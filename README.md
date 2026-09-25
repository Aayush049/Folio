# Folio

**Folio — The Offline Document Studio**

Folio is a cross-platform document scanner and management app built with Flutter. It combines camera-based capture, image cropping, on-device text recognition (OCR), digital signatures, and PDF export into a single offline-first workflow — no server, no account, and no internet connection required to scan, process, or store a document.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Supported Platforms](#supported-platforms)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Building a Release](#building-a-release)
- [Project Structure](#project-structure)
- [Running Tests](#running-tests)
- [Configuration Notes](#configuration-notes)
- [Roadmap](#roadmap)
- [Contributing](#contributing)

## Overview

Folio is aimed at anyone who needs to digitize paper documents quickly without relying on a cloud service. Documents are scanned or imported, cropped and cleaned up, optionally run through on-device OCR to extract text, optionally signed, and then exported as a PDF that can be shared through any installed app. All processing and storage happens locally on the device using SQLite, so the app works fully offline.

## Features

### Capture and Import
- Scan a document directly using the device camera
- Import existing photos from the device gallery
- Support for multipage documents within a single scan session

### Editing
- Crop and straighten scanned pages before saving
- Adjust and clean up individual pages ahead of export

### Text Recognition (OCR)
- On-device text extraction using Google ML Kit, with no data leaving the device
- Useful for making scanned documents searchable or for pulling text out of a photographed page

### Signatures
- Add a handwritten digital signature directly onto a document
- Useful for signing forms or agreements without printing them

### Export and Sharing
- Convert one or more scanned pages into a single PDF file
- Open exported files directly from within the app
- Share documents to other apps (email, messaging, cloud drives, etc.) using the platform share sheet

### Storage
- All documents and metadata are stored locally using SQLite
- No account, login, or network connection required to use the app

### Interface
- Consistent typography across platforms via Google Fonts
- Internationalization-ready date and number formatting via the `intl` package

## Tech Stack

| Category | Packages |
|---|---|
| Framework | Flutter |
| State Management | `flutter_bloc`, `provider`, `equatable` |
| Local Database | `sqflite`, `path_provider`, `path` |
| Image Capture & Editing | `image_picker`, `image_cropper` |
| Text Recognition (OCR) | `google_mlkit_text_recognition` |
| PDF Generation & Viewing | `pdf`, `open_filex` |
| Digital Signatures | `signature` |
| File Handling & Sharing | `file_picker`, `share_plus` |
| UI & Formatting | `google_fonts`, `intl`, `cupertino_icons` |
| Testing | `flutter_test`, `flutter_lints` |

## Architecture

Folio uses `flutter_bloc` for its primary state management, with `provider` used for lighter-weight or localized state where a full Bloc is unnecessary. `equatable` is used to simplify state and event comparisons within the Bloc layer.

The application logic in `lib/` is generally organized around the document lifecycle:

1. Capture or import a page (camera or gallery)
2. Edit the page (crop, adjust)
3. Optionally run OCR on the page
4. Optionally add a signature
5. Persist the document locally via SQLite
6. Export the document to PDF and share or open it

Refer to the `lib/` directory for the current folder-level breakdown of features, widgets, and data layers.

## Supported Platforms

Folio is scaffolded as a multi-platform Flutter project, with build targets for:

- Android
- iOS
- Windows
- Web

Platform-specific configuration lives in the `android/`, `ios/`, `windows/`, and `web/` directories respectively.

## Prerequisites

- Flutter SDK, Dart SDK `^3.11.5` or compatible
- Android Studio and/or Xcode, depending on which platform(s) you're targeting
- A connected physical device, or an emulator/simulator, for camera-based features (note that camera capture will not work in most desktop/web simulators)

## Getting Started

1. Clone the repository

   ```bash
   git clone https://github.com/Aayush049/Folio.git
   cd Folio
   ```

2. Install dependencies

   ```bash
   flutter pub get
   ```

3. Run the application

   ```bash
   flutter run
   ```

   To target a specific platform:

   ```bash
   flutter run -d chrome     # Web
   flutter run -d windows    # Windows
   flutter run -d android    # Android
   flutter run -d ios        # iOS
   ```

## Building a Release

```bash
flutter build apk       # Android APK
flutter build appbundle # Android App Bundle
flutter build ios       # iOS build
flutter build windows   # Windows executable
flutter build web       # Web build
```

Refer to the official Flutter documentation for platform-specific signing and release requirements: https://docs.flutter.dev/deployment

## Project Structure

```
Folio/
├── android/       # Android platform code and configuration
├── ios/           # iOS platform code and configuration
├── lib/           # Application source code (Dart)
├── test/          # Unit and widget tests
├── web/           # Web platform code and configuration
├── windows/       # Windows platform code and configuration
├── analysis_options.yaml  # Lint and static analysis rules
├── pubspec.yaml   # Project dependencies and metadata
├── pubspec.lock   # Locked dependency versions
└── README.md
```

## Running Tests

```bash
flutter test
```

Widget and unit tests live in the `test/` directory. Add new tests alongside the feature they cover as the codebase grows.

## Configuration Notes

- Camera and gallery access require platform permissions to be declared (camera and storage/photo library permissions on Android and iOS respectively). Check `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist` if you run into permission-related issues.
- OCR via Google ML Kit runs entirely on-device; no API key or network access is required for text recognition.
- Because storage is local (SQLite), documents are not currently synced across devices or backed up automatically — back up the app's data directory manually if needed.

## Roadmap

Potential areas for future development:

- Cloud backup / sync support
- Batch export of multiple documents at once
- Document tagging and search
- Dark mode refinements across all platforms