# Acorde - Guitar Tabs & Chords Manager

Acorde is a cross-platform application (Web & Android) designed to search, save, and visualize guitar tabs from multiple online sources. It focuses on providing a clean, distraction-free reading experience with advanced features for musicians.

## 🌟 Core Features

### 1. Multi-Source Search
*   **Aggregated Results:** Search across Ultimate Guitar, Cifraclub, LaCuerda, and Cifras simultaneously.
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
*   **Dedicated Tab:** A new "Diagrams" tab allows for quick browsing and searching of the entire chord database.
*   **Search by Name:** Quickly find diagrams for any chord (e.g., "C#m7", "Bb", "Dsus4").
*   **Full Interactivity:** Uses the same reusable `ChordDetailModal` and `ChordDiagram` components, supporting swipable alternative shapes and barre visualization.

### 4. Guitar Tuner
*   **Real-time Pitch Detection:** A dedicated "Tuner" tab uses the device microphone to listen to guitar strings.
*   **Visual Feedback:** Features a high-precision meter that indicates how many "cents" off a string is from standard tuning (EADGBe).
*   **Interactive Controls:** Single-tap to start or stop the tuner.
*   **Multi-Platform Support:** 
    *   **Web:** Uses high-performance Web Audio API and Autocorrelation algorithm.
    *   **Native:** (Coming soon) Will utilize native audio buffers for low-latency detection.

### 5. Interactive Chord Diagrams
*   **Interactive Chords:** Every chord in a tab is clickable.
*   **Visual Diagrams:** Displays a guitar neck with finger positions (1-4), open strings (O), and muted strings (X).
*   **Barre Support:** Renders actual visual bars for barre chords instead of individual dots.
*   **Multiple Shapes:** For common chords (like 'C'), the app supports multiple fingerings. Users can **swipe** on the diagram to see alternative shapes.
*   **Smart Highlighting:** Chords missing from the database are highlighted in yellowish to notify the user.

## 🛠️ Technical Architecture

### Tech Stack
*   **Framework:** React Native (Expo Router) for Web and Android.
*   **Database:** `expo-sqlite` for persistent local storage of saved songs.
*   **Parsing:** `cheerio` (v1.0.0-rc.12) for HTML scraping and custom regex-based parsers for tab alignment.
*   **UI Components:** Custom themed components supporting Light and Dark modes.

### Cross-Platform Strategy
*   **CORS Management:**
    *   **Web:** Uses a multi-proxy rotation (corsproxy.io, allorigins, thingproxy) to fetch data from restricted sites.
    *   **Android:** Fetches directly without proxies to bypass web restrictions.
*   **PagerView Shim:** A custom implementation of `PagerView` that uses `ScrollView` on Web and the native component on Android to avoid environment-specific crashes.
*   **ABI Splitting:** Configured Gradle to generate architecture-specific APKs (`arm64-v8a`), reducing file size from 97MB to ~39MB.

## 🚀 Build & Development

### APK Generation
A custom script `build-apk.sh` automates the entire pipeline:
1.  Builds the `acorde-core` library.
2.  Prebuilds the Android native project.
3.  Installs necessary Android SDK components.
4.  Runs Gradle with ABI splitting and minification.
5.  Copies the optimized APK to the public web folder for easy download.

### Serving the App
*   The production build can be served on port 80 (standard HTTP) or 8082 (development default).
*   The web app includes a "Download APK" button in settings, allowing web users to easily switch to the native Android experience.

## 🔒 Privacy & Storage
*   **Local-First:** All saved songs are stored locally on the user's device.
*   **No Accounts Required:** No cloud syncing or external accounts are needed to manage your personal tab collection.
