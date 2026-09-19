# MIRALO AI

> **"Your AI. Your Space. Designed for What Matters."**  
> *Smart. Private. Yours.*

MIRALO AI is a minimal, distraction-free AI assistant with an integrated discreet private communication space and an independently encrypted Library Vault, engineered entirely in **Flutter**.

---

## Visual Overview & 21-Screen Board

The interface is handcrafted in code matching the exact 21-screen specification:

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

## Key Features

1. **AI Assistant (ChatGPT Mobile Aesthetic):**
   - OLED black dark mode (`#080B10`) & warm clean light mode (`#F7F9FC`).
   - Token-by-token streaming simulation with markdown and syntax-highlighted code blocks.
   - Quick prompt pills: *Explain something*, *Help me write*, *Summarize this*, *Give me ideas*.
   - Multi-model selector (`GPT-4o`, `Claude 3.5 Sonnet`, `Gemini 1.5 Pro`).

2. **Private Workspace (Zero Tracking & Stealth):**
   - Accessible via secret phrase / PIN interception inside the normal AI prompt bar.
   - Neutral dark chat bubbles (`#1B2430` / `#151C25`) — **never blue**.
   - Multi-contact chats (Sarah, Alex, Emma, Chris), emoji reactions, image attachments, GIF picker, and realistic camera viewfinder.

3. **Independently Protected Library Vault:**
   - Isolated PIN security layer.
   - Categorized file browser: *Personal*, *Documents*, *College*, *Shared*, *Recently Added*.
   - Full document and image preview dialogs with download, rename, and export capabilities.

4. **Safety & Emergency Panic Controls:**
   - Single-tap **Quick Exit to AI** button or local `/urgent` interception in chat.
   - Hide Mode to obfuscate contacts, preview snippets, and thumbnails.
   - Nuclear wipe actions for instant local data sanitization.

---

## Getting Started

### Prerequisites
- Flutter 3.13+ (or 3.47+)
- Dart 3.13+

### Run Locally
```bash
# Clone or navigate to the project directory
cd "/home/aarush/Myoffice/Personal Projects/miralo"

# Get dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run unit and widget test suite
flutter test

# Launch the app
flutter run
```

### Default Credentials (Test Environment)
- **Private Chat Secret:** `1234`
- **Library Vault PIN:** `1234`

---

## Assets
- `assets/logo.png` — Official MIRALO AI glowing blue orbital logo.
