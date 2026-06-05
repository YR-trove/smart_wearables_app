import 'dart:async';
import 'models/imu_sample.dart';
import 'models/light_sample.dart';
import 'models/mic_sample.dart';

/// In-memory ring buffer used exclusively during Developer Mode.
/// No data is ever written to disk from this class.
/// The buffer feeds real-time charts via broadcast streams.
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
