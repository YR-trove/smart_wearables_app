# Walkthrough: Unified BLE Packet Architecture

This document describes the structure and layout of the 20-byte unified Bluetooth packet being streamed from the MainBoard logger, along with example code for correctly extracting the telemetry values inside a Flutter application.

## Packet Transport Overview
- **Dispatch Rate**: Sent exactly once every 500ms (2Hz).
- **Size**: Fixed at 20 bytes total to comply with standard BLE MTU limitations.
- **Payload**: Contains both live data (such as the IMU Step Count tracking during the IMU phase) and securely cached environment data (Light and Audio measurements captured during the Environment Phase).

## Packet Structure (20 Bytes Total)

The packet is wrapped with explicit `Start` and `End` sentinels to allow the receiving app to quickly verify byte alignment. Multi-byte integers are transmitted in **Little Endian** format.

| Byte Index | Field Name | Data Type | Description |
| :--- | :--- | :--- | :--- |
| **0** | `Start Sentinel` | `uint8` | Always `0x7B` (`{`). Used to verify packet alignment. |
| **1** | `Message Type` | `uint8` | Always `0x55`. Identifies this as the Unified Metrics packet. |
| **2** | `Step Count (LSB)` | `uint16` (Little-Endian) | The lower byte of the cumulative step count. |
| **3** | `Step Count (MSB)` | `uint16` (Little-Endian) | The upper byte of the cumulative step count. |
| **4** | `Light Class` | `uint8` | `0`=Dark, `1`=Low Exp, `2`=Moderate Exp, `3`=High Exp, `4`=Very High Exp. |
| **5** | `Blue/Clear (LSB)` | `uint16` (Little-Endian) | The lower byte of the Blue to Clear light ratio. |
| **6** | `Blue/Clear (MSB)` | `uint16` (Little-Endian) | The upper byte of the Blue to Clear light ratio. |
| **7** | `Color Temp (LSB)` | `uint16` (Little-Endian) | The lower byte of the color temperature (Kelvin). |
| **8** | `Color Temp (MSB)` | `uint16` (Little-Endian) | The upper byte of the color temperature (Kelvin). |
| **9** | `LAeq x10 (LSB)` | `uint16` (Little-Endian) | The lower byte of the Audio LAeq multiplied by 10 (e.g. `654` = 65.4 dB). |
| **10** | `LAeq x10 (MSB)` | `uint16` (Little-Endian) | The upper byte of the Audio LAeq multiplied by 10. |
| **11** | `Audio Env Class` | `uint8` | `1`=Very Quiet, `2`=Quiet, `3`=Moderate, `4`=Lively, `5`=Noisy, `6`=Very Noisy, `7`=High Exp. |
| **12-18** | `Padding` | `uint8[7]` | 7 bytes of zero padding (`0x00`) to reach the fixed MTU size. |
| **19** | `End Sentinel` | `uint8` | Always `0x7D` (`}`). Used to verify the end of the packet. |

---

## Example Flutter / Dart Parsing Snippet

In Dart, you can parse this byte array cleanly using a `ByteData` view to automatically handle the Little Endian extraction:

```dart
import 'dart:typed_data';

void parseUnifiedPacket(List<int> data) {
  // 1. Verify packet length and sentinels
  if (data.length == 20 && data[0] == 0x7B && data[1] == 0x55 && data[19] == 0x7D) {
    
    // Create a ByteData view for easy Little Endian extraction
    final byteData = ByteData.sublistView(Uint8List.fromList(data));

    // 2. Extract values
    final int stepCount = byteData.getUint16(2, Endian.little);
    final int lightClass = data[4];
    final int blueClearRatio = byteData.getUint16(5, Endian.little);
    
    final int laeqX10 = byteData.getUint16(9, Endian.little);
    final double realLaeq = laeqX10 / 10.0; // Convert back to float dB
    final int audioClass = data[11];

    // Print or use the extracted data
    print('Steps: $stepCount');
    print('Light Class: $lightClass, B/C Ratio: $blueClearRatio');
    print('LAeq: $realLaeq dB, Audio Class: $audioClass');
  } else {
    print('Invalid packet format or sentinels!');
  }
}
```
