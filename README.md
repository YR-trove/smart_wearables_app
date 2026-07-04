# Smart Wearables App

A comprehensive Flutter application designed to interface with smart glasses and wearables via Bluetooth Low Energy (BLE). The app receives real-time telemetry, processes the data into actionable insights, and securely stores historical sessions using an on-device SQLite database.

## Key Features

- **Unified BLE Telemetry:** Reads a robust 20-byte unified telemetry packet streamed at 2Hz containing IMU, Light, and Audio metrics.
- **Fitness Tracking:** Real-time step counting, distance estimation, and calorie burn tracking.
- **Light Environment & Circadian Rhythm:** Monitors ambient light exposure (Dark to Very Bright) and tracks blue-light exposure ratios to help protect sleep quality.
- **Stress & Concentration Meter:** Evaluates ambient noise levels (LAeq dB) to classify the audio environment (Very Quiet to High Exposure) and computes a live Focus and Stress Index.
- **Local Persistence:** Uses SQLite to store session data and aggregate historical trends without needing a cloud backend.
- **Dynamic Theming:** Supports light and dark modes with customizable accent colors.

## Pages Overview

- **Connection Page:** Manages BLE discovery, connects to the wearable, and handles the raw byte-level framing of the incoming data stream to ensure reliable telemetry processing.
- **Dashboard:** A central hub providing an at-a-glance summary of all core metrics for the current active session.
- **Fitness Page:** Focused on physical activity. Displays live step counts, calculates estimated distance in real time, tracks calories burned, and shows weekly step progression charts.
- **Light Page:** Dedicated to ambient light and circadian rhythm tracking. Displays the current light intensity class and visually tracks the Blue-to-Clear light ratio via an intuitive circular gauge.
- **Stress & Noise Page:** Evaluates the acoustic environment in real-time. Features a dynamic noise waveform, WHO-based ear safety limits, and computes dual indices: a **Focus Index** (using light data) and a **Stress Index** (using noise data).

## Architecture & Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management:** `provider`
- **Bluetooth:** `flutter_blue_plus`
- **Database:** `sqflite`

## Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- A physical Android or iOS device (BLE cannot be tested on an emulator)
- A compatible smart wearable running the unified BLE firmware

### Installation
1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Connect your physical device.
4. Run the app using `flutter run`.

## Hardware Communication Protocol

The app communicates with the wearable using a **fire-and-forget push model**.
- **Packet Structure:** Fixed 20-byte payload.
- **Sentinels:** Starts with `0x7B` and ends with `0x7D` for payload alignment.
- **Message Type:** `0x55` for Unified Telemetry, `0x53` for Connection Events.

*(For detailed byte-level mapping, refer to the `lib/BLE_walkthrough.md` file).*
