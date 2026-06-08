# Agent Guidelines: Acorde Flutter Migration

This document provides guidelines for Gemini (and other AI agents) on how to interact with the Acorde Flutter codebase during the migration and ongoing development.

## Project Structure

The project uses a unified Flutter architecture located at `flutter/acorde`:
- **`lib/core/`**: Dart implementations of scraping, parsing logic, and data models.
- **`lib/ui/`**: Flutter UI components, screens, and themes.
- **`lib/services/`**: Infrastructure such as database interactions (`sqflite`) and the headless webview scraper (`flutter_inappwebview`).
- **`test/`**: Unit, widget, and integration tests.

## Test-Driven Migration Rule

**CRITICAL:** Every piece of logic ported from TypeScript/React Native to Dart/Flutter MUST have its corresponding test suite ported *first* or *alongside* the logic.
1. Port the test.
2. Run the test (it should fail or not compile).
3. Port the logic.
4. Verify the test passes before moving to the next component.

## Running Tests

When modifying the codebase, run the following commands from the `flutter/acorde` directory to evaluate the code:

### 1. Unit & Widget Tests
To execute all unit tests for the core logic and widget tests for the UI components:
```bash
flutter test
```
*Note: Ensure you are in the `flutter/acorde` directory before running.*

### 2. Integration Tests
To run full UI automation tests (which replace the old Playwright tests):
```bash
flutter test integration_test/
```
*Note: This requires a running emulator/simulator. If one is not running, you can use the provided Android Docker container via `docker-compose -f docker-compose.android.yml up -d` at the project root, connect ADB, and then run the integration tests targeting the containerized device.*

## Code Generation

If you introduce packages like `freezed` or `riverpod_generator` that rely on code generation, ensure you run the build runner after creating or modifying the source files:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Static Analysis

Always ensure your modifications conform to the Dart analyzer and formatting rules:
```bash
flutter analyze
flutter format .
```

By following these rules, agents can guarantee a stable, 100% verified migration of the Acorde application.
