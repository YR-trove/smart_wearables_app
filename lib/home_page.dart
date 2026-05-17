import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:smart_wearables_app/connection/stream.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:smart_wearables_app/utils/sensor_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title, required this.stream});
  final String title;
  final MyStream stream;

  @override
  State<HomePage> createState() => _HomePageState();
}

class ChartData {
  ChartData(this.x, this.y);
  final int x;
  final double y;
}

class _HomePageState extends State<HomePage> {
  late StreamSubscription _dataSubscription;

  List<ChartData> xaData = [];
  List<ChartData> yaData = [];
  List<ChartData> zaData = [];

  List<ChartData> xgData = [];
  List<ChartData> ygData = [];
  List<ChartData> zgData = [];

  ChartSeriesController? _xaSeriesController;
  ChartSeriesController? _yaSeriesController;
  ChartSeriesController? _zaSeriesController;

  ChartSeriesController? _xgSeriesController;
  ChartSeriesController? _ygSeriesController;
  ChartSeriesController? _zgSeriesController;

  int xaCounter = 0;
  int xgCounter = 0;
  String dataType = 'N/A';
  final int maxDataPoints = 50;
  final double aSensitivity = 2.0 / 32767.0;
  final double gSensitivity = 1.0 / 175.0;

  @override
  void initState() {
    super.initState();
    _dataSubscription = widget.stream.controller.stream.listen((data) {
      _parsePacket(data);
    });
  }

  void _parsePacket(List<int> packet) {
    String type = String.fromCharCode(packet[1]);

    var byteData = Uint8List.fromList(packet.sublist(2)).buffer.asByteData();

    if (dataType != type) {
      setState(() {
        dataType = type;
      });
    }

    int rawX = byteData.getInt16(0, Endian.little);
    int rawY = byteData.getInt16(2, Endian.little);
    int rawZ = byteData.getInt16(4, Endian.little);

    if (dataType == 'A')
    {
    double aX = rawX * aSensitivity;
    double aY = rawY * aSensitivity;
    double aZ = rawZ * aSensitivity;

    xaData.add(ChartData(xaCounter, aX));
    yaData.add(ChartData(xaCounter, aY));
    zaData.add(ChartData(xaCounter, aZ));
    
    xaCounter++;

    bool isListFull = xaData.length > maxDataPoints;
    if (isListFull) {
      xaData.removeAt(0);
      yaData.removeAt(0);
      zaData.removeAt(0);
      }

    _xaSeriesController?.updateDataSource(
      addedDataIndexes: <int>[xaData.length - 1], 
      removedDataIndexes: isListFull ? <int>[0] : null, 
    );
    _yaSeriesController?.updateDataSource(
      addedDataIndexes: <int>[yaData.length - 1],
      removedDataIndexes: isListFull ? <int>[0] : null,
    );
    _zaSeriesController?.updateDataSource(
      addedDataIndexes: <int>[zaData.length - 1],
      removedDataIndexes: isListFull ? <int>[0] : null,
    );
        //debugPrint(
        //"Parsed: Type=$dataType, X=${gX.toStringAsFixed(2)}g, Y=${gY.toStringAsFixed(2)}g, Z=${gZ.toStringAsFixed(2)}g");

   }
    else if (dataType == 'G')
    {
    double gX = rawX * gSensitivity;
    double gY = rawY * gSensitivity;
    double gZ = rawZ * gSensitivity;

    xgData.add(ChartData(xgCounter, gX));
    ygData.add(ChartData(xgCounter, gY));
    zgData.add(ChartData(xgCounter, gZ));
    
    xgCounter++; 

    bool isListFull = xgData.length > maxDataPoints;
    if (isListFull) {
      xgData.removeAt(0);
      ygData.removeAt(0);
      zgData.removeAt(0);
      }

    _xgSeriesController?.updateDataSource(
      addedDataIndexes: <int>[xgData.length - 1], 
      removedDataIndexes: isListFull ? <int>[0] : null, 
    );
    _ygSeriesController?.updateDataSource(
      addedDataIndexes: <int>[ygData.length - 1],
      removedDataIndexes: isListFull ? <int>[0] : null,
    );
    _zgSeriesController?.updateDataSource(
      addedDataIndexes: <int>[zgData.length - 1],
      removedDataIndexes: isListFull ? <int>[0] : null,
    );
    //debugPrint(
    //    "Parsed: Type=$dataType, X=${gX.toStringAsFixed(2)}g, Y=${gY.toStringAsFixed(2)}g, Z=${gZ.toStringAsFixed(2)}g");
    }
  }

  @override
  void dispose() {
    _dataSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: <Widget>[
          SizedBox(height: 10),
          Center(
            child: Text(
              'Accelerometer and Gyroscope',
              //'Sensor Type: ${getSensorNameFromType(dataType)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 20),
          
          _buildAccChart(
            "Acc-X-Axis",
            xaData,
            Colors.red,
            (controller) => _xaSeriesController = controller, 
          ),
          _buildAccChart(
            "Acc-Y-Axis",
            yaData,
            Colors.green,
            (controller) => _yaSeriesController = controller, 
          ),
          _buildAccChart(
            "Acc-Z-Axis",
            zaData,
            Colors.blue,
            (controller) => _zaSeriesController = controller, 
          ),
          _buildGyrChart(
            "Gyr-X-Axis",
            xgData,
            Colors.orange,
            (controller) => _xgSeriesController = controller, 
          ),
          _buildGyrChart(
            "Gyr-Y-Axis",
            ygData,
            Colors.purple,
            (controller) => _ygSeriesController = controller, 
          ),
          _buildGyrChart(
            "Gyr-Z-Axis",
            zgData,
            Colors.yellow,
            (controller) => _zgSeriesController = controller, 
          ),
        ],
      ),
    );
  }


  Widget _buildAccChart(String title, List<ChartData> data, Color color,
      void Function(ChartSeriesController) onControllerCreated) { 
    return Container(
      height: 250,
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: NumericAxis(

                autoScrollingMode: AutoScrollingMode.end,
                autoScrollingDelta: maxDataPoints,

                isVisible: false,
              ),
              primaryYAxis: NumericAxis(
                minimum: -3,
                maximum: 3,
                labelFormat: '{value} g',
              ),
              series: <LineSeries<ChartData, int>>[
                LineSeries<ChartData, int>(

                  onRendererCreated: onControllerCreated,

                  dataSource: data,
                  xValueMapper: (ChartData d, _) => d.x,
                  yValueMapper: (ChartData d, _) => d.y,
                  color: color,
                  animationDuration: 0,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGyrChart(String title, List<ChartData> data, Color color,
      void Function(ChartSeriesController) onControllerCreated) { 
    return Container(
      height: 400,
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: NumericAxis(

                autoScrollingMode: AutoScrollingMode.end,
                autoScrollingDelta: maxDataPoints,

                isVisible: false,
              ),
              primaryYAxis: NumericAxis(
                minimum: -180,
                maximum: 180,
                labelFormat: '{value} °/s',
              ),
              series: <LineSeries<ChartData, int>>[
                LineSeries<ChartData, int>(

                  onRendererCreated: onControllerCreated,

                  dataSource: data,
                  xValueMapper: (ChartData d, _) => d.x,
                  yValueMapper: (ChartData d, _) => d.y,
                  color: color,
                  animationDuration: 0,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}