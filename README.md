<div align="center">

# 📄 Folio — The Offline Document Studio

[![Live Demo](https://img.shields.io/badge/Live%20Demo-Visit%20App-000000?style=for-the-badge&logo=vercel&logoColor=white)](https://folio-nine-omega-50.vercel.app)
[![Deployment](https://img.shields.io/github/deployments/Aayush049/folio/production?label=Vercel&logo=vercel&style=for-the-badge)](https://folio-nine-omega-50.vercel.app)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

<br/>

**A secure, offline-first document scanner and management studio.**  
Capture, crop, extract text (OCR), sign digitally, and export high-resolution PDFs —  
all without a backend or cloud subscription.

<br/>

[🌐 Live Web App](https://folio-nine-omega-50.vercel.app) &nbsp;•&nbsp; [✨ Features](#-features) &nbsp;•&nbsp; [🏗️ Architecture](#%EF%B8%8F-architecture) &nbsp;•&nbsp; [🚀 Quick Start](#-getting-started) &nbsp;•&nbsp; [🗺️ Roadmap](#%EF%B8%8F-roadmap)

</div>

---

## 🌐 Live Deployment

> **🟢 Status: Live & Active**  
> **URL:** **[https://folio-nine-omega-50.vercel.app](https://folio-nine-omega-50.vercel.app)**

Hosted on **Vercel's Edge Network** with:
- ⚡ Progressive Web App (PWA) support — installable from the browser
- 🗄️ Client-side SQLite powered by **WebAssembly** — no server, no database calls
- 🌍 Global CDN — fast load times worldwide

---

## 📖 Overview

**Folio** is built for anyone who needs to digitize, organize, and export paper documents quickly and securely — without handing personal files over to third-party cloud servers.

Everything runs **locally on your device or browser**:

| 🔒 Zero Cloud Dependency | ⚡ WASM-Powered SQLite | 📄 Instant PDF Export |
|:---:|:---:|:---:|
| Scanned documents, folders, and metadata never leave your device | High-performance local SQL engine running in native apps and web browsers | Compile multi-page scans into formatted, searchable PDF files ready to share |

---

## ✨ Features

### 📸 Capture & Import
- **Camera Scanning** — Capture pages on mobile or desktop via webcam with auto-focus and flash controls
- **Multi-Page Sessions** — Scan or upload multiple pages sequentially into a single unified document
- **Gallery & File Upload** — Import existing documents, receipts, or photos from local storage

### ✂️ Document Studio & Editing
- **Interactive Cropping** — Straighten edges, adjust aspect ratios, and remove messy backgrounds
- **Visual Filters** — Contrast and colour optimisation presets for enhanced scanning clarity

### 🔍 On-Device OCR (Text Recognition)
- **Smart Naming** — Context-aware keyword detection that auto-suggests document names (e.g. *Amazon_Invoice*, *Passport_Scan*, *Contract*)
- **Text Extraction** — On-device OCR powered by **Google ML Kit** with zero external API calls

### ✍️ Digital Signatures
- **Handwritten Signature Pad** — Draw and embed signatures directly onto documents before export
- **Position & Scale** — Customise placement for signing agreements, contracts, and receipts

### 📑 PDF Export & Sharing
- **Multi-Page Compilation** — Combine scanned pages into a single, optimised PDF
- **Direct Preview & Share** — Preview exported PDFs in-app and share via system share sheets or direct browser downloads

### 💾 Local SQLite Database
- **Offline Storage** — Document records, folder structures, and page references persisted via SQLite (`sqflite` / `sqflite_common_ffi_web` WebAssembly worker on web)
- **Categorisation** — Create custom folders to organise personal, financial, and work documents

---

## 🛠️ Tech Stack

| Layer | Technology | Version | Purpose |
|---|---|---|---|
| **Framework** | [Flutter](https://flutter.dev) + [Dart](https://dart.dev) | `^3.x / SDK ^3.11.5` | Multi-platform declarative UI toolkit |
| **Hosting** | [Vercel](https://vercel.com) | Edge Network | Global CDN deployment for the web app |
| **State Management** | `flutter_bloc` + `provider` + `equatable` | `8.1.6 / 6.1.2 / 2.0.5` | Scalable BLoC pattern for predictable state flow |
| **Database** | `sqflite` + `sqflite_common_ffi_web` | `2.3.0 / 1.2.0` | Local relational database with WebAssembly fallback |
| **PDF Generation** | `pdf` | `3.10.10` | Pure Dart PDF creation and document layout engine |
| **Image Processing** | `image_picker` + `image_cropper` | `1.1.2 / 8.0.2` | Multi-source image capture and crop matrix |
| **Text Recognition** | `google_mlkit_text_recognition` | `0.13.0` | High-accuracy on-device OCR engine |
| **Signature Pad** | `signature` | `5.5.0` | Responsive canvas signature capture |
| **File Handling** | `file_picker` + `open_filex` + `share_plus` | `13.1.0 / 4.5.0 / 13.3.0` | Cross-platform file access, open, and share |
| **Design** | `google_fonts` + `cupertino_icons` | `6.2.1 / 1.0.8` | Neumorphic dark/light adaptive design system |
| **Internationalisation** | `intl` | `0.19.0` | Date/time formatting and locale support |

---

## 🏗️ Architecture

Folio follows a clean, layered architecture that strictly separates UI, presentation state, and data management:

```
┌──────────────────────────────────────────────────────────┐
│                   UI & Screen Layer                       │
│   DashboardScreen  •  StudioScreen  •  ScannerScreen     │
└────────────────────────▲─────────────────────────────────┘
                         │  Events & States (BLoC)
┌────────────────────────┴─────────────────────────────────┐
│                  BLoC Presentation Layer                  │
│          DashboardBloc          •       ScannerBloc       │
└────────────────────────▲─────────────────────────────────┘
                         │  Repository Ingestion
┌────────────────────────┴─────────────────────────────────┐
│               Domain & Service Layer                      │
│  DocumentRepository  •  ScannerService  •  PdfService    │
└────────────────────────▲─────────────────────────────────┘
                         │  Local Persistence
┌────────────────────────┴─────────────────────────────────┐
│              Data Storage & WebAssembly Layer             │
│     SQLite  (sqflite  /  sqflite_common_ffi_web WASM)    │
└──────────────────────────────────────────────────────────┘
```

**Design principles applied:**
- 📦 **BLoC Pattern** — Events in, States out; fully testable business logic
- 🔄 **Repository Pattern** — Data sources swappable without touching UI
- 🌐 **Platform Abstraction** — Same codebase runs on Web, Android, iOS, and Windows via platform-aware database initialisation

---

## 📂 Project Structure

```
folio/
├── lib/
│   ├── blocs/                        # Business Logic Components (BLoCs)
│   │   ├── dashboard/                #   Dashboard events, states & bloc
│   │   └── scanner/                  #   Scanning, OCR & processing flow
│   ├── core/                         # App-wide constants, themes & DB setup
│   │   ├── color_filters.dart        #   Image filter presets
│   │   ├── database_helper.dart      #   Cross-platform SQLite initialisation
│   │   └── folio_theme.dart          #   Day/Night theme notifier & styles
│   ├── models/                       # Data entities — Document, Folder, Page
│   ├── repositories/                 # Document & folder database abstraction
│   ├── services/                     # PDF compilation & OCR orchestration
│   ├── ui/
│   │   ├── screens/                  #   Dashboard, Detail, Studio, Scanner
│   │   └── widgets/                  #   Neumorphic controls, tiles, badges
│   └── main.dart                     # App entry point & multi-platform bootstrap
├── web/                              # Web-specific assets
│   ├── index.html                    #   PWA shell
│   ├── sqflite_sw.js                 #   SQLite Web Worker script
│   └── sqlite3.wasm                  #   SQLite WebAssembly binary
├── android/                          # Android native project
├── ios/                              # iOS native project
├── windows/                          # Windows desktop native project
├── pubspec.yaml                      # Dependencies & project metadata
└── README.md
```

---

## 📱 Supported Platforms

| Platform | Status | Minimum Version |
|---|:---:|---|
| 🌐 **Web** (Chrome, Edge, Safari, Firefox) | ✅ Live | Modern browsers with WASM support |
| 🤖 **Android** | ✅ Supported | API 21+ (Android 5.0+) |
| 🍎 **iOS** | ✅ Supported | iOS 12.0+ |
| 🪟 **Windows** | ✅ Supported | Windows 10 / 11 |

> The web build is installable as a **Progressive Web App (PWA)** — click *"Add to Home Screen"* or *"Install"* in your browser's address bar.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) — version `^3.11.5` or compatible
- [Dart SDK](https://dart.dev/get-dart) — bundled with Flutter
- **Chrome** for web testing, or **Android Studio / Xcode** for mobile targets

### 1. Clone the Repository

```bash
git clone https://github.com/Aayush049/folio.git
cd folio
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run Locally

```bash
# Web (Chrome)
flutter run -d chrome

# Windows Desktop
flutter run -d windows

# Android device or emulator
flutter run -d android

# iOS simulator or device
flutter run -d ios
```

---

## 📦 Building for Production

### Web Release

```bash
flutter build web --release
# Output: build/web/
```

### Deploy to Vercel

```bash
npx vercel build/web --prod
```

### Mobile & Desktop Releases

```bash
flutter build apk --release         # Android APK
flutter build appbundle --release   # Google Play App Bundle
flutter build ipa --release         # iOS Archive (requires Xcode)
flutter build windows --release     # Windows Desktop Executable
```

---

## 🧪 Testing

Run the automated test suite:

```bash
flutter test
```

---

## 🗺️ Roadmap

| Status | Feature |
|:---:|---|
| ✅ | Client-side SQLite with WebAssembly support |
| ✅ | Production web deployment to Vercel |
| ✅ | Multi-page PDF compilation & export |
| ✅ | On-device OCR with smart document naming |
| ✅ | Digital signature pad |
| 🔲 | Batch document export as bundled ZIP archives |
| 🔲 | Document tagging, search indexing & colour labelling |
| 🔲 | Encrypted PDF export with password protection |
| 🔲 | Cloud backup / sync integration (opt-in, end-to-end encrypted) |

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!  
Feel free to open an [issue](https://github.com/Aayush049/folio/issues) or submit a pull request.

1. Fork the repository
2. Create your feature branch: `git checkout -b feat/amazing-feature`
3. Commit your changes: `git commit -m 'feat: add amazing feature'`
4. Push to the branch: `git push origin feat/amazing-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Built with ❤️ by [Aayush](https://github.com/Aayush049) &nbsp;•&nbsp; Powered by **Flutter** & **Vercel**

⭐ If you find this project useful, please consider giving it a star!

</div>
