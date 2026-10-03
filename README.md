# MIRALO

<p align="center">
  <img src="assets/logo.png" alt="MIRALO Logo" width="120" height="120" />
</p>

<p align="center">
  <strong>"Your AI. Your Space. Designed for What Matters."</strong><br>
  <em>Smart. Private. Yours.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.13+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Firebase-RTDB%20%26%20Auth-FFCA28?logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/Security-AES--GCM%20%2B%20HMAC-brightgreen" alt="Security" />
  <img src="https://img.shields.io/badge/License-Proprietary-red" alt="License" />
</p>

---

## 🌟 Overview

**MIRALO** is a dual-personality mobile application engineered in **Flutter**. It combines a modern, distraction-free **AI Assistant** with a discreet, end-to-end encrypted **Private Space** and an independently secured **Library Vault**.

1. **Public Persona (AI Assistant):** A sleek ChatGPT/Claude-style conversational assistant featuring token-streaming responses, markdown rendering, syntax-highlighted code blocks, and prompt recommendations.
2. **Stealth Persona (Private Workspace):** An isolated, cryptographically protected realm containing encrypted 1-on-1 and group chats, media sharing, and private document storage — invisible to casual inspection and accessible only via secret passcodes or local phrase interception.

---

## 📱 Visual Workflow

```
[01. Welcome] ──> [02. Sign Up] ──> [03. Sign In] ──> [04. Security Setup]
       │
       └──> [05. AI Home] ──> [06. AI Chat]
                   │
                   ├──> [07. Sidebar (Locked)] ──> [08. Unlock via Secret] ──> [09. Sidebar (Unlocked)]
                   │                                                                   │
                   │                                              ┌────────────────────┴────────────────────┐
                   │                                              ▼                                         ▼
                   │                                      [10. Private Chat]                       [18. Naughty Mode]
                   │                                              │
                   │                                    ┌─────────┴─────────┐
                   │                                    ▼                   ▼
                   │                           [11. Attachment]     [13. Image Viewer]
                   │                                    │
                   │                           ┌────────┴────────┐
                   │                           ▼                 ▼
                   │                   [12. Camera View]   [14. GIF Picker]
                   │
                   ├──> [15. Library Vault PIN] ──> [16. Library Home] ──> [17. File Viewer]
                   │
                   ├──> [19. Quick Emergency Exit]
                   │
                   └──> [20. Settings] ──> [21. Profile]
```

---

## 🚀 Key Features

### 1. 🤖 Next-Gen AI Assistant
- **Minimalist Mobile UI:** OLED deep black theme (`#080B10`) and clean light mode (`#F7F9FC`).
- **Markdown & Code Highlighting:** Formatted output with copyable code snippets, tables, and lists.
- **Quick Action Pills:** Rapid query starters (*Explain something*, *Help me write*, *Summarize this*, *Give me ideas*).
- **Multi-Model Selector:** Support for Gemini, GPT-4o, and Claude configurations.
- **Custom System Instructions & Controls:** Adjust system prompts, creativity/temperature, and context history.

### 2. 🔒 End-to-End Encrypted Private Space
- **Cryptographic Security:** AES-GCM encryption with HMAC authenticity verification for all chat payloads.
- **Discreet Bubbles & Stealth UI:** Neutral dark chat bubble aesthetics (`#1B2430` / `#151C25`) with zero color leak.
- **Message Hiding Mode:** Sensitive chat messages remain obscured until tapped or temporarily unhidden using your secret key.
- **Group Chats:** Create multi-member encrypted groups with role management (Owner, Admin, Member), invite codes, and `@all` mentions.
- **Friend Request & Discovery System:**
  - Real-time live invitations with instant hot-reload and pull-to-refresh synchronization.
  - Search by username (`@username`) or user ID.
  - Non-blocking chat deletion: remove conversations from your view without permanently blocking future communication.
- **Real-Time Presence & Accurate Last Seen:**
  - Active app lifecycle monitoring (`resumed`, `paused`, `inactive`, `detached`, `hidden`).
  - Broadcasts offline presence and timestamped last seen immediately when the app is backgrounded or closed.
  - Server-side cleanup via Firebase `.info/connected` and `.onDisconnect()` hooks.
  - Case-insensitive UID and username routing ensuring accurate status sync across all devices.
- **Typing Indicators & Receipts:** Real-time `typing...` indicators and sent/delivered/seen message state updates.

### 3. 📂 Independently Protected Library Vault
- **Dual-PIN Security:** Separate, independent credential protection from private chats.
- **Categorized Filing:** Organized folders (*Personal*, *Documents*, *College*, *Shared*, *Recently Added*).
- **In-App Previews:** Built-in viewer for images and documents with rename, download, and export capabilities.
- **Cloud Backup:** Optional encrypted backup tracking to Firebase and Cloudinary.

### 4. 🚨 Safety & Emergency Panic Controls
- **Quick Emergency Exit:** One-tap header button to immediately return to the clean AI home screen.
- **Stealth Command Interception:** Type local commands (e.g. `/urgent`) to lock spaces instantly.
- **No Badge Leakage:** Silent notifications and minimalist indicators without sensitive unread message counts.
- **Nuclear Local Wipe:** Instant sanitization of locally cached chat history and keys.

---

## 🛠️ Tech Stack & Architecture

- **Framework:** [Flutter](https://flutter.dev) (Dart 3+)
- **State Management:** `Provider` architecture with dedicated domain providers:
  - `AuthProvider`: Session management and persistent credentials.
  - `PrivateChatProvider`: Real-time chat streams, presence engine, and contacts.
  - `AiChatProvider`: Conversational inference and message histories.
  - `VaultProvider`: Passcode validation, lock states, and encryption keys.
  - `LibraryProvider`: File system and vault asset management.
  - `ThemeProvider`: Adaptive dark/light aesthetics.
- **Backend & Realtime:** Firebase Realtime Database (RTDB) & Firebase Authentication.
- **Media Hosting:** Cloudinary CDN for encrypted photo/video storage.
- **Audio & Media:** `record` package for voice notes, `image_picker` and `file_picker` for attachments.

---

## ⚙️ Getting Started

### Prerequisites
- **Flutter SDK:** `>= 3.13.0`
- **Dart SDK:** `>= 3.0.0`
- **Android Studio** / **Xcode** (for device builds)

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/aarushlohit/miralo.git
   cd miralo
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   - Ensure `lib/firebase_options.dart` is configured for your Firebase project.
   - Deploy appropriate Firebase Realtime Database rules (`rules.json`).

4. **Run with Environment Flags:**
   ```bash
   flutter run \
     --dart-define=CLOUDINARY_CLOUD_NAME="your_cloud_name" \
     --dart-define=CLOUDINARY_UPLOAD_PRESET="your_upload_preset"
   ```

---

## 🧪 Testing & Verification

Run static analysis to verify code health:
```bash
flutter analyze
```

Execute unit and integration provider tests:
```bash
flutter test test/longcat_providers_test.dart
```

---

## 🔐 Default Test Credentials

For development and testing environments:
- **Private Chat Secret:** `1234`
- **Library Vault PIN:** `1234`

---

## 📄 License

Copyright © 2026 MIRALO. All rights reserved.
