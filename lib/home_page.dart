import 'dart:async';
import 'package:flutter/material.dart';
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
  final int    x;
  final double y;
}

// ---------------------------------------------------------------------------
// HomePage — Developer Mode live charts
// Data flows exclusively from SensorBuffer streams.
// ---------------------------------------------------------------------------
class HomePage extends StatefulWidget {
  HomePage({
    super.key,
    required this.title,
    required this.buffer,
  });
  final String       title;
  final SensorBuffer buffer;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription<ImuSample>?   _imuSub;
  StreamSubscription<LightSample>? _lightSub;
  StreamSubscription<MicSample>?   _micSub;

  // ── IMU — separate series for accel (A) and gyro (G) ─────────────────────
  List<ChartData> xaData = [], yaData = [], zaData = [];
  List<ChartData> xgData = [], ygData = [], zgData = [];
  ChartSeriesController? _xaCtrl, _yaCtrl, _zaCtrl;
  ChartSeriesController? _xgCtrl, _ygCtrl, _zgCtrl;
  int _accelCounter = 0;
  int _gyroCounter  = 0;

  // ── Light ─────────────────────────────────────────────────────────────────
  List<ChartData> uvData = [], blIntData = [], blRatioData = [], sunData = [];
  ChartSeriesController? _uvCtrl, _blIntCtrl, _blRatioCtrl, _sunCtrl;
  int _lightCounter = 0;

  // ── Mic ───────────────────────────────────────────────────────────────────
  List<ChartData> noiseLvlData = [], noiseTimeData = [];
  ChartSeriesController? _noiseLvlCtrl, _noiseTimeCtrl;
  int _micCounter = 0;

  final int maxPts = 200;

  @override
  void initState() {
    super.initState();
    _imuSub   = widget.buffer.imuStream.listen(_onImu);
    _lightSub = widget.buffer.lightStream.listen(_onLight);
    _micSub   = widget.buffer.micStream.listen(_onMic);
  }

  // ── Stream handlers ───────────────────────────────────────────────────────

  void _onImu(ImuSample s) {
    if (s.type == 'A') {
      _append(xaData, _accelCounter, s.x);
      _append(yaData, _accelCounter, s.y);
      _append(zaData, _accelCounter, s.z);
      _accelCounter++;
      _updateCtrl(_xaCtrl, xaData);
      _updateCtrl(_yaCtrl, yaData);
      _updateCtrl(_zaCtrl, zaData);
    } else {
      _append(xgData, _gyroCounter, s.x);
      _append(ygData, _gyroCounter, s.y);
      _append(zgData, _gyroCounter, s.z);
      _gyroCounter++;
      _updateCtrl(_xgCtrl, xgData);
      _updateCtrl(_ygCtrl, ygData);
      _updateCtrl(_zgCtrl, zgData);
    }
  }

  void _onLight(LightSample s) {
    _append(uvData,      _lightCounter, s.uvRisk);
    _append(blIntData,   _lightCounter, s.blueLightIntensity);
    _append(blRatioData, _lightCounter, s.blueLightRatio);
    _append(sunData,     _lightCounter, s.sunLikeIndex);
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          _sectionHeader('Accelerometer (g)'),
          _buildChart('X',  xaData, Colors.red,    (c) => _xaCtrl = c, min: -3,   max: 3),
          _buildChart('Y',  yaData, Colors.green,  (c) => _yaCtrl = c, min: -3,   max: 3),
          _buildChart('Z',  zaData, Colors.blue,   (c) => _zaCtrl = c, min: -3,   max: 3),

          _sectionHeader('Gyroscope (°/s)'),
          _buildChart('X',  xgData, Colors.orange, (c) => _xgCtrl = c, min: -180, max: 180),
          _buildChart('Y',  ygData, Colors.purple, (c) => _ygCtrl = c, min: -180, max: 180),
          _buildChart('Z',  zgData, Colors.yellow, (c) => _zgCtrl = c, min: -180, max: 180),

          _sectionHeader('Light Sensor'),
          _buildChart('UV Risk (0–1)',           uvData,      Colors.orange,    (c) => _uvCtrl = c,      min: 0, max: 1),
          _buildChart('Blue-Light Intensity',   blIntData,   Colors.blue,      (c) => _blIntCtrl = c,   min: 0, max: 4096),
          _buildChart('Blue-Light Ratio (0–1)', blRatioData, Colors.lightBlue, (c) => _blRatioCtrl = c, min: 0, max: 1),
          _buildChart('Sun-Like Index (0–1)',   sunData,     Colors.amber,     (c) => _sunCtrl = c,     min: 0, max: 1),

          _sectionHeader('Microphone'),
          _buildChart('Noise Level (dB)', noiseLvlData,  Colors.red,    (c) => _noiseLvlCtrl = c,  min: 30,  max: 120),
          _buildChart('Noise Time (s)',   noiseTimeData, Colors.purple, (c) => _noiseTimeCtrl = c, min: 0,   max: 28800),
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
            child: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600)),
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
