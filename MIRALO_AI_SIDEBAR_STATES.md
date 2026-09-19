# MIRALO AI — Exact Locked & Unlocked Sidebar Specification

## 1. Core Rule

> The AI chat interface never changes. Only the sidebar content changes according to Private Space access state.

The active screen, composer, message bubbles, typography, icons, spacing, and navigation remain identical in both states.

Private Space is unlocked by entering the configured secret into the normal AI composer. There is no separate Private Space unlock screen.

The Library has its own dedicated Vault unlock UI.

---

## 2. Sidebar States

MIRALO AI has three related interface states:

1. **Locked State** — Private Space is unavailable.
2. **Unlocked State** — Private Space is available.
3. **Library Vault State** — A separate protected Library interface after Vault authentication.

The Library Vault state is independent of Private Space.

---

## 3. Locked Sidebar

### 3.1 Exact Ordering

```text
MIRALO AI Header
────────────────────────

＋ New Chat

Chats
  Recent AI Conversations

────────────────────────

Library

────────────────────────

Settings
About AI
```

### 3.2 Detailed Structure

```text
┌──────────────────────────────┐
│ MIRALO AI                    │
│                              │
│ ＋  New Chat                  │
│                              │
│ Chats                        │
│                              │
│  Quantum Computing           │
│  Resume Improvement          │
│  Java Threads                │
│  Project Ideas               │
│  Cybersecurity Notes         │
│                              │
│                              │
│ Library                  ›   │
│                              │
│                              │
│ ⚙ Settings               ›   │
│ ⓘ About AI               ›   │
└──────────────────────────────┘
```

### 3.3 Locked Sidebar Labels

| Order | Label | Type |
|---|---|---|
| 1 | MIRALO AI | Brand header |
| 2 | New Chat | Primary action |
| 3 | Chats | Section label |
| 4 | Recent AI conversations | Conversation list |
| 5 | Library | Protected feature |
| 6 | Settings | Navigation item |
| 7 | About AI | Navigation item |

The locked state uses **Chats** as the section title. Its contents are the user's recent AI conversations.

Recommended presentation:

```text
Chats

Quantum Computing
Resume Improvement
Java Threads
Project Ideas
```

---

## 4. Locked Sidebar Visibility Rules

### Always Visible

- MIRALO AI header
- New Chat
- Chats
- Recent AI conversations
- Library
- Settings
- About AI

### Hidden

- Pinned Chats section
- Private section
- Private contacts
- Private conversation previews
- Private unread counts
- Private images
- Naughty Mode
- Private media controls
- Private contact-management options

### Library Rule

The Library navigation item may remain visible while Private Space is locked.

However:

- Tapping Library opens the Library Vault PIN screen.
- Library content is never displayed before Vault authentication.
- Private Space unlock does not unlock Library.
- Library Vault unlock does not unlock Private Space.

---

## 5. Locked Sidebar Empty State

If the user has no AI conversations:

```text
Chats

No conversations yet.

Start a new chat to begin.
```

The New Chat action remains available and prominent.

The sidebar must not show empty placeholders for private features.

---

## 6. Unlocked Sidebar

After successful Private Space unlock, the sidebar changes to the following structure.

### 6.1 Exact Ordering

```text
MIRALO AI Header
────────────────────────

＋ New Chat

Chats
  AI Conversations

Pinned Chats
  Pinned AI Conversations

Private
  Private Contacts / Conversations

────────────────────────

Images
Library
Naughty Mode

────────────────────────

Settings
About AI
```

### 6.2 Detailed Structure

```text
┌──────────────────────────────┐
│ MIRALO AI                    │
│                              │
│ ＋  New Chat                  │
│                              │
│ Chats                        │
│  Quantum Computing           │
│  Resume Improvement          │
│  Java Threads                │
│  Project Ideas               │
│                              │
│ Pinned Chats                 │
│  Research Ideas              │
│  Interview Preparation       │
│                              │
│ Private                      │
│  Sarah                       │
│  Alex                        │
│  Emma                        │
│                              │
│ Images                   ›   │
│ Library                  ›   │
│ Naughty Mode             ›   │
│                              │
│ ⚙ Settings               ›   │
│ ⓘ About AI               ›   │
└──────────────────────────────┘
```

---

## 7. Unlocked Sidebar Labels

| Order | Label | Type |
|---|---|---|
| 1 | MIRALO AI | Brand header |
| 2 | New Chat | Primary action |
| 3 | Chats | AI conversation section |
| 4 | AI conversations | Conversation list |
| 5 | Pinned Chats | Pinned AI conversation section |
| 6 | Pinned AI conversations | Conversation list |
| 7 | Private | Private conversation section |
| 8 | Private contacts/conversations | Private list |
| 9 | Images | Private media navigation |
| 10 | Library | Protected file storage |
| 11 | Naughty Mode | Private-only feature |
| 12 | Settings | Navigation item |
| 13 | About AI | Navigation item |

---

## 8. Chats Section Rules

### Locked State

The section is titled:

```text
Chats
```

It displays recent AI conversations.

### Unlocked State

The section remains titled:

```text
Chats
```

It continues displaying AI conversations.

The title should not change to `AI Chats`, because that adds unnecessary visual complexity.

### Recommended Behavior

- Show the most recent 5–8 conversations.
- Use one-line titles.
- Truncate long titles.
- Display relative timestamps only if space permits.
- Do not show message previews by default.
- Allow scrolling when the list exceeds available space.
- Use the same conversation-row component in both states.

---

## 9. Pinned Chats Section Rules

### Visibility

`Pinned Chats` is visible only when:

- Private Space is unlocked, and
- At least one AI conversation is pinned.

If no conversations are pinned, the section is hidden instead of displaying an empty section.

### Example Without Pinned Chats

```text
Chats
  Quantum Computing
  Resume Improvement

Private
  Sarah
  Alex
```

### Example With Pinned Chats

```text
Chats
  Quantum Computing
  Resume Improvement

Pinned Chats
  Cybersecurity Research

Private
  Sarah
  Alex
```

### Pinned Chat Behavior

- Pinning an AI conversation adds it to Pinned Chats.
- Unpinning removes it from Pinned Chats.
- Pinned Chats contains AI conversations only.
- Private conversations are not mixed into Pinned Chats.

---

## 10. Private Section Rules

### Visibility

The `Private` section is visible only after successful Private Space unlock.

It must remain hidden when:

- The app is first opened.
- The user has not entered the private secret.
- The private session expires.
- The user manually locks Private Space.
- Emergency Quick Exit is activated.
- The app is backgrounded, if auto-lock is enabled.

### Private List Contents

The section displays:

- Private person-to-person conversations
- Private contacts with active conversations
- Recently active private contacts
- Optional unread indicators, depending on Hide Mode

Example:

```text
Private

Sarah
Alex
Emma
```

### Private List Restrictions

Do not show:

- Romantic labels
- Relationship status
- Heart icons
- Explicit message previews
- Private media thumbnails
- Naughty Mode indicators
- Large privacy badges

Private conversations must use the same row design as AI conversations.

---

## 11. Private Section Sorting

Recommended default sorting:

1. Most recently active private conversation
2. Unread private conversations
3. Other conversations by latest activity

Unread indicators must be hidden when Hide Mode is enabled.

### Normal Display

```text
Private

Sarah       2
Alex
Emma
```

### Hide Mode Display

```text
Private

Person 1
Person 2
Person 3
```

Alternatively, private names and the entire Private section may be hidden until the user unlocks Private Space again.

---

## 12. Images Navigation Rules

### Locked State

`Images` is hidden.

Reason:

- It contains private media.
- Its existence may reveal private functionality.
- Private media should not be accessible before Private Space unlock.

### Unlocked State

`Images` becomes visible below the Private section:

```text
Images
```

Opening Images displays app-owned private media only.

It must not display the entire device gallery.

### Images Access Requirements

- Private Space must be unlocked.
- Private media access must be authorized.
- Image thumbnails must be protected.
- Images must not be automatically sent to AI.
- Images must not automatically save to the phone gallery.

---

## 13. Library Navigation Rules

### Locked State

`Library` remains visible as a normal navigation item:

```text
Library                 ›
```

When selected:

```text
Library Vault

Enter your Vault PIN
```

### Unlocked Private State

`Library` remains in the same location.

Private Space unlock must not bypass the Vault PIN. The user must authenticate separately.

### Credential Separation

```text
Private Chat Secret ≠ Library Vault PIN
```

The two unlock states are independent.

---

## 14. Naughty Mode Navigation Rules

### Locked State

Naughty Mode is completely hidden.

It must not appear in:

- Sidebar
- Settings shortcuts
- AI home cards
- Search results
- Onboarding screens
- Normal AI composer suggestions

### Unlocked State

Naughty Mode appears below Library:

```text
Images
Library
Naughty Mode
```

It opens a private-only experience.

Use the neutral navigation label:

```text
Naughty Mode
```

Avoid labels such as:

- Romance Center
- Couple Space
- Secret Fun
- Adult Zone
- Love Mode

---

## 15. Settings and About AI

These items are always visible in both states.

### Settings

```text
Settings                 ›
```

Settings may contain:

- Account
- AI Model
- Private Security
- Storage
- Appearance
- Notifications
- Privacy
- Help & Support
- About
- Sign Out

Recommended behavior:

- General settings are always visible.
- Private security settings require authentication before sensitive changes.
- Private contact settings are visible only after Private Space unlock.

### About AI

```text
About AI                 ›
```

It contains:

- MIRALO AI description
- AI provider information
- Model information
- Privacy explanation
- Terms
- Privacy Policy
- Version information
- Open-source acknowledgements, if applicable

---

## 16. Transition: Locked → Unlocked

### Trigger

The user enters the correct Private Chat Secret/PIN into the normal AI composer.

Example:

```text
4829
```

### Required Processing

1. Detect the input locally.
2. Compare it against a secure verifier.
3. Do not send the value to the AI backend as a prompt.
4. Do not save it in the AI conversation.
5. Do not add it to recent prompts.
6. Clear the composer.
7. Update the private-session state.
8. Refresh the sidebar.
9. Reveal unlocked-only sections.

### Transition Animation

Recommended duration:

```text
180–240 ms
```

Recommended animation:

- Sidebar content fades and slides into place.
- New sections appear with a subtle opacity transition.
- Existing AI chat remains stationary.
- No full-screen navigation.
- No celebratory animation.
- No “Private Space Unlocked” banner.
- No sound effect.
- No large lock animation.

### Visual Result

Before:

```text
Chats
  Recent AI chats

Library

Settings
About AI
```

After:

```text
Chats
  AI chats

Pinned Chats

Private
  Sarah
  Alex

Images
Library
Naughty Mode

Settings
About AI
```

The active AI conversation remains open.

---

## 17. Transition: Unlocked → Locked

Private Space becomes locked when any of the following occurs:

- User taps `Lock Private Space`.
- User enters `/lock`.
- User taps Emergency Quick Exit.
- Auto-lock timer expires.
- App is backgrounded, if configured.
- User logs out.
- Session is invalidated.
- Device security requirements fail.

### Required Behavior

1. Clear private session keys from active memory where appropriate.
2. Remove private conversations from the sidebar.
3. Remove private media shortcuts.
4. Hide Naughty Mode.
5. Return the sidebar to the locked state.
6. Keep the current AI conversation visible if it is safe to display.
7. Never expose private content in AI chat history.

### Animation

- 150–220 ms fade transition
- Private sections disappear smoothly
- No warning banner
- No visible “Private Locked” notification
- No navigation to a separate lock screen

The sidebar simply returns to the normal AI-focused state.

---

## 18. Emergency Quick Exit Transition

Emergency Quick Exit must be more immediate than normal locking.

### Trigger Sources

- Emergency button in private chat menu
- `/urgent` entered into the composer
- Optional quick action in private media viewer

### Behavior

1. Intercept `/urgent` locally.
2. Do not send it to AI.
3. Do not save it in chat history.
4. Lock Private Space.
5. Hide private sidebar sections.
6. Remove private content from the current visible view.
7. Navigate to the last used normal AI conversation.
8. If no AI conversation exists, open a new AI chat.
9. Prefill the composer with:

```text
What can I help you with today?
```

10. Do not submit the prefilled message automatically.

### Emergency Animation

```text
150–200 ms
```

Use:

- Subtle fade
- Short slide
- Immediate content replacement

Avoid:

- Red emergency banners
- Alarm sounds
- Large lock icons
- “Emergency Mode Activated” text
- Obvious private-mode status indicators

---

## 19. Mobile Sidebar / Drawer Behavior

On mobile, the sidebar should appear as a ChatGPT-style navigation drawer or full-height sheet.

### Locked Drawer

```text
MIRALO AI

＋ New Chat

Chats
  Quantum Computing
  Resume Improvement
  Java Threads

Library

Settings
About AI
```

### Unlocked Drawer

```text
MIRALO AI

＋ New Chat

Chats
  Quantum Computing
  Resume Improvement
  Java Threads

Pinned Chats
  Research Ideas

Private
  Sarah
  Alex
  Emma

Images
Library
Naughty Mode

Settings
About AI
```

### Drawer Rules

- Drawer opens from the top-left menu icon.
- Drawer closes after selecting a destination.
- Selecting a conversation closes the drawer.
- The drawer preserves scroll position during normal navigation.
- Private sections do not animate independently in a distracting way.
- Use a single consistent row height.
- Do not use separate private navigation tabs.

---

## 20. Sidebar Row Design

All rows must use the same component system.

### AI Conversation Row

```text
┌─────────────────────────────┐
│ Quantum Computing       ⋯   │
└─────────────────────────────┘
```

### Private Conversation Row

```text
┌─────────────────────────────┐
│ Sarah                   ⋯   │
└─────────────────────────────┘
```

Private rows must not use:

- Different bubble colors
- Heart icons
- Special gradients
- Decorative avatars by default
- Different typography
- Romantic badges

### Recommended Dimensions

- Row height: 44–52 px
- Horizontal padding: 12–16 px
- Selected-row corner radius: 10–12 px
- Icon size: 18–20 px
- Text size: 14–15 px
- Section label size: 11–12 px
- Section label weight: Medium or Semibold
- Minimum touch target: 44 × 44 px

---

## 21. Selected Item Behavior

### AI Conversation Selected

- Subtle neutral background
- No bright blue highlight
- High-contrast text
- Optional three-dot action menu

### Private Conversation Selected

- Same selected-row treatment as AI conversation
- No special private color
- No heart or romantic highlight
- No `Private` badge inside the row

### Navigation Item Selected

For Library, Images, and Settings:

- Use the same neutral selected background.
- Keep icon and label aligned consistently.
- Avoid full-width colored cards.

---

## 22. Final State Summary

### Locked Sidebar

```text
MIRALO AI

＋ New Chat

Chats
  Recent AI Conversations

Library

Settings
About AI
```

Hidden:

```text
Pinned Chats
Private
Images
Naughty Mode
```

### Unlocked Sidebar

```text
MIRALO AI

＋ New Chat

Chats
  AI Conversations

Pinned Chats
  Pinned AI Conversations

Private
  Private Conversations

Images
Library
Naughty Mode

Settings
About AI
```

---

## 23. Final Product Rule

> Locked state is AI-focused. Unlocked state adds private functionality without changing the AI interface.

The experience should feel like:

- **Before secret:** A clean AI assistant.
- **After secret:** The same AI assistant with additional contextual sidebar sections.
- **Library access:** A separate Vault PIN and dedicated file-management UI.
- **After emergency exit:** The app silently returns to the normal AI-focused sidebar.
