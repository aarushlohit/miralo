# MIRALO AI — APP FEATURES

## 1. Product Overview

MIRALO AI is a premium, privacy-focused AI assistant and private communication application.

The app combines:

- AI-powered text conversations
- Private person-to-person messaging
- Private media sharing
- Protected personal file storage
- Optional private Naughty Mode
- Emergency Quick Exit
- Hide Mode
- Light and dark themes

The app must maintain a single, clean ChatGPT-like interface without looking like a social media or dating application.

## 2. Core Product Principles

- Premium Apple-style interface
- Minimal and distraction-free design
- ChatGPT-inspired interaction model
- One unified chat interface
- No unnecessary dashboards
- No colorful private-chat redesign
- No gradients or neon-heavy styling
- Privacy-first architecture
- Private features must remain discreet
- Private content must never be sent to the AI automatically
- Separate security credentials for private chat and Library Vault

## 3. AI Assistant Features

### 3.1 AI Chat

- Create a new AI conversation
- Continue previous conversations
- Send text prompts
- Receive AI-generated responses
- Stream AI responses
- Stop response generation
- Regenerate the latest response
- Copy response text
- Share response
- Delete individual messages
- Delete complete conversations
- Rename conversations
- Pin conversations
- Archive conversations
- Search conversations locally
- Markdown rendering
- Code-block rendering
- Syntax highlighting
- Code copy button
- Basic tables and lists
- Loading and error states
- Retry failed responses

### 3.2 AI Composer

- Multiline text input
- Send button
- Stop-generation button
- Auto-expanding input field
- Keyboard-aware layout
- Clear input after sending
- Secure command interception

Supported commands:

- `/clear` — Clears the current private conversation
- `/urgent` — Activates Emergency Quick Exit
- `/lock` — Locks private content
- `/help` — Displays supported commands

## 4. AI Provider Integration

- AI requests pass through a secure backend
- API keys remain server-side
- Provider selection is handled by the backend
- Request rate limiting
- Usage monitoring
- Error handling
- Timeout handling
- Retry logic
- Model configuration
- Token and request limits
- Abuse prevention

The initial version excludes web search, browsing, projects, plugins, scheduled tasks, remote tools, image generation, and autonomous agents.

## 5. Authentication Features

### Account Creation

- Email and password registration
- Email verification
- Password validation
- Terms and privacy consent
- Account creation error handling

### Login

- Email and password login
- Remember session
- Secure session persistence
- Logout
- Invalid credentials handling
- Rate limiting after repeated failures

### Account Recovery

- Forgot password
- Password reset email
- Password change from settings
- Logout from all devices

## 6. Security Onboarding

Users can configure:

- Private Chat Secret/PIN
- Separate Library Vault PIN
- Biometric unlock, if supported
- Hide Mode
- Auto-lock duration
- Privacy preferences

The credentials must remain separate:

| Credential | Unlocks |
|---|---|
| Private Chat Secret/PIN | Private people, private chats, private media, reactions, GIFs, Naughty Mode |
| Library Vault PIN | Protected Library files and folders |

Unlocking private chat must never unlock the Library automatically.

## 7. Private Chat Unlock

The user unlocks private features through the normal AI composer.

### Unlock Flow

1. User opens a normal AI chat.
2. User enters the configured secret phrase, number, or PIN.
3. The application intercepts the input locally.
4. The input is not sent to the AI.
5. The input is not saved in chat history.
6. The composer is cleared.
7. Private people and conversations become available.

### Security Requirements

- Secret must never be sent to the AI provider
- Secret must never appear in conversation history
- Secret must not be stored in plaintext
- Secret must not be logged
- Secret must not appear in analytics
- Secret must not be hardcoded
- Failed attempts must be rate-limited
- Unlock state must expire after inactivity

## 8. Private Sidebar Features

After successful private unlock:

- Private people list
- Private conversations list
- Recent private chats
- Unread message indicator
- Search private contacts
- Add a private contact
- Remove a private contact
- Block a contact
- Mute a conversation
- Archive a private conversation
- Delete a private conversation
- Hide private previews
- Hide private unread counts

Hide Mode can replace private names with neutral labels or hide private sections until unlock.

## 9. Unified Private Chat Interface

Private chats must use the same visual system as AI chats.

Shared components:

- Same app bar
- Same message bubble system
- Same typography
- Same spacing
- Same composer
- Same navigation drawer
- Same themes
- Same context menus
- Same animation language

### Private Chat Features

- One-to-one messaging
- Text messages
- Image messages
- Camera capture
- Gallery/file picker
- GIF sharing
- Emoji reactions
- Message reply
- Message copy
- Message delete
- Message timestamps
- Read status, if enabled
- Typing indicator
- Online/offline status, if enabled
- Mute notifications
- Block contact
- Report contact
- Delete conversation

Private messages must use neutral gray and charcoal styling rather than a separate colorful or romantic theme.

## 10. Private Media Features

### Image Sharing

Supported sources:

- Camera
- Device gallery
- File picker
- App-owned private media section

Features:

- Image preview before sending
- Image compression
- Upload progress
- Cancel upload
- Retry failed upload
- Full-screen image viewer
- Zoom and pan
- Image download
- Move image to Library
- Delete image

### Privacy Rules

- Private images must not automatically save to the phone gallery
- Private images must not automatically be sent to AI
- Private images must not automatically be analyzed by AI
- Explicit Download saves an image to the device
- Move to Library stores the image in the protected app vault
- Cached private images must be securely protected
- Temporary files must be deleted according to retention rules

### Private Images Section

- View private images
- Filter by conversation
- Sort by date
- Full-screen preview
- Download
- Move to Library
- Delete
- Multi-select
- Bulk delete

The Images section must display only app-owned private media and must not mirror the entire device gallery.

## 11. GIF and Reaction Features

### GIF Sharing

- Search GIFs
- Preview GIFs
- Send GIFs
- Recently used GIFs
- Loading and error states
- Content moderation
- Privacy-safe GIF provider integration

### Emoji Reactions

- Add reaction
- Remove reaction
- View reaction count
- View users who reacted
- Multiple reaction types
- Real-time synchronization

## 12. Library Vault

The Library is an independently protected storage area.

### Vault Unlock

- Separate Library PIN
- Optional biometric unlock
- Auto-lock after inactivity
- Lock when app backgrounds
- Failed-attempt rate limiting

### Supported Files

- Images
- Videos
- PDFs
- Text files
- Documents
- Audio files
- ZIP files
- Other supported file types

### Library Features

- Add files
- Import from device
- Create folders
- Rename files
- Rename folders
- Move files
- Move folders
- Delete files
- Delete folders
- Search files
- Sort by name
- Sort by date
- Sort by file type
- Grid view
- List view
- File preview
- Full-screen image viewer
- Video playback
- PDF preview
- File metadata
- Multi-select
- Bulk delete
- Export files
- Export folders
- Create ZIP archive
- Optional password-protected ZIP export

### Library Privacy

- Library content is hidden until Vault unlock
- File names must not leak through notifications
- Thumbnails must be protected
- Temporary previews must be securely managed
- Files must not be uploaded to AI automatically
- Files must not be publicly accessible
- Access must be validated server-side for cloud storage

## 13. Naughty Mode

Naughty Mode is an optional private-only feature for adults.

Requirements:

- Available only after Private Chat unlock
- Must not appear on the normal AI home screen
- Must be consensual
- Must be optional and skippable
- Must not require intimate media
- Must not involve minors or coercion
- Must provide a clear exit option

Possible features:

- Mild romantic dares
- Flirty prompts
- Couples questions
- Playful challenges
- Consent-based roleplay prompts
- Random dare generator
- Difficulty levels
- Skip button
- End session button
- Private session history control

A curated prompt database is recommended for the MVP.

## 14. Emergency Quick Exit

Emergency Quick Exit allows users to leave private content quickly and discreetly.

### Emergency Behavior

1. Private content is removed from the visible screen.
2. Private session is locked.
3. Private previews are hidden.
4. The app transitions to the last used normal AI conversation.
5. If no AI conversation exists, a new empty AI chat opens.
6. The composer is prefilled with:

> What can I help you with today?

The message must not be automatically submitted.

### Animation

- Subtle fade or slide
- Approximately 150–250 milliseconds
- No loud alert
- No emergency banner

### `/urgent` Command

The command must be intercepted locally, not sent to AI, not saved in history, and must trigger Quick Exit.

## 15. Hide Mode

Features:

- Hide private conversation names
- Hide private avatars
- Hide private message previews
- Hide private unread counts
- Hide private media thumbnails
- Hide Naughty Mode label
- Hide romantic indicators
- Hide private notifications
- Replace private contact names with neutral labels
- Hide private sections until unlock

Do not show an obvious “Hide Mode Active” banner.

## 16. Notifications

### AI Notifications

- AI response completed
- AI request failed
- Account security alert

### Private Notifications

When Hide Mode is disabled:

- New private message
- Sender name
- Neutral message preview
- Attachment notification

When Hide Mode is enabled:

- Generic notification
- No sender name
- No message preview
- No private media thumbnail

Example:

> You have a new message.

## 17. Settings

### Account

- Profile information
- Email
- Change password
- Logout
- Delete account
- Active sessions
- Logout from all devices

### Appearance

- System theme
- Light mode
- Dark mode
- Text size preference

### Privacy

- Private Chat Secret/PIN management
- Library Vault PIN management
- Biometric unlock
- Auto-lock duration
- Hide Mode
- Notification privacy
- Clear cached private media
- Data deletion controls

### AI Settings

- Default model
- Response style
- Conversation history setting
- Clear all AI conversations
- AI usage information

### Private Chat Settings

- Contact management
- Message retention
- Read receipts
- Typing indicator
- Media auto-download settings
- GIF provider settings
- Blocked contacts
- Private notification behavior

### Library Settings

- Vault lock duration
- Biometric unlock
- Storage usage
- Clear temporary previews
- Export settings
- Delete all Library content

## 18. Theme Features

### Dark Mode

- Deep charcoal background
- Near-black navigation surfaces
- Neutral gray message bubbles
- Soft-white primary text
- Muted-gray secondary text
- Subtle borders
- Minimal shadows
- No neon accents

### Light Mode

- White or soft-gray background
- Light navigation surfaces
- Dark text
- Soft-gray message bubbles
- Subtle borders
- Clean contrast
- No excessive color usage

Both themes must use the same layout and components.

## 19. Accessibility Features

- Screen-reader labels
- Semantic buttons
- Minimum 44 × 44 touch targets
- Dynamic text scaling
- Sufficient contrast
- Keyboard navigation where applicable
- Reduced motion support
- Clear focus states
- Haptic feedback settings
- Accessible error messages
- Accessible media controls

## 20. Offline and Network Handling

- Display cached AI conversation history
- Display offline state
- Preserve unsent composer text
- Retry pending requests
- Handle reconnecting state
- Handle expired authentication
- Handle server unavailability

Private message delivery states:

- Sending
- Sent
- Delivered
- Read
- Failed

## 21. Security and Privacy Requirements

Mandatory requirements:

- HTTPS/TLS
- Secure authentication tokens
- Secure token storage
- Server-side authorization
- Database access rules
- Encrypted private media storage
- Access-controlled media URLs
- Expiring download URLs
- No API keys in the mobile app
- No plaintext secrets
- No secret logging
- No sensitive analytics
- Rate limiting
- Brute-force protection
- Session expiration
- Device logout support
- Secure deletion policy
- Input validation
- File type validation
- File size limits
- Malware scanning where applicable

The app cannot fully prevent screenshots, screen recording, recipient copying, device compromise, or camera capture by another device.

## 22. Analytics Restrictions

Do not collect:

- Private message content
- Private image content
- Private contact names
- Private Chat Secret/PIN
- Library Vault PIN
- Naughty Mode content
- Protected Library file names
- Private notification text

Allowed anonymous analytics may include:

- App crashes
- Screen performance
- API latency
- General feature usage counts
- Error categories
- App version
- Device compatibility data

## 23. MVP Feature Priority

### Phase 1 — Essential MVP

- Account registration and login
- AI chat
- AI conversation history
- Streaming responses
- Light/dark themes
- Secret unlock through AI composer
- Private contact list
- One-to-one private text chat
- Private Chat Secret/PIN
- Separate Library Vault PIN
- Basic Library file import
- Emergency Quick Exit
- Hide Mode
- Secure backend API

### Phase 2 — Private Communication

- Image sharing
- Camera capture
- GIF sharing
- Emoji reactions
- Message deletion
- Read receipts
- Typing indicators
- Private image viewer
- Move media to Library

### Phase 3 — Advanced Library

- Video playback
- PDF preview
- Folder management
- ZIP export
- Password-protected ZIP
- Multi-select operations
- Advanced search and filtering

### Phase 4 — Optional Features

- Naughty Mode
- Biometric unlock
- Message editing
- Voice messages
- Video calls
- Multi-device synchronization
- Advanced privacy controls

## 24. Explicitly Excluded Features

The first release must not include:

- Web browsing
- Web search
- Projects
- Plugins
- Scheduled tasks
- Image generation
- Public social feed
- Dating-style profiles
- Public user discovery
- Public/private follower system
- Colorful romantic chat interface
- Automatic private-media AI analysis
- Automatic gallery synchronization
- Hardcoded secrets
- Plaintext private media storage
- Unrestricted adult content generation
- Anonymous public file sharing

## 25. Primary User Experience

### Normal AI Flow

1. Open app.
2. View normal AI conversation.
3. Type a prompt.
4. Receive AI response.
5. Continue or create another conversation.

### Private Chat Flow

1. Open normal AI composer.
2. Enter private secret.
3. Secret is intercepted locally.
4. Private sidebar becomes available.
5. Select a person.
6. Chat using the same interface.
7. Send text, images, GIFs, or reactions.
8. Lock or exit private mode when finished.

### Library Flow

1. Open Library.
2. Enter separate Vault PIN.
3. Browse protected files.
4. Import, organize, preview, or export files.
5. Lock the Library.

### Emergency Flow

1. Open private chat.
2. Tap the more menu.
3. Tap Emergency Quick Exit.
4. Private content locks and disappears.
5. Normal AI chat appears.
6. Continue with an ordinary AI prompt.

## 26. Success Criteria

MIRALO AI is successful when:

- The app feels as simple as ChatGPT
- Private features do not look suspicious or overdesigned
- Private and AI chats feel like one cohesive product
- Private content remains inaccessible without the correct credential
- Library protection is independent from private chat unlock
- AI providers never receive private unlock secrets
- Private media is not automatically saved to the device gallery
- Emergency exit works quickly and discreetly
- Light and dark modes feel equally polished
- The app remains fast, responsive, and accessible
- Security limitations are clearly communicated to users
