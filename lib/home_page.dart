import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wearables_app/connection/stream.dart';
import 'package:smart_wearables_app/data/sensor_buffer.dart';
import 'package:smart_wearables_app/data/models/imu_sample.dart';
import 'package:smart_wearables_app/data/models/light_sample.dart';
import 'package:smart_wearables_app/data/models/mic_sample.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// ---------------------------------------------------------------------------
// Chart data point
// ---------------------------------------------------------------------------
class ChartData {
  ChartData(this.x, this.y);
  final int x;
  final double y;
}

// ---------------------------------------------------------------------------
// HomePage — Developer Mode live charts
// Data flows from SensorBuffer streams, never from the DB.
// ---------------------------------------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.title,
    required this.stream,
    required this.buffer,
  });
  final String title;
  final MyStream stream;
  final SensorBuffer buffer;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // IMU subscriptions
  StreamSubscription<ImuSample>?   _imuSub;
  StreamSubscription<LightSample>? _lightSub;
  StreamSubscription<MicSample>?   _micSub;

  // ── IMU (accel + gyro retained from original implementation) ──────────────
  List<ChartData> xaData = [], yaData = [], zaData = [];
  List<ChartData> xgData = [], ygData = [], zgData = [];
  ChartSeriesController? _xaCtrl, _yaCtrl, _zaCtrl;
  ChartSeriesController? _xgCtrl, _ygCtrl, _zgCtrl;
  int _imuCounter = 0;

  // ── Light ─────────────────────────────────────────────────────────────────
  List<ChartData> uvData = [], blIntData = [], blRatioData = [], sunData = [];
  ChartSeriesController? _uvCtrl, _blIntCtrl, _blRatioCtrl, _sunCtrl;
  int _lightCounter = 0;

  // ── Mic ───────────────────────────────────────────────────────────────────
  List<ChartData> noiseLvlData = [], noiseTimeData = [];
  ChartSeriesController? _noiseLvlCtrl, _noiseTimeCtrl;
  int _micCounter = 0;

  final int maxPts = 200;

  // IMU sensitivity constants (unchanged)
  static const double aSensitivity = 2.0 / 32767.0;
  static const double gSensitivity = 1.0 / 175.0;

  @override
  void initState() {
    super.initState();
    _imuSub   = widget.buffer.imuStream.listen(_onImu);
    _lightSub = widget.buffer.lightStream.listen(_onLight);
    _micSub   = widget.buffer.micStream.listen(_onMic);
  }

  // ── Stream handlers ────────────────────────────────────────────────────────
  void _onImu(ImuSample s) {
    _append(xaData, _imuCounter, s.stepCount.toDouble());
    _append(yaData, _imuCounter, s.metric3);
    _append(zaData, _imuCounter, 0);          // placeholder until firmware defines
    _imuCounter++;
    _updateCtrl(_xaCtrl, xaData);
    _updateCtrl(_yaCtrl, yaData);
    _updateCtrl(_zaCtrl, zaData);

    // Gyro channels stay wired to the raw BLE stream for backward compat.
  }

  void _onLight(LightSample s) {
    _append(uvData,       _lightCounter, s.uvRisk);
    _append(blIntData,    _lightCounter, s.blueLightIntensity);
    _append(blRatioData,  _lightCounter, s.blueLightRatio);
    _append(sunData,      _lightCounter, s.sunLikeIndex);
    _lightCounter++;
    _updateCtrl(_uvCtrl,      uvData);
    _updateCtrl(_blIntCtrl,   blIntData);
    _updateCtrl(_blRatioCtrl, blRatioData);
    _updateCtrl(_sunCtrl,     sunData);
  }

  void _onMic(MicSample s) {
    _append(noiseLvlData,  _micCounter, s.noiseLevel);
    _append(noiseTimeData, _micCounter, s.noiseTime);
    _micCounter++;
    _updateCtrl(_noiseLvlCtrl,  noiseLvlData);
    _updateCtrl(_noiseTimeCtrl, noiseTimeData);
  }

  void _append(List<ChartData> list, int x, double y) {
    list.add(ChartData(x, y));
    if (list.length > maxPts) list.removeAt(0);
  }

  void _updateCtrl(ChartSeriesController? ctrl, List<ChartData> data) {
    ctrl?.updateDataSource(
      addedDataIndexes: [data.length - 1],
      removedDataIndexes: data.length == maxPts ? [0] : null,
    );
  }

  @override
  void dispose() {
    _imuSub?.cancel();
    _lightSub?.cancel();
    _micSub?.cancel();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          _sectionHeader('IMU'),
          _buildChart('Steps',    xaData, Colors.red,    (c) => _xaCtrl = c, min: 0,    max: 50000),
          _buildChart('Metric 3', yaData, Colors.green,  (c) => _yaCtrl = c, min: -100, max: 100),

          _sectionHeader('Light Sensor'),
          _buildChart('UV Risk (0–1)',          uvData,      Colors.orange,      (c) => _uvCtrl = c,      min: 0, max: 1),
          _buildChart('Blue-Light Intensity',  blIntData,   Colors.blue,        (c) => _blIntCtrl = c,   min: 0, max: 4096),
          _buildChart('Blue-Light Ratio (0–1)',blRatioData, Colors.lightBlue,   (c) => _blRatioCtrl = c, min: 0, max: 1),
          _buildChart('Sun-Like Index (0–1)',  sunData,     Colors.amber,       (c) => _sunCtrl = c,     min: 0, max: 1),

          _sectionHeader('Microphone'),
          _buildChart('Noise Level (dB)',   noiseLvlData,  Colors.red,    (c) => _noiseLvlCtrl = c,  min: 30, max: 120),
          _buildChart('Noise Time (s)',     noiseTimeData, Colors.purple, (c) => _noiseTimeCtrl = c, min: 0,  max: 28800),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  );

  Widget _buildChart(
    String title,
    List<ChartData> data,
    Color color,
    void Function(ChartSeriesController) onCreated, {
    required double min,
    required double max,
  }) {
    return Container(
      height: 220,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: NumericAxis(
                autoScrollingMode: AutoScrollingMode.end,
                autoScrollingDelta: maxPts,
                isVisible: false,
              ),
              primaryYAxis: NumericAxis(minimum: min, maximum: max),
              series: <LineSeries<ChartData, int>>[
                LineSeries<ChartData, int>(
                  onRendererCreated: onCreated,
                  dataSource: data,
                  xValueMapper: (d, _) => d.x,
                  yValueMapper: (d, _) => d.y,
                  color: color,
                  animationDuration: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
