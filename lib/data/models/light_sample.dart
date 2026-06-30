/// One light-sensor packet decoded from the BLE frame.
/// 
/// Note: In the v2 Edge Computing architecture, this model is used STRICTLY 
/// for transient Developer Mode plotting via SensorBuffer. 
/// It is NEVER persisted to SQLite.
class LightSample {
  final int      sessionId;
  final DateTime timestamp;
  final double   uvRisk;              // normalised UV risk index (0.0–1.0)
  final double   blueLightIntensity;  // raw intensity (lux or ADC units)
  final double   blueLightRatio;      // fraction of blue in total spectrum (0–1)
  final double   colorTemp;           // color temperature (K)
  final double   metric1;             // reserved

  const LightSample({
    required this.sessionId,
    required this.timestamp,
    required this.uvRisk,
    required this.blueLightIntensity,
    required this.blueLightRatio,
    required this.colorTemp,
    required this.metric1,
  });
  
  // toMap() has been deleted to prevent accidental insertions into dead tables.
}