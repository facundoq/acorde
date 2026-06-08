# acorde
A pwa/react native app for android to download and store tabs and lyrics. Includes chord guide and tuner.

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

Once connected, you can run Detox, Appium, or any native Android instrumentation tests targeting the connected device.

To stop the emulator:
```bash
docker-compose -f docker-compose.android.yml down
```
