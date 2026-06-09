# Acorde Flutter Application

Acorde is a cross-platform application for tab searching, monospaced chord visualization, and audio tuning. It has been migrated from React Native (TypeScript) to Flutter (Dart) utilizing a clean, test-driven approach.

---

## 🛠️ Linux Desktop Prerequisites

Before building, running, or testing the application on Linux, you must install all the required development tools, desktop libraries, database dependencies, and external utilities.

### 1. Build and System Libraries
Flutter requires standard development tools, GTK, LZMA, and C++ libraries. Install them by running:

```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
```

### 2. Database Dependency (SQLite)
The application uses SQLite (`sqflite_common_ffi`) to persist saved songs locally on desktop platforms. You must have the SQLite development libraries installed:

```bash
sudo apt-get install -y libsqlite3-dev
```

### 3. Chromium (Required for Web Scraping)
Because `flutter_inappwebview` does not support Linux desktop, the application uses a **headless Chromium subprocess** to execute JavaScript and bypass bot-detection mechanisms when fetching tabs from sites like Ultimate Guitar and Cifra Club.

You must install Chromium (or Google Chrome) to use the online search features:

```bash
sudo apt-get install -y chromium-browser
# Or on other distributions:
sudo apt-get install -y chromium
```

The application will check the following binaries on your PATH in order:
1. `chromium-browser`
2. `chromium`
3. `google-chrome-stable`
4. `google-chrome`

If none are available, the app falls back to a plain HTTP scraper, which will likely be blocked by bot-detection.

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
