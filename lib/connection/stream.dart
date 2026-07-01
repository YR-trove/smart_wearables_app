import 'dart:async';


// ── ACK frame constants ───────────────────────────────────────────────────────
/// Sent once immediately after BLE connection is established.
/// Tells the mainboard the app is ready to receive live packets.
const List<int> kAckConnect = [0xAA, 0x01];

/// Builds a per-packet ACK: [0xAA, msgType].
/// Sent after every successfully framed live-mode packet.
List<int> ackForPacket(int msgType) => [0xAA, msgType];

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

  /// Send the connection-established ACK [0xAA, 0x01] to the mainboard.
  /// Call once immediately after BLE connection is confirmed.
  void sendConnectAck() {
    controllerSend.add(kAckConnect);
  }

  /// Send a per-packet ACK [0xAA, msgType] after each successfully parsed packet.
  void sendPacketAck(int msgType) {
    controllerSend.add(ackForPacket(msgType));
  }

}
