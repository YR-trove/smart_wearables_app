import 'dart:async';

import 'package:smart_wearables_app/connection/message_type.dart';

class MyStream {
  StreamController<List<int>> controller        = StreamController<List<int>>.broadcast();
  StreamController<List<int>> controllerBattery = StreamController<List<int>>.broadcast();
  StreamController<List<int>> controllerSend    = StreamController<List<int>>.broadcast();

  void setNum(List<int> data) {
    if (data[0] == MsgType.battery.description) {
      controllerBattery.add(data);
    } else {
      controller.add(data);
    }
  }

  void sendData(List<int> data) {
    controllerSend.add(data);
  }
}
