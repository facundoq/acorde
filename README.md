# Acorde

A Flutter app for Android, Linux, Web, iOS, and Windows to search, download, and store guitar tabs and lyrics. Includes a chord diagram explorer and a guitar tuner.

The app is located in the `src/` directory.

## Getting Started

1. **Navigate to the app directory:**
   ```bash
   cd src
   ```

2. **Fetch dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

See [`src/README.md`](src/README.md) for full build, run, and testing instructions.

## 🛠️ Linux Desktop Prerequisites

Before building or running the application on Linux, you must install the following system dependencies, libraries, and utilities.

### System dependencies install command:

```bash
# 1. Update your package lists
sudo apt-get update

# 2. Install build tools, GTK headers, compression libraries, C++ compiler, and SQLite3
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev libsqlite3-dev

# 3. Install Chromium (required for headless web scraping/javascript execution)
sudo apt-get install -y chromium-browser
```

*Note: Headless Chromium is required on Linux because `flutter_inappwebview` lacks Linux desktop support. The app uses Chromium to execute JavaScript and render page contents dynamically from tab sites. Supported PATH binaries include: `chromium-browser`, `chromium`, `google-chrome-stable`, and `google-chrome`.*


## Android Testing Container

You can run an Android emulator in a Docker container to execute test suites for the Android version of the app. This relies on `budtmo/docker-android`.

### Starting the Container

Run the following command at the root of the project to spin up the Android emulator container:

```bash
docker-compose -f docker-compose.android.yml up -d
```

### Accessing the Emulator

- **Web UI**: Access the emulator's screen directly from your browser by navigating to `http://localhost:6080`.
- **ADB Access**: You can connect to the emulator using ADB for running test suites:
  ```bash
  adb connect localhost:5555
  ```

Once connected, you can run Flutter integration tests targeting the connected device:

```bash
cd src
flutter test integration_test/
```

To stop the emulator:
```bash
docker-compose -f docker-compose.android.yml down
```
