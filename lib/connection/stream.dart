import 'dart:async';




class MyStream {
  // 1. Live-mode packet stream (1 Hz IMU + 3 s env, variable-length)
  StreamController<List<int>> controller     = StreamController<List<int>>.broadcast();

  // 2. Outgoing commands / ACKs to the MCU (wired to BLE TX in connection_page)
  StreamController<List<int>> controllerSend = StreamController<List<int>>.broadcast();


  /// Route a received raw packet to the correct stream.
  /// The live-mode protocol uses fixed-size packets with a leading msg_type
  /// byte — no framing wrappers required.
  void setNum(List<int> data) {
    if (data.isEmpty) return;
    controller.add(data);
  }

  /// Send a raw byte buffer to the MCU over BLE TX.
  void sendData(List<int> data) {
    controllerSend.add(data);
  }



}
