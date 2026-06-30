import 'dart:async';
import 'package:flutter/foundation.dart';
class MyStream {
  // 1. The 1Hz Normal Mode Stream (UI, Step Count, General Metrics)
  StreamController<List<int>> controller          = StreamController<List<int>>.broadcast();
  
  // 2. The 20Hz Dev Mode Stream (High-speed Accel, Gyro, Light, Mic plots)
  StreamController<List<int>> controllerDevMode   = StreamController<List<int>>.broadcast();
  
  // 3. Telemetry Streams
  StreamController<List<int>> controllerBattery   = StreamController<List<int>>.broadcast();
  
  // 4. Outgoing MCU Commands
  StreamController<List<int>> controllerSend      = StreamController<List<int>>.broadcast();

  void setNum(List<int> data) {
    if (data.isEmpty) return;

    // Route the packet based on its Header Byte (data[0])
    if (data[0] == 123) { // 123 in decimal: Unified 1Hz Payload
      controller.add(data);
    } 
    else if (data[0] == 119) { // 119 in decimal: Omnibus 20Hz Dev Payload
      controllerDevMode.add(data);
    }
    else {
      debugPrint('Warning: Unknown packet header received: ${data[0]}');
    }
  }

  /// Sends a command to the MCU to switch data streaming modes.
  /// [isRawMode] true = 100Hz Raw IMU/Light, false = 1Hz Metrics
  Future<void> setMcuMode(bool isRawMode) async {
    final payload = isRawMode ? 0x01 : 0x00;
    
    // Command frame: [Start, MsgType, Payload, End]
    final command = [0x7B, 0xC0, payload, 0x7D];
    
    // Push the command into the stream.
    controllerSend.add(command);
    
    debugPrint('MainShell: MCU Mode swapped to -> ${isRawMode ? "RAW" : "METRICS"}');
  }

  void sendData(List<int> data) {
    controllerSend.add(data);
  }
}