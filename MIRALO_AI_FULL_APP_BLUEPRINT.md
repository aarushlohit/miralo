# MIRALO AI — Full Application Blueprint

**Version:** MVP v1.0  
**Platform:** Flutter mobile application  
**Primary Theme:** Premium light and dark UI  
**Product Type:** AI API wrapper with discreet private communication and protected personal library

---

## 1. Product Overview

Miralo AI is a premium, mobile-first AI assistant built around a clean ChatGPT-style conversation experience.

The primary purpose of the application is to let users communicate with an external AI model through a polished interface. Miralo AI does not train or host its own model in the mobile app. It connects to an AI backend, which communicates with configured model providers.

Miralo AI also contains an optional private communication layer. The private layer is unlocked by entering a user-configured secret phrase or number directly into the **same normal AI message composer**. Once unlocked, private contacts become available through the sidebar. The user can select a person and chat using the same unified Miralo AI conversation interface.

The application must never look like two unrelated apps.

> **Miralo AI = Premium AI chat + discreet private communication + independently protected personal library.**

---

## 2. Explicit Product Boundaries

### Included

- AI text chat through an external API
- Firebase authentication
- AI conversation history
- Model selection
- Streaming AI responses
- Private person-to-person conversations
- Private text messages
- Private image messages
- Camera capture
- Gallery selection
- GIF sending
- Emoji reactions
- Private media viewer
- Private Library
- Independent Library Vault PIN
- Hide Mode
- Quick Exit / Emergency transition
- Local slash commands
- Light and dark themes
- Premium mobile UI

### Excluded from MVP

- Projects
- Web search
- Browsing
- Search engine integration
- Image generation
- AI image analysis
- AI vision
- Voice/video calling
- Public social feed
- Public profiles
- Complex productivity dashboards
- Plugin marketplace
- Scheduled tasks
- Remote tools
- Canvas
- Multi-agent workflows
- Automatic intimate-media analysis

---

## 3. Product Principles

1. AI chat is the default experience.
2. The app must look like a serious AI assistant.
3. Private functionality must not create a separate visual application.
4. The secret is entered through the normal AI composer.
5. Private Chat Secret and Library Vault PIN are independent.
6. Private media is never automatically saved to the device gallery.
7. Private content is never sent to the AI provider automatically.
8. Emergency actions must be fast and local.
9. Light and dark modes must share the same design system.
10. Privacy claims must be realistic; the app cannot prevent screenshots or external recording.

---

# 4. Application Architecture

## High-Level Areas

```text
MIRALO AI
│
├── Authentication
│
├── AI Assistant
│   ├── New Chat
│   ├── Recent Chats
│   ├── Pinned Chats
│   └── AI Conversation
│
├── Private Communication
│   ├── Private Contacts
│   ├── Private Conversations
│   ├── Camera
│   ├── Gallery
│   ├── GIFs
│   ├── Reactions
│   └── Naughty Mode
│
├── Private Library
│   ├── Library Lock
│   ├── Folders
│   ├── Files
│   ├── Media Preview
│   └── ZIP Export
│
└── Settings
    ├── Account
    ├── AI Preferences
    ├── Security
    ├── Storage
    └── Appearance
```

---

# 5. Navigation Model

Miralo AI uses a full-screen conversation layout with a ChatGPT-style sidebar or drawer.

## Main Navigation

```text
/app/home
/app/chat/:chatId
/app/recent
/app/pinned
/app/settings
```

## Private Navigation

```text
/private/unlock
/private/contacts
/private/add-person
/private/chat/:conversationId
/private/chat/:conversationId/media/:mediaId
/private/naughty
```

## Library Navigation

```text
/library/unlock
/library/home
/library/folder/:folderId
/library/file/:fileId
/library/add
/library/export
```

The private routes should be protected by session state. Library routes require a separate Library Vault session.

---

# 6. Authentication Flow

## Screen A01 — Welcome

### Purpose

Introduce the application without overwhelming the user.

### UI

- Miralo AI logo
- Miralo AI wordmark
- Short tagline
- Get Started button
- Sign In button

### Suggested Copy

```text
MIRALO AI

Your AI. Your Space.

A focused AI assistant with a discreet
private experience.
```

### Actions

- Get Started → Sign Up
- Sign In → Login

---

## Screen A02 — Sign Up

### Fields

- Username
- Email
- Password
- Confirm Password

### Actions

- Create Account
- Sign In

### Validation

- Required fields
- Valid email
- Password strength
- Matching passwords
- Username availability

### Backend

- Firebase Authentication
- User profile document in Firestore

---

## Screen A03 — Sign In

### Fields

- Email or username
- Password

### Actions

- Sign In
- Forgot Password
- Create Account

---

## Screen A04 — Forgot Password

### Fields

- Email

### Actions

- Send Reset Link
- Return to Login

---

# 7. Security Onboarding

## Screen S01 — Private Security Introduction

Explain the two independent security credentials.

```text
Set up your private access

Miralo AI uses two separate credentials.

Private Chat Secret
Protects private conversations and private media.

Library Vault PIN
Protects personal files, images, videos, and documents.
```

Actions:

- Set Up Private Chat Secret
- Set Up Library Vault PIN
- Continue

---

## Screen S02 — Create Private Chat Secret

### Secret Types

- 4-digit PIN
- 6-digit PIN
- Custom number
- Word
- Sentence

### Fields

- Secret type
- Secret value
- Confirm secret

### Requirements

- Never store raw secret
- Never display secret after saving
- Never send secret to AI provider
- Never place secret in chat history
- Rate-limit failed unlock attempts

### Security Design

Use a secure derivation or verifier strategy on the backend. The frontend must not contain a hardcoded secret comparison.

---

## Screen S03 — Create Library Vault PIN

### Fields

- Vault PIN
- Confirm PIN

### Optional

- Enable biometric unlock
- Auto-lock duration

### Rule

The Library Vault PIN must be separate from the Private Chat Secret.

---

## Screen S04 — Security Confirmation

```text
You're ready

Your private chats and Library are protected
by separate credentials.

You can unlock one without unlocking the other.
```

Action:

- Continue to Miralo AI

---

# 8. AI Assistant Experience

## Screen AI01 — AI Home / Empty State

This is the default application screen.

### Header

- Hamburger menu
- Centered title: Miralo AI
- New Chat icon
- Optional account avatar

### Main Content

- Small Miralo AI logo
- Welcome headline
- Minimal supporting text

### Suggested Copy

```text
How can I help you today?

Ask questions, learn something new,
write, plan, or solve a problem.
```

### Optional Prompt Suggestions

Keep them compact and limited:

- Explain a concept
- Help me write
- Study with me

Do not use large feature cards.

### Composer

```text
[ + ]  Ask MIRALO AI...                 [Send]
```

Optional:

- Voice input, only if implemented
- Model selector

Do not show:

- Web search
- Image generation
- Projects
- Plugins
- Scheduled tools
- Remote tools

---

## Screen AI02 — AI Conversation

### Header

- Sidebar/back button
- Conversation title
- Model selector
- More menu

### Message Area

Support:

- User messages
- AI messages
- Markdown
- Code blocks
- Tables
- Copy action
- Regenerate action
- Stop generation
- Feedback actions

### Composer

The composer remains fixed above the keyboard.

```text
[ + ]  Ask MIRALO AI...       [Mic] [Send]
```

### AI Message Actions

- Copy
- Regenerate
- Edit
- Delete
- Share
- Feedback

### User Message Actions

- Edit
- Copy
- Delete
- Retry

---

## Screen AI03 — AI Chat List

### Content

Each conversation row includes:

- Title
- Last message preview
- Timestamp
- More menu

### Actions

- Open
- Rename
- Pin
- Delete

### Empty State

```text
Your conversations will appear here.
```

---

## Screen AI04 — Pinned Chats

Shows pinned AI conversations.

### Actions

- Open
- Unpin
- Rename
- Delete

---

## Screen AI05 — Model Selector

The model selector is a compact sheet or popover.

### Possible Fields

- Model name
- Provider
- Context limit, if useful
- Default indicator

### Important

The mobile app should not contain provider API keys. The backend controls provider credentials and model routing.

---

# 9. Hidden Private Unlock System

## Core Requirement

The user must unlock private chats by typing their secret phrase or number into the **same normal AI message composer**.

There must be no permanent “Unlock Private Space” button on the AI home screen.

---

## Unlock Flow

```text
Normal AI Chat
      ↓
User types secret into normal composer
      ↓
App detects possible unlock attempt
      ↓
Secure verification
      ↓
Input is cleared
      ↓
Private contacts become available in sidebar
```

### Example

User types:

```text
blue moon forever
```

or:

```text
123456
```

### Valid Secret Behavior

- Do not send to AI
- Do not create a chat message
- Do not save in history
- Clear composer
- Establish private chat session
- Update sidebar availability
- Show subtle confirmation if desired

Suggested confirmation:

```text
Private chats unlocked
```

This should be a small toast or subtle status message, not a large screen.

---

## Invalid Secret Behavior

The input should not reveal that a private feature exists.

Recommended behavior:

- Treat it as a normal AI prompt, or
- Show a generic response/input error based on the product’s chosen security model

Do not show:

```text
Wrong private PIN
```

because that exposes the existence of the hidden feature.

A safer implementation can use a recognizable local command prefix internally, but the product requirement is that the user enters the secret through the normal composer.

---

# 10. Sidebar Behavior

## Sidebar Before Unlock

```text
MIRALO AI

+ New Chat

Recent Chats
Pinned Chats

────────────────

Settings
Account
```

Do not show:

- Private Space
- Secret Chats
- Naughty Mode
- Private Library
- Private contact names

---

## Sidebar After Private Chat Unlock

The sidebar expands naturally.

```text
MIRALO AI

+ New Chat

Recent Chats
Pinned Chats

Chats
  Person One
  Person Two
  Person Three
  + Add Person

Images
Library

────────────────

Settings
Account
```

The sidebar should not become a colorful private dashboard.

Private contacts should look like ordinary conversation entries:

- Avatar
- Name
- Last message preview, unless Hide Mode is enabled
- Timestamp
- Unread count, unless Hide Mode is enabled

---

# 11. Unified Conversation System

## Critical Design Rule

AI conversations and private person conversations must use the same core chat UI system.

Use shared components:

- ConversationScaffold
- ConversationHeader
- MessageList
- MessageRow
- MessageBubble
- Composer
- AttachmentSheet
- MessageActions
- MediaViewer
- LoadingIndicator

Only the conversation context changes.

---

## AI Conversation Context

Header:

```text
Miralo AI
GPT-style model
```

Composer:

```text
Ask MIRALO AI...
```

---

## Person Conversation Context

Header:

```text
Person Name
Online
```

Composer:

```text
Message...
```

The following must remain consistent:

- Background
- Typography
- Spacing
- Message alignment
- Bubble radius
- Composer shape
- Send button
- Animation
- Context menu style
- Media viewer

Do not create a separate WhatsApp-style private UI.

---

# 12. Private Communication

## Screen P01 — Private Contacts

This screen is accessible only after Private Chat Secret unlock.

### Header

- Back/sidebar button
- Private contacts title
- Search, optional
- Add Person action

### Contact Rows

- Avatar
- Display name
- Last message
- Timestamp
- Unread indicator
- Pin indicator

### Empty State

```text
Your private conversations will appear here.
```

Action:

- Add Person

---

## Screen P02 — Add Person

### Possible Methods

- Search by username
- Enter invite code
- Scan invite QR
- Share invite link

### Fields

```text
Search username or enter invite code
```

### Actions

- Send Request
- Connect
- Cancel

---

## Screen P03 — Contact Request

### Content

- Person avatar
- Username
- Basic profile information
- Request status

### Actions

- Accept
- Decline
- Block
- Report

Only implement the actions required for the MVP.

---

## Screen P04 — Private Conversation

### Header

- Back/sidebar
- Contact avatar
- Contact name
- Optional online status
- More menu

### Supported Messages

- Text
- Images
- GIFs
- Emoji reactions

### Composer

```text
[ + ]  Message...       [GIF] [Emoji] [Send]
```

### More Menu

- Search in conversation
- View media
- Pin conversation
- Mute
- Lock private session
- Quick Exit
- Clear chat
- Delete conversation

---

# 13. Private Media Messaging

## Screen P05 — Attachment Sheet

Opened by tapping the plus button in a private conversation.

### Options

- Take Photo
- Choose from Gallery
- Send File
- Send GIF
- Cancel

The sheet should be a compact, native-style bottom sheet.

---

## Screen P06 — Camera Capture

### UI

- Full-screen camera preview
- Back button
- Flash control
- Camera flip
- Capture button
- Gallery thumbnail

### After Capture

Preview actions:

- Retake
- Use Photo
- Cancel

After selecting Use Photo:

- Optional caption
- Send
- Cancel

---

## Screen P07 — Gallery Picker

### Behavior

- Open system image picker
- Select one or multiple images
- Preview selected images
- Add caption
- Send

The app must not request broad gallery access if the platform picker can provide limited selection access.

---

## Screen P08 — GIF Picker

### UI

- Search field
- Trending GIFs
- Category tabs
- Grid layout
- Loading skeleton
- Preview

### Actions

- Select GIF
- Send
- Cancel

Use a backend-proxied GIPHY or Tenor integration where appropriate.

Do not send private chat content to the GIF provider.

---

## Screen P09 — Media Viewer

### Actions

- Zoom
- Close
- Download
- Move to Library
- Share
- Delete

### Default Rule

Private media is viewed inside the app and is not automatically saved to the phone gallery.

---

# 14. Message Reactions

Long-pressing a message opens a compact reaction/action popover.

## Reactions

- 👍
- ❤️
- 😂
- 😮
- 😢
- 👏
- 🔥

## Actions

- Reply, optional
- Copy
- Save
- Delete
- More

The reaction bar should be compact, subtle, and consistent with the overall design.

---

# 15. Private Images Section

## Screen P10 — Images

This section contains images belonging to Miralo’s private communication system.

It must not automatically show the entire device gallery.

### Filters

- All
- Sent
- Received
- Saved

### Layout

- Premium 3-column grid
- Rounded image thumbnails
- Loading placeholders
- Empty state

### Actions

- Open
- Download
- Move to Library
- Share
- Delete

### Empty State

```text
Images shared in your private conversations
will appear here.
```

---

# 16. Private Library

The Library is independently protected and must not unlock automatically with Private Chats.

## Screen L01 — Library Lock

### Content

```text
Library Vault

Enter your Library PIN
```

### Actions

- Unlock
- Biometric Unlock, if enabled
- Cancel
- Recovery information

The Library Vault PIN is separate from the Private Chat Secret.

---

## Screen L02 — Library Home

### Header

- Back/sidebar
- Library title
- Search
- Add
- Select

### Main Sections

- Folders
- Recent files
- Images
- Videos
- Documents
- Other files

### Suggested Layout

```text
Library

[ Search files... ]

Folders
  Personal
  Documents
  Media

Recent Files
  image.jpg
  notes.pdf
  video.mp4
```

---

## Screen L03 — Add to Library

### Options

- Choose Images
- Choose Videos
- Choose Documents
- Choose Files
- Create Folder

No selected file should be sent to the AI automatically.

---

## Screen L04 — Folder View

### Features

- Folder title
- Search
- Sort
- Add file
- Create subfolder
- Select multiple

### Sort Options

- Name
- Date added
- File type
- Size

---

## Screen L05 — File Preview

Support previews for:

- Images
- Videos
- PDFs
- Text documents
- Supported file formats

### Actions

- Rename
- Move
- Share
- Download/export
- Delete

---

## Screen L06 — Create Folder

### Field

- Folder name

### Actions

- Create
- Cancel

---

## Screen L07 — Multi-Select and Export

### Actions

- Move
- Delete
- Export ZIP
- Cancel

---

## Screen L08 — ZIP Export

### Fields

- ZIP filename
- Password protection toggle
- ZIP password
- Confirm password

### Warning

```text
Keep your ZIP password safe.
It cannot be recovered if forgotten.
```

### Actions

- Create ZIP
- Cancel

Use a real encryption-capable ZIP implementation. Base64 is not encryption.

---

# 17. Naughty Mode

Naughty Mode is an optional feature accessible only after Private Chat Secret unlock.

It must not be visible on the normal AI home screen.

## Access Options

- Private conversation more menu
- Private-only tools menu
- `/naughty` local command

## Screen N01 — Naughty Mode Introduction

```text
Naughty Mode

Adults only.
Everything is optional and consensual.
You can skip any prompt at any time.
```

Actions:

- Continue
- Cancel

---

## Screen N02 — Naughty Mode Preferences

### Categories

- Sweet
- Romantic
- Flirty
- Sensual
- Sexual — Mild
- Couple’s Fantasy
- Random Mix

### Intensity

- Sweet
- Playful
- Spicy
- Mild Sexual

---

## Screen N03 — Dare Card

### UI

A simple dark or light elevated card.

```text
Your next dare

Give your partner a playful compliment
and hold eye contact for ten seconds.

[Done] [Skip] [New Dare]
```

### Rules

- Adults only
- Consensual
- Optional
- Skippable
- No coercion
- No dangerous tasks
- No public exposure
- No forced intimate media
- No minors
- No automatic camera/gallery access

For MVP, use a curated local dare database instead of unrestricted AI generation.

---

# 18. Emergency and Quick Exit System

Private mode must include two local commands and a UI emergency action.

## Command 1 — `/clear`

### Purpose

Clear the currently open private chat.

### Behavior

1. Detect command locally.
2. Do not send it to the private contact.
3. Do not send it to AI.
4. Do not store it as a message.
5. Clear the current private chat according to the configured deletion policy.
6. Return to an empty conversation or the private chat list.
7. Show a subtle confirmation if appropriate.

Suggested confirmation:

```text
Chat cleared
```

### Deletion Policy

The implementation must clearly define whether `/clear` means:

- Clear local visible messages
- Delete locally cached messages
- Request server deletion
- Delete media attachments

Do not claim that a local clear deletes copies stored on another participant’s device.

---

## Command 2 — `/urgent`

### Purpose

Immediately leave private mode and return to the normal AI experience.

### Behavior

1. Detect `/urgent` locally.
2. Do not send the command.
3. Hide private navigation entries.
4. Lock the private chat session.
5. Find the last used normal AI conversation.
6. Open that AI conversation.
7. If no AI conversation exists, open a new empty AI chat with a harmless prefilled prompt.

### Routing Logic

```text
/urgent
  ↓
Lock private chat session
  ↓
Read lastNormalAiChatId
  ├── Exists → Open last normal AI chat
  └── Missing → Open new empty AI chat
```

---

## No Previous AI Chat

If no normal AI conversation exists, open a blank AI chat with the composer prefilled with:

```text
What can I help you with today?
```

The prompt must not be automatically submitted.

It should appear in the composer as editable text.

---

## Emergency Button

The UI emergency action should be located inside the private conversation’s more menu.

Recommended neutral label:

- Quick Exit
- Return to AI
- Switch to AI Chat

Avoid a large red button or dramatic emergency screen.

### Button Behavior

- Lock private session
- Hide private content
- Open last normal AI chat
- Otherwise open empty AI chat with harmless prefilled prompt
- Use a short 150–250 ms transition
- Do not show “Emergency Mode Activated”
- Do not send any message
- Do not reveal private content on the destination screen

---

# 19. Slash Command System

## Supported Commands

```text
/clear
```

Clears the current private chat.

```text
/urgent
```

Returns to the last normal AI chat.

```text
/lock
```

Locks private chat access and hides private navigation.

```text
/help
```

Shows available local commands.

## Processing

```text
Composer Input
    ↓
Local Command Parser
    ↓
Recognized Command?
  ├── Yes → Execute locally
  └── No  → Send as normal message
```

Commands must be processed before network transmission.

Never send commands to:

- AI providers
- Private contacts
- Analytics logs as raw sensitive content

---

# 20. Hide Mode

Hide Mode makes the visible app more generic when enabled.

## Hide These Items

- Username
- Display name
- Profile avatar
- Private chat labels
- Private message previews
- Romantic indicators
- Naughty Mode label
- Unread private counts
- Private notification content
- Private workspace status

## Normal Sidebar

```text
Account
Dawn
Free Plan
```

## Hide Mode Sidebar

```text
Account
Account
Free Plan
```

Or use:

```text
General AI
Free Plan
```

## Private Chat Preview

Normal:

```text
Sarah
Are you free tonight?
```

Hide Mode:

```text
Conversation
No preview
```

## Notification Behavior

Normal:

```text
Sarah: Hey, are you free?
```

Hide Mode:

```text
New message
```

Hide Mode should not show a large banner announcing that it is active.

---

# 21. Settings

## Screen SET01 — Settings Home

### Account

- Profile
- Username
- Email
- Password
- Sign out
- Delete account

### AI

- Default model
- Provider preference
- Response preferences
- Chat history
- Data controls

### Privacy and Security

- Change Private Chat Secret
- Change Library Vault PIN
- Hide Mode
- Auto-lock timeout
- Biometric unlock
- Lock Private Chats
- Lock Library
- Clear private cache
- Active sessions

### Storage

- Storage usage
- Download preferences
- Clear cached media
- Export data

### Appearance

- Light
- Dark
- System
- Accent preference
- Haptic feedback

### Support

- Help
- Privacy Policy
- Terms
- About
- Contact Support

---

## Screen SET02 — Account Settings

- Profile avatar
- Username
- Email
- Change password
- Sign out
- Delete account

---

## Screen SET03 — AI Settings

- Default model
- Provider/model availability
- Response style
- Chat history preference
- Clear AI history

---

## Screen SET04 — Private Security Settings

### Private Chat Security

- Change Private Chat Secret
- Auto-lock timeout
- Biometric unlock
- Lock now

### Library Security

- Change Library Vault PIN
- Auto-lock timeout
- Biometric unlock
- Lock now

These settings must remain independent.

---

## Screen SET05 — Appearance Settings

### Theme

- Light
- Dark
- System Default

The app should provide equal design quality in both modes.

---

# 22. Light Theme

## Colors

```text
Background:        #F7F7F8
Primary Surface:   #FFFFFF
Secondary Surface: #F1F1F3
Elevated Surface:  #FFFFFF
Primary Text:      #171717
Secondary Text:    #6B6B73
Muted Text:        #96969F
Border:            #E4E4E7
Divider:           #EEEEF0
Accent:            #3B82F6
Destructive:       #D92D20
Success:           #218A5A
```

## Style

- White and soft-gray surfaces
- Near-black typography
- Subtle shadows
- Thin borders
- Restrained blue accent
- No excessive gradients
- No glass-heavy UI

---

# 23. Dark Theme

## Colors

```text
Background:        #000000
Primary Surface:   #111111
Secondary Surface: #171717
Elevated Surface:  #222222
Input Background:  #242424
Pressed Surface:   #2B2B2B
Primary Text:      #F5F5F5
Secondary Text:    #B5B5B5
Muted Text:        #777777
Border:            #2A2A2A
Divider:           #202020
Accent:            #7EA7FF
Destructive:       #FF6B6B
Success:           #7DD3A8
```

## Style

- Near-black background
- Charcoal surfaces
- White text
- Soft blue accent
- Minimal shadows
- No neon cyberpunk treatment
- No bright colorful cards

---

# 24. Typography and Spacing

## Typography

Use:

- SF Pro-style system font on iOS
- Inter or system sans-serif fallback on Android

### Sizes

```text
Display heading: 28–32 px
Screen title:     20–24 px
Chat title:       16–18 px
Body:             15–17 px
Secondary:        13–14 px
Caption:          11–12 px
```

## Spacing

Use an 8-point spacing system:

```text
4 px   Micro spacing
8 px   Small spacing
12 px  Compact spacing
16 px  Standard spacing
20 px  Section spacing
24 px  Large spacing
32 px  Major spacing
```

## Touch Targets

- Minimum 44x44 logical pixels
- Clear pressed states
- Comfortable keyboard interaction
- Safe-area support

---

# 25. Flutter Technical Architecture

## Recommended Stack

- Flutter
- Dart
- Material 3 customized to resemble iOS/ChatGPT
- Riverpod, Bloc, or Provider
- GoRouter
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Backend AI API
- WebSocket or Firebase listeners for private messaging
- Secure local storage
- Camera plugin
- File picker
- Image picker
- GIF provider integration

---

## Suggested Folder Structure

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── light_theme.dart
│   │   └── dark_theme.dart
│   └── constants/
│
├── core/
│   ├── errors/
│   ├── network/
│   ├── security/
│   ├── storage/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── ai_chat/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── private_chat/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── private_media/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── library/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── naughty_mode/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── settings/
│   │   ├── data/
│   │   └── presentation/
│   │
│   └── shell/
│       ├── app_shell.dart
│       ├── sidebar.dart
│       └── conversation_scaffold.dart
│
└── shared/
    ├── models/
    ├── widgets/
    └── services/
```

---

# 26. Reusable Flutter Components

Create reusable components instead of duplicating UI.

```text
AppShell
AppSidebar
SidebarSection
ConversationScaffold
ConversationHeader
MessageList
MessageRow
MessageBubble
MessageActions
MessageComposer
ComposerActionButton
ModelSelector
SuggestionChip
PrivateUnlockHandler
PrivateSessionGuard
AttachmentSheet
CameraCaptureScreen
GalleryPicker
GifPickerSheet
ReactionPicker
MediaViewer
ImagesGrid
LibraryFileRow
LibraryFolderTile
VaultPinScreen
ZipExportSheet
NaughtyModeSheet
QuickExitAction
HideModeController
SettingsSection
SettingsRow
ConfirmationDialog
ToastMessage
```

---

# 27. Backend Architecture

## AI Request Flow

```text
Flutter App
    ↓
Miralo Backend
    ↓
Authentication Validation
    ↓
Rate Limiting / Usage Checks
    ↓
Configured AI Provider
    ↓
AI Response Stream
    ↓
Flutter App
```

## Backend Responsibilities

- Validate Firebase authentication tokens
- Manage AI provider credentials
- Route requests to selected models
- Enforce usage limits
- Stream responses
- Handle provider failures
- Prevent secret leakage
- Log only safe operational metadata
- Apply abuse protection

API keys must never be embedded in Flutter source code.

---

# 28. Data Model

## User

```text
users/{userId}
  username
  email
  displayName
  avatarUrl
  createdAt
  settings
  hideModeEnabled
  defaultModel
```

Do not store raw private secrets in the user document.

---

## Private Security Metadata

```text
users/{userId}/security/privateChat
  verifier
  salt
  version
  updatedAt
  autoLockDuration
  biometricEnabled
```

```text
users/{userId}/security/library
  verifier
  salt
  version
  updatedAt
  autoLockDuration
  biometricEnabled
```

Use a secure server-side strategy. Do not treat a client-side hash comparison as sufficient security.

---

## AI Conversation

```text
aiConversations/{conversationId}
  ownerId
  title
  model
  provider
  createdAt
  updatedAt
  pinned
```

## AI Message

```text
aiConversations/{conversationId}/messages/{messageId}
  role
  content
  createdAt
  status
  metadata
```

---

## Private Conversation

```text
privateConversations/{conversationId}
  participantIds
  createdAt
  updatedAt
  lastMessageAt
  pinnedBy
  mutedBy
```

## Private Message

```text
privateConversations/{conversationId}/messages/{messageId}
  senderId
  type
  text
  mediaId
  createdAt
  editedAt
  deletedFor
  reactions
  deliveryStatus
```

Message types:

```text
text
image
gif
file
system
```

---

## Private Media

```text
privateMedia/{mediaId}
  ownerId
  conversationId
  senderId
  storagePath
  mimeType
  size
  width
  height
  createdAt
  libraryCopyId
```

Use protected storage paths and strict access rules.

---

## Library File

```text
libraryFiles/{fileId}
  ownerId
  folderId
  name
  type
  mimeType
  storagePath
  size
  createdAt
  updatedAt
  source
```

Possible source values:

```text
device
privateChat
import
export
```

---

# 29. Privacy and Security Requirements

## Secret Handling

- Never store raw secrets
- Never send secrets to AI providers
- Never log secrets
- Never store secrets in chat messages
- Never hardcode secrets in Flutter
- Rate-limit attempts
- Add lockout protection where appropriate
- Clear sensitive input from memory where practical

## Private Media

- Use protected storage
- Apply server-side authorization
- Do not expose public download URLs permanently
- Use short-lived signed URLs where appropriate
- Do not auto-save media to the gallery
- Do not send private media to AI automatically
- Do not analyze private media without explicit opt-in

## Realistic Privacy Statement

The app can reduce accidental exposure, but cannot guarantee protection against:

- Screenshots
- Screen recording
- Another device photographing the screen
- Malware on the device
- Rooted/jailbroken devices
- Compromised accounts
- Recipient-controlled copies

---

# 30. Emergency State Management

Maintain:

```text
lastNormalAiChatId
privateChatSessionUnlocked
librarySessionUnlocked
lastPrivateConversationId
lastActiveConversationType
```

## Quick Exit State Transition

```text
privateChatSessionUnlocked = false
librarySessionUnlocked = unchanged or locked according to policy
activeConversationType = ai
activeConversationId = lastNormalAiChatId
```

If no `lastNormalAiChatId` exists:

```text
activeConversationType = ai
activeConversationId = newEmptyConversation
composerDraft = "What can I help you with today?"
```

The prefilled prompt must not be automatically submitted.

---

# 31. Error and Empty States

Every major screen needs:

## Loading State

- Skeleton rows
- Subtle shimmer
- No excessive animation

## Error State

- Clear explanation
- Retry button
- No technical stack traces shown to users

## Empty State

- Short explanation
- One useful action
- No giant illustrations

### Examples

AI chats:

> Your conversations will appear here.

Private chats:

> Your private conversations will appear here.

Library:

> Your private files will appear here.

Images:

> Images shared in your private conversations will appear here.

---

# 32. Animation System

Use short, subtle animations.

### Recommended Durations

```text
Micro interaction: 100–150 ms
Button feedback:   120–180 ms
Sheet transition:  220–320 ms
Screen transition: 180–250 ms
Image transition:  220–300 ms
```

### Required Animations

- Sidebar slide
- Bottom-sheet spring
- Message appearance
- Send button feedback
- Loading shimmer
- Image preview transition
- Secret verification fade
- Quick Exit transition
- Modal presentation
- Haptic feedback where supported

Avoid:

- Confetti
- Neon effects
- Excessive bouncing
- Long splash animations
- Dramatic private-mode transformations

---

# 33. MVP Release Scope

## Release 1 — Required

### Authentication

- Welcome
- Sign Up
- Sign In
- Forgot Password
- Firebase integration

### AI

- New AI chat
- AI conversation
- Text prompt/response
- Streaming
- Chat history
- Rename
- Delete
- Pin
- Model selection

### Private Unlock

- Secret setup
- Secret verification through AI composer
- Private session state
- Sidebar contact access

### Private Chat

- Contact connection
- Text messages
- Real-time updates
- Image sending
- Camera
- Gallery
- In-app media viewer
- Basic reactions

### Library

- Independent Library PIN
- Add files
- Folders
- Preview
- Rename
- Move
- Delete
- Save private media to Library

### Privacy

- Hide Mode
- Lock private session
- Quick Exit
- `/clear`
- `/urgent`

---

## Release 1.1

- GIF integration
- Search conversations
- Message delivery states
- Read states
- ZIP export
- Password-protected ZIP
- Biometric unlock
- Advanced notification privacy
- Friend request improvements

---

## Release 2

- Stronger end-to-end encryption
- Secure multi-device key management
- Voice calls
- Video calls
- Advanced private sharing controls
- Expanded Naughty Mode personalization

---

# 34. Final User Journeys

## Journey A — Normal AI Use

```text
Open app
  ↓
Sign in
  ↓
AI Home
  ↓
Type question
  ↓
Backend calls AI provider
  ↓
AI response streams
  ↓
Conversation saved
```

---

## Journey B — Unlock Private Chats

```text
AI Home
  ↓
Type secret phrase into normal composer
  ↓
Local/backend verification
  ↓
Input cleared
  ↓
Private contacts appear in sidebar
  ↓
Select person
  ↓
Same unified chat UI opens
```

---

## Journey C — Send Private Image

```text
Private conversation
  ↓
Tap plus
  ↓
Camera or Gallery
  ↓
Preview image
  ↓
Optional caption
  ↓
Send
  ↓
Image appears inside chat
  ↓
No automatic device-gallery save
```

---

## Journey D — Save Media to Library

```text
Private image
  ↓
Open media viewer
  ↓
Move to Library
  ↓
Library authorization check
  ↓
Library PIN if locked
  ↓
Select folder
  ↓
File saved to protected Library
```

---

## Journey E — Quick Exit

```text
Private conversation
  ↓
Tap Quick Exit
  or type /urgent
  ↓
Private session locked
  ↓
Last normal AI chat opens
  ↓
If none exists, empty AI chat opens
  ↓
Composer contains:
"What can I help you with today?"
```

---

## Journey F — Clear Private Chat

```text
Private conversation
  ↓
Type /clear
  ↓
Local command parser
  ↓
Current private chat is cleared
  ↓
No message is sent
  ↓
User returns to empty chat/list
```

---

# 35. Final Design Rule

The most important requirement is:

> **Miralo AI must always look like Miralo AI.**

Before private unlock:

- Normal ChatGPT-style AI interface

After private unlock:

- The same AI interface
- The same colors
- The same spacing
- The same composer
- The same message components
- Additional people become selectable from the sidebar

The private feature is a hidden capability, not a separate visual product.

The Library is independently protected. The emergency action returns to a normal AI conversation. The app remains minimal, premium, discreet, and focused.

---

# Final Product Summary

Miralo AI is a premium AI API wrapper with a unified ChatGPT-style interface. Users can chat with external AI models, manage conversations, and choose models through a secure backend.

By entering a private secret phrase into the ordinary AI message composer, users can discreetly access private person-to-person conversations from the sidebar. Those conversations use the same Miralo AI chat interface and support text, images, camera capture, GIFs, and reactions.

A separate Library Vault PIN protects personal files, images, videos, and documents. Private media does not automatically save to the device gallery or get sent to the AI.

Quick Exit and `/urgent` return users to the last normal AI chat, while `/clear` clears the current private chat. Hide Mode removes identifying information from the visible interface and notifications.

**Miralo AI is simple in appearance, powerful in capability, and privacy-oriented by design.**
