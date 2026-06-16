# Acorde - Guitar Tabs & Chords Manager

Acorde is a cross-platform application (Android, Linux, Web, iOS, and Windows) built with Flutter, designed to search, save, and visualize guitar tabs from multiple online sources. It focuses on providing a clean, distraction-free reading experience with advanced features for musicians.

## 🌟 Core Features

### 1. Multi-Source Search
*   **Aggregated Results:** Search across Ultimate Guitar, Cifraclub, LaCuerda, and Cifras simultaneously.
*   **PRO Filtering:** Automatically filters out paywalled "Official" and "Pro" tabs from Ultimate Guitar, ensuring all results are accessible for free.
*   **Configurable Sources:** Users can toggle specific providers on or off in the settings.
*   **Direct Saving:** Found tabs can be added to a local library with a single tap.

### 2. Advanced Tab Visualization
*   **Automatic Format Detection:** The app detects if a tab follows the "Ultimate Guitar" format (`[ch]`, `[tab]` tags).
*   **The Aligned-Wrapping Algorithm:**
    *   **The Problem:** Traditional tabs break alignment when text wraps on small screens.
    *   **The Solution:** Acorde pairs chord lines with their corresponding lyrics line and splits them into "atomic segments". Each segment (Chord + Text) wraps as a single unit, ensuring the chord stays perfectly positioned above its syllable.
*   **Monospace Precision:** Uses the `SpaceMono` and `RecursiveMono` fonts to maintain character-level alignment across all devices.
*   **Dynamic Font Sizing:** Adjustable font size controls (+/-) in the top header for better readability.

### 3. Chord Diagrams Explorer
*   **Dedicated Screen:** A "Diagrams" tab allows for quick browsing and searching of the entire chord database.
*   **Search by Name:** Quickly find diagrams for any chord (e.g., "C#m7", "Bb", "Dsus4").
*   **Expanded Database:** Includes advanced and specialized shapes (e.g., `C#mM7`, `C#m6`, `D#7/A#`) frequently used in complex songs.
*   **Full Interactivity:** Uses the reusable `ChordDetailModal` and `ChordDiagram` widgets, supporting swipeable alternative shapes and barre visualization.

### 4. Guitar Tuner
*   **Real-time Pitch Detection:** A dedicated "Tuner" tab uses the device microphone to listen to guitar strings.
*   **Visual Feedback:** Features a high-precision meter that indicates how many "cents" off a string is from standard tuning (EADGBe).
*   **Interactive Controls:** Single-tap to start or stop the tuner. Supports multiple instruments (Guitar, Ukulele, Bass) and tunings (Standard, Drop D, Half Step Down).

### 5. Interactive Chord Diagrams
*   **Interactive Chords:** Every chord name in a tab is tappable.
*   **Visual Diagrams:** Displays a guitar neck with finger positions (1–4), open strings (O), and muted strings (X).
*   **Barre Support:** Renders actual visual bars for barre chords instead of individual dots.
*   **Multiple Shapes:** For common chords (like 'C'), the app supports multiple fingerings. Users can **swipe** on the diagram to see alternative shapes.
*   **Smart Highlighting:** Chords missing from the database are highlighted to notify the user.

## 🛠️ Technical Architecture

### Tech Stack
*   **Framework:** Flutter (Dart) with Material 3.
*   **Database:** `sqflite` for persistent local storage of saved songs. `sqflite_common_ffi` is used for desktop (Linux, macOS, Windows) support.
*   **HTML Parsing:** `html` (Dart package) for scraping and custom regex-based parsers for tab alignment.
*   **Network Fetching:** `flutter_inappwebview` (headless WebView) for native platforms to handle client-side rendering and execute JavaScript; falls back to `http` for web or when WebView initialization fails.
*   **Settings:** `shared_preferences` for user preferences persistence.
*   **UI:** Custom Material 3 themed widgets supporting Light and Dark modes (system-adaptive).

### Project Structure

```
src/
├── lib/
│   ├── core/               # Business logic, data models, parsers
│   │   ├── models.dart
│   │   ├── ug_parser.dart  # Ultimate Guitar tab format parser
│   │   ├── chord_shapes.dart
│   │   ├── tuner_utils.dart
│   │   ├── logger.dart
│   │   └── sources/        # Per-site scraping implementations
│   │       ├── ultimate_guitar_source.dart
│   │       ├── cifraclub_source.dart
│   │       ├── cifras_source.dart
│   │       └── la_cuerda_source.dart
│   ├── services/           # Infrastructure (DB, network, settings)
│   │   ├── database.dart
│   │   ├── fetcher.dart    # WebView + HTTP fetcher
│   │   └── settings.dart
│   └── ui/
│       ├── components/     # Reusable widgets
│       │   ├── chord_diagram.dart
│       │   ├── chord_detail_modal.dart
│       │   └── ug_song_view.dart
│       └── screens/        # App screens
│           ├── home_tabs.dart
│           ├── search_screen.dart
│           ├── song_detail_screen.dart
│           ├── diagrams_screen.dart
│           └── tuner_screen.dart
├── test/                   # Unit & widget tests
└── integration_test/       # Full UI automation tests
```

### Cross-Platform Strategy
*   **Network Scraper Architecture:**
    *   **Android / iOS / macOS:** Uses a headless `flutter_inappwebview` WebView to load pages with full JavaScript execution, ensuring accurate page rendering.
    *   **Linux Desktop:** Uses a **headless Chromium subprocess** (`chromium --headless=new --dump-dom <url>`) for full JS rendering. Tries `chromium-browser`, `chromium`, `google-chrome-stable`, and `google-chrome` in order. Falls back to plain HTTP if no browser binary is found. Requires `chromium-browser` or equivalent to be installed.
    *   **Web:** Fetches directly via `http`; CORS must be handled by the target servers or a proxy.
*   **Desktop Database:** `sqflite_common_ffi` provides SQLite support on Linux, macOS, and Windows (where the native `sqflite` plugin is not available).

## 🚀 Build & Development

See [`src/README.md`](src/README.md) for complete setup, run, build, and test instructions.

### Quick Reference

```bash
cd src
flutter pub get
flutter run              # Run on a connected device or emulator
flutter test             # Run unit & widget tests
flutter build apk        # Build Android APK
flutter build linux      # Build Linux desktop binary
flutter build web        # Build web app
```

## 🔒 Privacy & Storage
*   **Local-First:** All saved songs are stored locally on the user's device using SQLite.
*   **No Accounts Required:** No cloud syncing or external accounts are needed to manage your personal tab collection.
