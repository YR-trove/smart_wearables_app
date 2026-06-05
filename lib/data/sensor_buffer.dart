import 'dart:async';
import 'models/imu_sample.dart';
import 'models/light_sample.dart';
import 'models/mic_sample.dart';

/// In-memory ring buffer used exclusively for live chart display.
/// No data is ever written to disk from this class.
const int kBufferSize = 200;

class SensorBuffer {
  final _imu   = _Ring<ImuSample>(kBufferSize);
  final _light = _Ring<LightSample>(kBufferSize);
  final _mic   = _Ring<MicSample>(kBufferSize);

  final _imuCtrl   = StreamController<ImuSample>.broadcast();
  final _lightCtrl = StreamController<LightSample>.broadcast();
  final _micCtrl   = StreamController<MicSample>.broadcast();

  Stream<ImuSample>   get imuStream   => _imuCtrl.stream;
  Stream<LightSample> get lightStream => _lightCtrl.stream;
  Stream<MicSample>   get micStream   => _micCtrl.stream;

  List<ImuSample>   get imuSnapshot   => _imu.toList();
  List<LightSample> get lightSnapshot => _light.toList();
  List<MicSample>   get micSnapshot   => _mic.toList();

  // Named consistently with main_shell.dart callers:
  void addAccel(DateTime ts, double x, double y, double z) {
    final s = ImuSample(
      sessionId: 0, timestamp: ts, type: 'A', x: x, y: y, z: z);
    _imu.add(s); _imuCtrl.add(s);
  }

  void addGyro(DateTime ts, double x, double y, double z) {
    final s = ImuSample(
      sessionId: 0, timestamp: ts, type: 'G', x: x, y: y, z: z);
    _imu.add(s); _imuCtrl.add(s);
  }

  void addLight(
      DateTime ts, double uvRisk, double blueLightIntensity,
      double blueLightRatio, double sunLikeIndex) {
    final s = LightSample(
      sessionId: 0, timestamp: ts,
      uvRisk: uvRisk,
      blueLightIntensity: blueLightIntensity,
      blueLightRatio: blueLightRatio,
      sunLikeIndex: sunLikeIndex,
      metric1: 0,
    );
    _light.add(s); _lightCtrl.add(s);
  }

  void addMic(DateTime ts, double noiseLevel, double noiseTime) {
    final s = MicSample(
      sessionId: 0, timestamp: ts,
      noiseLevel: noiseLevel, noiseTime: noiseTime, metric2: 0);
    _mic.add(s); _micCtrl.add(s);
  }

  // Legacy ingest aliases (used by HomePage directly if needed)
  void ingestImu(ImuSample s)     { _imu.add(s);   _imuCtrl.add(s); }
  void ingestLight(LightSample s) { _light.add(s); _lightCtrl.add(s); }
  void ingestMic(MicSample s)     { _mic.add(s);   _micCtrl.add(s); }

  void dispose() {
    _imuCtrl.close();
    _lightCtrl.close();
    _micCtrl.close();
  }
}

class _Ring<T> {
  final int capacity;
  final _list = <T>[];
  _Ring(this.capacity);

  void add(T item) {
    if (_list.length >= capacity) _list.removeAt(0);
    _list.add(item);
  }

  List<T> toList() => List.unmodifiable(_list);
}
