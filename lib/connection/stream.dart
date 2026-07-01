import 'dart:async';
import 'package:flutter/foundation.dart';

class MyStream {
  // 1. Live-mode packet stream (1 Hz IMU + 3 Hz env, variable-length)
  StreamController<List<int>> controller        = StreamController<List<int>>.broadcast();

  // 2. Outgoing commands / ACKs to the MCU
  StreamController<List<int>> controllerSend    = StreamController<List<int>>.broadcast();

  /// TODO-REMOVE: controllerDevMode was the 20 Hz raw dev-mode stream.
  /// No equivalent packet type exists in the ble_live workflow.
  /// Remove this field (and all listeners) once the dev-dashboard is updated.
  StreamController<List<int>> controllerDevMode = StreamController<List<int>>.broadcast(); // TODO-REMOVE

  /// TODO-REMOVE: controllerBattery was planned but never connected to a
  /// real MCU packet.  Remove once confirmed unused.
  StreamController<List<int>> controllerBattery = StreamController<List<int>>.broadcast(); // TODO-REMOVE

  /// Route a received raw packet to the correct stream.
  /// The live-mode protocol uses fixed-size packets with a leading msg_type
  /// byte — no framing wrappers required.
  void setNum(List<int> data) {
    if (data.isEmpty) return;
    // All live-mode packet types are routed through controller.
    // MainShell dispatches by reading data[0] (msg_type).
    controller.add(data);
  }

  /// Send a raw byte buffer to the MCU over BLE TX.
  void sendData(List<int> data) {
    controllerSend.add(data);
  }

  /// Send a single ACK byte (0x06) to the MCU.
  void sendAck() {
    controllerSend.add(const [0x06]);
  }

  /// TODO-REMOVE: setMcuMode switched between 1 Hz metrics and 20 Hz raw mode.
  /// The ble_live workflow has no equivalent mode-switch command.
  /// Remove once settings page toggle is removed.
  Future<void> setMcuMode(bool isRawMode) async { // TODO-REMOVE
    debugPrint('MyStream.setMcuMode: no-op in ble_live workflow'); // TODO-REMOVE
  } // TODO-REMOVE
}
