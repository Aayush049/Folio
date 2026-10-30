# Folio — The Offline Document Studio

<div align="center">

[![Live Demo](https://img.shields.io/badge/Live_Demo-Vercel-000000?style=for-the-badge&logo=vercel&logoColor=white)](https://folio-nine-omega-50.vercel.app)
[![Android Release](https://img.shields.io/badge/Android-Download_APK-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/Aayush049/Folio/releases/download/v1.0.0/folio.apk)
[![GitHub Release](https://img.shields.io/badge/Release-v1.0.0-blue?style=for-the-badge&logo=github)](https://github.com/Aayush049/Folio/releases/tag/v1.0.0)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Author](https://img.shields.io/badge/Author-Aayush-blue?style=for-the-badge&logo=github)](https://github.com/Aayush049)

**An offline-first document scanner, studio, and management application built with Flutter.**

[Launch Web App](https://folio-nine-omega-50.vercel.app) • [Download Android APK](https://github.com/Aayush049/Folio/releases/download/v1.0.0/folio.apk) • [Features](#features) • [Tech Stack](#tech-stack) • [Getting Started](#getting-started) • [Deployment](#deployment)

</div>

---

## Live Application & Releases

### 🌐 Web Production Build
The production web bundle is live and hosted on Vercel:
> **URL:** [https://folio-nine-omega-50.vercel.app](https://folio-nine-omega-50.vercel.app)  
> **Status:** Live & Operational  
> **Platform:** Web (PWA-ready with client-side WebAssembly SQLite)

### 📱 Android Release (APK)
A standalone release APK is published on GitHub Releases and ready for direct on-device download & installation:
> **Direct Download:** [**folio.apk (v1.0.0)**](https://github.com/Aayush049/Folio/releases/download/v1.0.0/folio.apk)  
> **GitHub Release Page:** [Folio v1.0.0 Release](https://github.com/Aayush049/Folio/releases/tag/v1.0.0)  
> **Architecture:** Universal Release Binary (ARM64, ARMv7, x86_64) with R8 / ProGuard optimization  
> **File Size:** ~90.5 MB

---

## Overview

**Folio** is a cross-platform document studio designed to capture, process, sign, and organize documents without relying on external servers or cloud services. All processing, text extraction, and storage remain strictly on the user's local device, providing privacy and full offline capability across mobile, desktop, and web platforms.

---

## Features

- **Document Capture & Import:** Scan via device camera or import existing images and files. Supports multi-page document sessions.
- **Editing Studio:** Crop, align, and apply contrast/color enhancement filters (`Original`, `Magic`, `B&W`, `Grey`) to optimize readability.
- **On-Device OCR:** Client-side text recognition powered by Google ML Kit with automated smart document naming based on recognized keywords.
- **Digital Signatures:** Draw handwritten signatures directly on the document canvas with customizable placement and sizing.
- **Multi-Page PDF Export:** Compile and export clean, high-resolution PDFs directly to local storage or share sheets.
- **Local Relational Storage:** Structured document and folder management backed by SQLite (`sqflite` natively, and `sqflite_common_ffi_web` with WebAssembly in browsers).

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Framework** | Flutter (v3.x) & Dart | Cross-platform UI toolkit |
| **Hosting** | Vercel | Global edge CDN hosting for the web app |
| **State Management** | `flutter_bloc`, `provider`, `equatable` | Unidirectional reactive state management |
| **Database** | `sqflite`, `sqflite_common_ffi_web` | Local SQLite with WebAssembly web worker |
| **PDF Engine** | `pdf`, `open_filex` | Vector document generation and file handling |
| **Processing** | `image_picker`, `image_cropper` | Image input, manipulation, and cropping |
| **OCR** | `google_mlkit_text_recognition` | On-device text recognition |
| **UI & Theming** | `google_fonts`, `signature` | Adaptive Neumorphic UI and signature pad |

---

## Project Structure

```text
folio/
├── folio.apk            # Compiled production Android APK binary
├── lib/
│   ├── blocs/           # BLoC state management (Dashboard, Scanner)
│   ├── core/            # Themes, color filters, and database helper
│   ├── models/          # Entity models (Document, Folder, Page)
│   ├── repositories/    # Database query abstraction layer
│   ├── services/        # PDF compilation, scanning, and OCR services
│   ├── ui/              # Screens and reusable Neumorphic UI widgets
│   └── main.dart        # Application entry point & web SQLite bootstrap
├── web/                 # Web manifest, icons, and SQLite WASM binaries
├── android/             # Android native platform files & ProGuard rules
├── ios/                 # iOS native platform files
└── windows/             # Windows native desktop files
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.11.5` or higher)
- [Dart SDK](https://dart.dev/get-dart)
- Android SDK / Android Studio (for Android build)
- Google Chrome (for web development)

### Setup & Local Execution

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Aayush049/Folio.git
   cd Folio
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on your target platform:**
   ```bash
   flutter run -d chrome     # Web
   flutter run -d windows    # Windows Desktop
   flutter run -d android    # Android Device / Emulator
   flutter run -d ios        # iOS Simulator / Device
   ```

---

## Deployment & Building

### 1. Web Release & Vercel Deployment
To compile the production web bundle and deploy to Vercel:
```bash
flutter build web --release
npx vercel build/web --prod
```

### 2. Android APK Release
To generate the standalone optimized release APK:
```bash
flutter build apk --release
```
The output file is generated at `build/app/outputs/flutter-apk/app-release.apk` (renamed as `folio.apk`).

---

## Author

Developed by **Aayush** ([@Aayush049](https://github.com/Aayush049)).
