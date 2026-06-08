# Acorde Flutter Application

Acorde is a cross-platform application for tab searching, monospaced chord visualization, and audio tuning. It has been migrated from React Native (TypeScript) to Flutter (Dart) utilizing a clean, test-driven approach.

---

## 🛠️ Linux Desktop Prerequisites

Before building or running the application on Linux, you must install the required development tools and desktop libraries.

Run the following command in your terminal:

```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev
```

---

## 🚀 Getting Started

1. **Clone the repository and navigate to the project directory:**
   ```bash
   cd flutter/acorde
   ```

2. **Fetch dependencies:**
   ```bash
   flutter pub get
   ```

---

## 💻 Running the Application

To run the application in development mode:

```bash
flutter run
```

If you have multiple devices or platforms enabled, you can run specifically on a target platform:

- **Linux Desktop:**
  ```bash
  flutter run -d linux
  ```
- **Web (Chrome):**
  ```bash
  flutter run -d chrome
  ```
- **Android Emulator / Device:**
  ```bash
  flutter run -d android
  ```

---

## 🏗️ Building the Application

To build the release binaries for the desired platform:

- **Linux Desktop:**
  ```bash
  flutter build linux
  ```
  *The executable and resources will be generated under `build/linux/x64/release/bundle/`.*

- **Android APK:**
  ```bash
  flutter build apk
  ```
  *The APK will be generated under `build/app/outputs/flutter-apk/app-release.apk`.*

- **Web Application:**
  ```bash
  flutter build web
  ```
  *The static files will be generated under `build/web/`.*

- **iOS:**
  ```bash
  flutter build ios --no-codesign
  ```

---

## 🧪 Running Tests

Acorde maintains a comprehensive, verified test suite for all components.

- **Run all unit & widget tests:**
  ```bash
  flutter test
  ```

- **Run specific test suites:**
  - **Tuner Autocorrelation Logic:** `flutter test test/core/tuner_logic_test.dart`
  - **Ultimate Guitar Parser:** `flutter test test/core/ug_parser_test.dart`
  - **Local SQLite Database:** `flutter test test/services/database_test.dart`
  - **SharedPreferences Settings:** `flutter test test/services/settings_test.dart`
  - **Navigation Tabs Smoke Test:** `flutter test test/widget_test.dart`
