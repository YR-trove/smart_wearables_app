import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smart_wearables_app/connection/message_type.dart';

class MyStream {
  StreamController<List<int>> controller        = StreamController<List<int>>.broadcast();
  StreamController<List<int>> controllerBattery = StreamController<List<int>>.broadcast();
  
  // Your brilliant existing write-back channel
  StreamController<List<int>> controllerSend    = StreamController<List<int>>.broadcast();

  void setNum(List<int> data) {
    if (data[0] == MsgType.battery.description) {
      controllerBattery.add(data);
    } else {
      controller.add(data);
    }
  }

  /// Sends a command to the MCU to switch data streaming modes.
  /// [isRawMode] true = 100Hz Raw IMU/Light, false = 1Hz Edge Metrics
  Future<void> setMcuMode(bool isRawMode) async {
    final payload = isRawMode ? 0x01 : 0x00;
    
    // Command frame: [Start, MsgType, Payload, End]
    final command = [0x7B, 0xC0, payload, 0x7D];
    
    // Push the command into the stream. 
    // connection_page.dart is already listening and will transmit it!
    controllerSend.add(command);
    
    debugPrint('MainShell: MCU Mode swapped to -> ${isRawMode ? "RAW" : "METRICS"}');
  }

  void sendData(List<int> data) {
    controllerSend.add(data);
  }
}