# MIRALO AI — Design System & Component Specification

> **"Your AI. Your Space. Designed for What Matters."**  
> **Tagline:** Focused · Private · Beautifully Simple  
> **Framework:** Flutter Native Mobile & Desktop (Mobile-first, responsive)

---

## 1. Design Principles

- **Calm & Minimal:** Free of unnecessary clutter, excessive glassmorphism, or loud gradients.
- **Unified Experience:** AI Assistant and Private Workspace share identical typography, spacing, navigation language, and interaction physics.
- **Discreet Security:** No flashy "secret mode" banners. Stealth interception via normal AI composer.
- **Neutral Dark Private Bubbles:** Outgoing private messages use dark charcoal (`#1B2430` / `#323236`) — **strictly never bright blue**.
- **Independent Credentials:** Private Chat Secret (`1234`) and Library Vault PIN (`1234`) are isolated session tokens.

---

## 2. Color System Tokens

### Light Theme (Warm, Clean, Soft)
| Token | Hex Value | Usage |
|---|---|---|
| `--background` | `#F7F9FC` | Scaffold background |
| `--surface` | `#FFFFFF` | Primary card & surface |
| `--surface-secondary` | `#F1F4F8` | Secondary container & inputs |
| `--surface-tertiary` | `#E9EEF5` | Grouped item background |
| `--border` | `#E2E8F0` | Subtle hairline borders |
| `--text-primary` | `#111827` | Headings & high contrast text |
| `--text-secondary` | `#64748B` | Subtitles & captions |
| `--text-muted` | `#94A3B8` | Hints & timestamp indicators |
| `--accent` | `#1677F2` | Primary buttons & active state |
| `--accent-soft` | `#E8F2FF` | Subtle highlights |
| `--danger` | `#EF4444` | Emergency actions & delete |
| `--success` | `#16A34A` | Online indicators & verified tags |

### Dark Theme (Deep Charcoal, OLED Friendly)
| Token | Hex Value | Usage |
|---|---|---|
| `--background` | `#080B10` | Scaffold background |
| `--surface` | `#0E131A` | Primary card & drawer background |
| `--surface-secondary` | `#151C25` | Secondary container & inputs |
| `--surface-tertiary` | `#1B2430` | Grouped items & message bubble |
| `--border` | `#263241` | Soft elevation borders |
| `--text-primary` | `#F5F7FA` | Primary reading text |
| `--text-secondary` | `#9AA7B7` | Secondary text |
| `--text-muted` | `#64748B` | Muted labels |
| `--accent` | `#2588FF` | Restrained focus & action blue |
| `--accent-soft` | `#102B4B` | Selected item background |
| `--danger` | `#F05252` | Destructive & panic actions |
| `--success` | `#35C98A` | Online status indicator |

---

## 3. Typography & Spacing System

- **Font Family:** Inter (`GoogleFonts.inter`), system fallback `SF Pro Display`
- **8px Grid System:** `4px`, `8px`, `12px`, `16px`, `20px`, `24px`, `32px`, `40px`, `48px`
- **Corner Radii:**
  - Inputs & Buttons: `12px` – `14px`
  - Cards: `16px` – `18px`
  - Bottom Sheets & Modals: `24px`
  - Circular Actions: `36px` × `36px` / `38px` × `38px`

---

## 4. Screen Implementation Map (21 Screens)

| # | Screen Name | Route / Component | File Path |
|---|---|---|---|
| **01** | Welcome | `/onboarding` | `lib/screens/onboarding/onboarding_screen.dart` |
| **02** | Sign Up | `/signup` | `lib/screens/auth/signup_screen.dart` |
| **03** | Sign In | `/login` | `lib/screens/auth/login_screen.dart` |
| **04** | Security Setup | `/security-setup` | `lib/screens/auth/security_setup_screen.dart` |
| **05** | AI Home | `/home` | `lib/screens/home/ai_home_screen.dart` |
| **06** | AI Chat | `/chat` | `lib/screens/ai_chat/ai_chat_screen.dart` |
| **07** | Sidebar (Locked) | Modal Drawer | `lib/widgets/common/app_sidebar_drawer.dart` |
| **08** | Unlock via Secret | `/private-chats` (locked) | `lib/screens/private_chat/private_chat_list_screen.dart` |
| **09** | Sidebar (Unlocked) | Modal Drawer | `lib/widgets/common/app_sidebar_drawer.dart` |
| **10** | Private Chat | `/private-chat` | `lib/screens/private_chat/private_chat_detail_screen.dart` |
| **11** | Attachment Menu | Bottom Sheet | `lib/widgets/chat/attachment_sheet.dart` |
| **12** | Camera Capture | Bottom Sheet | `lib/widgets/media/camera_view_sheet.dart` |
| **13** | Image Viewer | Route / Dialog | `lib/widgets/media/full_image_viewer.dart` |
| **14** | GIF Picker | Bottom Sheet | `lib/widgets/media/gif_picker_sheet.dart` |
| **15** | Library Vault | `/library/locked` | `lib/screens/library/library_locked_screen.dart` |
| **16** | Library Home | `/library` | `lib/screens/library/library_screen.dart` |
| **17** | File Viewer | Dialog Preview | `lib/widgets/library/file_preview_dialog.dart` |
| **18** | Naughty Mode | `/naughty-mode` | `lib/screens/naughty/naughty_mode_screen.dart` |
| **19** | Emergency Exit | `/emergency` | `lib/screens/emergency/emergency_screen.dart` |
| **20** | Settings | `/settings` | `lib/screens/settings/settings_screen.dart` |
| **21** | Profile | `/settings/profile` | `lib/screens/settings/profile_screen.dart` |

---

## 5. Security & Interception Rules

1. **AI Composer Secret Interception:** Typing the Private Chat Secret in the main AI prompt bar unlocks the private workspace without exposing the secret to the AI.
2. **Emergency Command (`/urgent`):** Typing `/urgent` instantly terminates private sessions, hides sensitive previews, and redirects to AI home.
3. **No Cross-Unlock:** Unlocking Private Chat does NOT unlock the Library Vault.
