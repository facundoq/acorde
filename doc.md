# Acorde - Guitar Tabs & Chords Manager

Acorde is a cross-platform application (Web & Android) designed to search, save, and visualize guitar tabs from multiple online sources. It focuses on providing a clean, distraction-free reading experience with advanced features for musicians.

## 🌟 Core Features

### 1. Multi-Source Search
*   **Aggregated Results:** Search across Ultimate Guitar, Cifraclub, LaCuerda, and Cifras simultaneously.
*   **PRO Filtering:** Automatically filters out paywalled "Official" and "Pro" tabs from Ultimate Guitar, ensuring all results are accessible for free.
*   **Debug Mode:** A built-in troubleshooting console (toggleable in settings) that captures network logs and HTTP errors directly in the UI, essential for diagnosing connection issues on Android.
*   **Configurable Sources:** Users can toggle specific providers on or off in the settings.
*   **Direct Saving:** Found tabs can be added to a local library with a single click.

### 2. Advanced Tab Visualization
*   **Automatic Format Detection:** The app detects if a tab follows the "Ultimate Guitar" format (`[ch]`, `[tab]` tags).
*   **The Aligned-Wrapping Algorithm:**
    *   **The Problem:** Traditional tabs break alignment when text wraps on small screens.
    *   **The Solution:** Acorde pairs chord lines with their corresponding lyrics line and splits them into "atomic segments". Each segment (Chord + Text) wraps as a single unit, ensuring the chord stays perfectly positioned above its syllable.
*   **Monospace Precision:** Uses the `SpaceMono` font to maintain character-level alignment across all devices.
*   **Dynamic Font Sizing:** Adjustable font size controls (+/-) in the top header for better readability.

### 3. Chord Diagrams Explorer
*   **Dedicated Tab:** A "Diagrams" tab allows for quick browsing and searching of the entire chord database.
*   **Search by Name:** Quickly find diagrams for any chord (e.g., "C#m7", "Bb", "Dsus4").
*   **Expanded Database:** Includes advanced and specialized shapes (e.g., `C#mM7`, `C#m6`, `D#7/A#`) frequently used in complex songs like "Ojalá".
*   **Full Interactivity:** Uses the same reusable `ChordDetailModal` and `ChordDiagram` components, supporting swipable alternative shapes and barre visualization.

### 4. Guitar Tuner
*   **Real-time Pitch Detection:** A dedicated "Tuner" tab uses the device microphone to listen to guitar strings.
*   **Modern Audio Engine:** Built on `expo-audio` (SDK 55+) for future-proof performance and improved stability on Android.
*   **Visual Feedback:** Features a high-precision meter that indicates how many "cents" off a string is from standard tuning (EADGBe).
*   **Interactive Controls:** Single-tap to start or stop the tuner. Supports multiple instruments (Guitar, Ukulele, Bass) and tunings (Standard, Drop D, Half Step Down).

### 5. Interactive Chord Diagrams
*   **Interactive Chords:** Every chord in a tab is clickable.
*   **Visual Diagrams:** Displays a guitar neck with finger positions (1-4), open strings (O), and muted strings (X).
*   **Barre Support:** Renders actual visual bars for barre chords instead of individual dots.
*   **Multiple Shapes:** For common chords (like 'C'), the app supports multiple fingerings. Users can **swipe** on the diagram to see alternative shapes.
*   **Smart Highlighting:** Chords missing from the database are highlighted in yellowish to notify the user.

## 🛠️ Technical Architecture

### Tech Stack
*   **Framework:** React Native (Expo SDK 55) with Expo Router.
*   **Audio Engine:** `expo-audio` for microphone access and pitch analysis.
*   **Database:** `expo-sqlite` for persistent local storage of saved songs.
*   **Parsing:** `cheerio` (v1.0.0-rc.12) for HTML scraping and custom regex-based parsers for tab alignment.
*   **UI Components:** Custom themed components supporting Light and Dark modes.

### Cross-Platform Strategy
*   **CORS Management:**
    *   **Web:** Uses a multi-proxy rotation (corsproxy.io, allorigins, thingproxy) to fetch data from restricted sites.
    *   **Android:** Fetches directly without proxies using `react-native-fetch-api` to bypass web restrictions.
*   **PagerView Shim:** A custom implementation of `PagerView` that uses `ScrollView` on Web and the native component on Android to avoid environment-specific crashes.
*   **Dependency Optimization:** Uses targeted patches (e.g., `expo-asset` export fixes) and ABI splitting to ensure small, stable binaries.

## 🚀 Build & Development

### APK Generation
A custom script `build-apk.sh` automates the entire pipeline:
1.  Builds the `acorde-core` library.
2.  Prebuilds the Android native project.
3.  Installs necessary Android SDK components.
4.  Runs Gradle with ABI splitting and minification.
5.  Copies the optimized APK to the public web folder for easy download.

## 🔒 Privacy & Storage
*   **Local-First:** All saved songs are stored locally on the user's device.
*   **No Accounts Required:** No cloud syncing or external accounts are needed to manage your personal tab collection.
