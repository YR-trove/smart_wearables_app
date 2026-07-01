import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/connection/stream.dart';
import 'package:smart_wearables_app/data/session_store.dart';
import 'package:smart_wearables_app/main_shell.dart';
import 'package:permission_handler/permission_handler.dart';

// ── BLE Service / Characteristic UUIDs (RN4871 ISSP Transparent UART) ────────
Uuid serviceUuid          = Uuid.parse("49535343-FE7D-4AE5-8FA9-9FAFD205E455");
Uuid characteristicUuid   = Uuid.parse("49535343-1E4D-4BD9-BA61-23C647249616"); // RX (MCU → App)
Uuid characteristicUuidTX = Uuid.parse("49535343-8841-43F4-A8D4-ECBE34729BB3"); // TX (App → MCU)

// ── Live-mode packet minimum lengths (must match ble_live_payload.h) ─────────
const int _kImuPacketLen       = 7; // 0x50
const int _kLightPacketLen     = 3; // 0x51
const int _kMicPacketLen       = 4; // 0x52
const int _kConnectionEventLen = 2; // 0x53

/// Returns the expected byte length for [msgType], or null if unknown.
int? _packetLen(int msgType) => switch (msgType) {
  0x50 => _kImuPacketLen,
  0x51 => _kLightPacketLen,
  0x52 => _kMicPacketLen,
  0x53 => _kConnectionEventLen,
  _    => null,
};

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key, required this.title});
  final String title;

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final String bleDeviceNameFilter = "BLE_SW";
  final flutterReactiveBle = FlutterReactiveBle();

  late StreamSubscription<DiscoveredDevice>      scanStream;
  late Stream<ConnectionStateUpdate>             currentConnectionStream;
  late StreamSubscription<ConnectionStateUpdate> connection;

  StreamSubscription<List<int>>? _rxSubscription;
  StreamSubscription<List<int>>? _txSubscription;

  late QualifiedCharacteristic _rxCharacteristic;
  late QualifiedCharacteristic _txCharacteristic;

  List<DiscoveredDevice> foundBleDevices         = [];
  List<DiscoveredDevice> foundBleDevicesFiltered = [];

  bool permGranted = false;
  bool scanning    = false;
  bool connecting  = false;
  bool connected   = false;

  MyStream incomingBLEStream = MyStream();

  void refreshScreen() => setState(() {});

  // ── Permissions ──────────────────────────────────────────────────────────────

  Future<void> _showNoPermissionDialog() async => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Permissions Missing'),
      content: const SingleChildScrollView(
        child: ListBody(children: [
          Text('Location and Bluetooth permissions are required for BLE.'),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Acknowledge'),
        ),
      ],
    ),
  );

  void _askPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
      Permission.bluetoothConnect,
    ].request();

    final granted =
        statuses[Permission.bluetoothScan]    == PermissionStatus.granted &&
        statuses[Permission.bluetoothConnect] == PermissionStatus.granted &&
        statuses[Permission.locationWhenInUse]== PermissionStatus.granted;

    permGranted = granted;
    if (granted && !scanning) _startScan();
  }

  // ── Scan ─────────────────────────────────────────────────────────────────────

  void _stopScan() async {
    await scanStream.cancel();
    scanning = false;
    refreshScreen();
  }

  void _startScan() async {
    if (scanning) _stopScan();
    if (!permGranted) { await _showNoPermissionDialog(); return; }

    foundBleDevices         = [];
    foundBleDevicesFiltered = [];
    scanning = true;
    refreshScreen();

    scanStream = flutterReactiveBle
        .scanForDevices(withServices: [])
        .listen((device) {
      if (foundBleDevices.every((e) => e.id != device.id)) {
        foundBleDevices.add(device);
        if (device.name.contains(bleDeviceNameFilter)) {
          foundBleDevicesFiltered.add(device);
        }
        refreshScreen();
      }
    }, onError: (Object error) {
      debugPrint('Scan error: $error');
      refreshScreen();
    });

    Future.delayed(const Duration(seconds: 10), () {
      if (scanning) _stopScan();
    });
  }

  // ── Connection ───────────────────────────────────────────────────────────────

  void _startConnection(int index) async {
    if (scanning) { scanStream.cancel(); scanning = false; }
    if (connected) return;

    setState(() => connecting = true);

    currentConnectionStream = flutterReactiveBle.connectToDevice(
      id: foundBleDevicesFiltered[index].id,
      connectionTimeout: const Duration(seconds: 5),
    );

    connection = currentConnectionStream.listen((event) {
      final id = event.deviceId.toString();
      switch (event.connectionState) {
        case DeviceConnectionState.connecting:
          connectingProcedure(id);
        case DeviceConnectionState.connected:
          connectionProcedure(id, event);
        case DeviceConnectionState.disconnected:
          disconnectionProcedure(id);
        default:
          break;
      }
      refreshScreen();
    }, onError: (Object error) {
      if (!mounted) return;
      connecting = false;
      connected  = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection failed!')));
      debugPrint('Connection error: $error');
      _startScan();
      refreshScreen();
    });
  }

  void connectingProcedure(String id) {
    connected  = false;
    connecting = true;
    debugPrint('Connecting to $id...');
  }

  void connectionProcedure(String id, ConnectionStateUpdate event) async {
    connected  = true;
    connecting = false;
    debugPrint('Connected to $id');

    // 1. Negotiate MTU
    try {
      await flutterReactiveBle.requestMtu(deviceId: id, mtu: 512);
    } catch (e) {
      debugPrint('MTU request failed or ignored: $e');
    }

    // 2. Discover services
    try {
      await flutterReactiveBle.discoverAllServices(id);
    } catch (e) {
      debugPrint('Service discovery error: $e');
    }

    // ── RX characteristic (MCU → App) ────────────────────────────────────────
    _rxCharacteristic = QualifiedCharacteristic(
      serviceId:        serviceUuid,
      characteristicId: characteristicUuid,
      deviceId:         event.deviceId,
    );

    // ── TX characteristic (App → MCU) ────────────────────────────────────────
    _txCharacteristic = QualifiedCharacteristic(
      serviceId:        serviceUuid,
      characteristicId: characteristicUuidTX,
      deviceId:         event.deviceId,
    );

    // ── Wire outgoing ACK / command stream to BLE TX ─────────────────────────
    await _txSubscription?.cancel();
    _txSubscription = incomingBLEStream.controllerSend.stream.listen((data) async {
      try {
        await flutterReactiveBle.writeCharacteristicWithoutResponse(
            _txCharacteristic, value: data);
        debugPrint('TX → MCU: 0x${data.map((b) => b.toRadixString(16).padLeft(2, "0")).join(" 0x")}');
      } catch (e) {
        debugPrint('TX Error: $e');
      }
    });

    // ── Subscribe to RX notifications ────────────────────────────────────────
    await Future.delayed(const Duration(milliseconds: 500));
    await _rxSubscription?.cancel();

    final List<int> packetBuffer = [];

    _rxSubscription = flutterReactiveBle
        .subscribeToCharacteristic(_rxCharacteristic)
        .listen(
      (chunk) {
        packetBuffer.addAll(chunk);

        // ── Live-mode framer ──────────────────────────────────────────────────
        // Packets are bare fixed-size structs with a leading msg_type byte.
        // No '{' / '}' wrappers — those belonged to the old unified frame.
        while (packetBuffer.isNotEmpty) {
          final msgType  = packetBuffer[0];
          final expected = _packetLen(msgType);

          if (expected == null) {
            // Unknown header byte — drop 1 byte and re-align.
            debugPrint('RX: unknown msg_type 0x${msgType.toRadixString(16)} — skipping byte');
            packetBuffer.removeAt(0);
            continue;
          }

          if (packetBuffer.length < expected) break; // wait for rest of packet

          // Extract the complete packet.
          final packet = List<int>.unmodifiable(packetBuffer.sublist(0, expected));
          packetBuffer.removeRange(0, expected);

          // Forward to MainShell router.
          incomingBLEStream.controller.add(packet);

          // Per-packet ACK: [0xAA, msgType] — sync scheme.
          incomingBLEStream.sendPacketAck(msgType);
          debugPrint(
            'RX ← MCU [0x${msgType.toRadixString(16).toUpperCase()}] '
            '${packet.length} B → ACK [0xAA, 0x${msgType.toRadixString(16).toUpperCase()}]',
          );
        }
      },
      onError: (dynamic error) => debugPrint('RX error: $error'),
    );

    // ── Connection-established ACK: [0xAA, 0x01] ─────────────────────────────
    // Sent after RX subscription is up so the MCU can start streaming
    // immediately upon receiving the ACK.
    await Future.delayed(const Duration(milliseconds: 100));
    incomingBLEStream.sendConnectAck();
    debugPrint('Connection ACK [0xAA, 0x01] sent to MCU');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connected!')));

    _navigateToShell(event.deviceId);
  }

  Future<void> _navigateToShell(String deviceId) async {
    final store = context.read<SessionStore>();
    final users = await store.getAllUsers();

    if (!mounted) return;

    if (users.isEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserOnboardingPage(store: store),
        ),
      );
    } else {
      if (store.currentUser == null) {
        await store.switchUser(users.first.id!);
      }
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MainShell(
          stream:   incomingBLEStream,
          deviceId: deviceId,
        ),
      ),
    ).whenComplete(forceDisconnection);
  }

  void disconnectionProcedure(String id) {
    if (connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disconnected!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not connected!')));
    }
    connected  = false;
    connecting = false;
    debugPrint('Disconnected from $id');
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void forceDisconnection() async {
    if (connected) {
      connection.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disconnected!')));
      _startScan();
      setState(() { connected = false; connecting = false; });
    }
  }

  @override
  void initState() {
    super.initState();
    _askPermissions();
  }

  // ── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(widget.title),
            actions: [
              if (scanning)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Scan again',
                  onPressed: _startScan,
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => _startScan(),
            child: foundBleDevicesFiltered.isEmpty
                ? _emptyState()
                : ListView.builder(
                    itemCount: foundBleDevicesFiltered.length,
                    itemBuilder: (context, index) => Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(foundBleDevicesFiltered[index].name),
                        subtitle: Text(foundBleDevicesFiltered[index].id),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          if (!connecting) _startConnection(index);
                        },
                      ),
                    ),
                  ),
          ),
        ),
        if (connecting) ...
          const [
            Opacity(
              opacity: 0.5,
              child: ModalBarrier(dismissible: false, color: Colors.black)),
            Center(child: CircularProgressIndicator()),
          ],
      ],
    );
  }

  Widget _emptyState() => ListView(
    children: const [
      SizedBox(height: 120),
      Center(
        child: Column(
          children: [
            Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Scanning for BLE_SW devices…',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text('Pull down to scan again',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    ],
  );
}

// ── User Onboarding ───────────────────────────────────────────────────────────

class UserOnboardingPage extends StatefulWidget {
  final SessionStore store;
  const UserOnboardingPage({super.key, required this.store});

  @override
  State<UserOnboardingPage> createState() => _UserOnboardingPageState();
}

class _UserOnboardingPageState extends State<UserOnboardingPage> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _ageCtrl    = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.store.createUser(
      name:     _nameCtrl.text.trim(),
      age:      int.tryParse(_ageCtrl.text),
      weightKg: double.tryParse(_weightCtrl.text),
      heightCm: double.tryParse(_heightCtrl.text),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _ageCtrl.dispose();
    _weightCtrl.dispose(); _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Welcome!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Create your profile to start tracking your health data.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Age (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake_outlined),
                  suffixText: 'years',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final n = int.tryParse(v);
                  if (n == null || n < 1 || n > 130) return 'Enter a valid age';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightCtrl,
                decoration: const InputDecoration(
                  labelText: 'Weight (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                  suffixText: 'kg',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final n = double.tryParse(v);
                  if (n == null || n < 1 || n > 500) return 'Enter a valid weight';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heightCtrl,
                decoration: const InputDecoration(
                  labelText: 'Height (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.height),
                  suffixText: 'cm',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final n = double.tryParse(v);
                  if (n == null || n < 50 || n > 300) return 'Enter a valid height';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Get Started',
                        style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
