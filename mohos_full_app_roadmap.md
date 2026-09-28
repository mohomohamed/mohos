# mohos — Full-Fledged macOS App Roadmap & Technical Specification

**Project:** mohos  
**Repository:** https://github.com/mohomohamed/mohos  
**Platform:** macOS  
**Primary stack:** Swift + AppKit, with SwiftUI where useful  
**Product direction:** Lightweight macOS utility for displays, screenshots, and productivity shortcuts

---

## 1. Product Vision

mohos should evolve from a personal menu-bar utility into a polished macOS application that can be installed by any user without Terminal, Homebrew, or manual configuration.

The product should focus on three core ideas:

1. **Fast display control**
2. **Clipboard-first screenshots for AI workflows**
3. **Lightweight native macOS automation**

The app should remain small, fast, native, and focused.

A useful positioning statement:

> **mohos is a lightweight macOS utility for display management, clipboard-first screenshots, and productivity shortcuts.**

---

# 2. Current State

The existing app already has a strong technical base.

## Current functionality

- Native macOS menu-bar app
- AppKit-based UI
- Display detection
- Resolution switching
- HiDPI and LoDPI mode filtering
- List and slider display modes
- `displayplacer` integration
- Dynamic display plug/unplug detection
- Clipboard-first screenshot workflow
- Global `⌘⇧4` interception
- Translation of `⌘⇧4` to `⌃⌘⇧4`
- Accessibility permission detection
- Launch at login
- UserDefaults-based preferences
- Native SF Symbols
- Light/dark mode compatibility

## Current architecture

```text
mohos
│
├── DisplayManager
│   └── displayplacer
│
├── ScreenshotShortcutManager
│   └── CGEventTap
│       └── ⌘⇧4 → ⌃⌘⇧4
│
├── PermissionManager
│   └── Accessibility
│
├── LoginItemManager
│   └── SMAppService / LaunchAgent fallback
│
├── PreferencesManager
│   └── UserDefaults
│
├── Menu Bar UI
│   └── AppKit
│
└── Custom Views
    ├── DisplayHeaderView
    ├── ControlCenterSliderView
    ├── ScreenshotWorkflowView
    └── SegmentedControlViews
```

---

# 3. Main Problems to Solve Before Public Release

The core features work, but the app still behaves like a developer utility rather than a finished product.

## Current limitations

### Installation

Current setup requires:

```text
Install Homebrew
↓
Install displayplacer
↓
Clone repository
↓
Run build.sh
↓
App is copied to ~/Applications
```

This is unsuitable for normal users.

### Build system

Current build process uses:

```bash
swiftc
codesign -s -
cp
```

This is useful for development, but not enough for a production-quality macOS app.

### App signing

The current bundle is ad-hoc signed.

A public release should use:

- Apple Developer ID
- Hardened Runtime
- Notarization
- Stapled notarization ticket

### Updates

There is no built-in updater.

### Testing

There are currently no automated tests.

### Error handling

Display mode changes are not verified strongly enough.

### Naming

There are still references to the original internal app name:

```text
DisplayMenu
```

These should all be replaced with:

```text
mohos
```

### Dependency

`displayplacer` must currently exist on the user’s machine.

---

# 4. Recommended Product Structure

mohos should use two UI surfaces:

## A. Menu Bar

Used for fast actions.

The menu should remain compact.

Example:

```text
┌──────────────────────────────────┐
│ 🖥 MacBook Display               │
│    1280 × 720 · HiDPI · Active   │
│                                  │
│ Resolution                       │
│ [1024] [1280] [1440]             │
│                                  │
│ Clipboard Screenshots       ●     │
│ ⌘⇧4 → Clipboard                  │
│                                  │
│ Profiles                         │
│ Work Setup                   ›    │
│ Native Resolution            ›    │
│                                  │
│ Settings…                   ⌘,    │
│ Quit mohos                  ⌘Q    │
└──────────────────────────────────┘
```

## B. Settings Window

Used for configuration.

Suggested sections:

```text
General
Displays
Screenshots
Shortcuts
Profiles
Advanced
About
```

---

# 5. Recommended Project Architecture

Move away from the flat `src` structure and create a proper Xcode project.

Recommended:

```text
mohos/
│
├── App/
│   ├── MohoApp.swift
│   ├── AppDelegate.swift
│   └── AppEnvironment.swift
│
├── Core/
│   ├── Logging/
│   ├── Permissions/
│   ├── Preferences/
│   └── Utilities/
│
├── Features/
│   │
│   ├── Displays/
│   │   ├── Models/
│   │   ├── DisplayManager.swift
│   │   ├── DisplayEngine.swift
│   │   ├── DisplayProfileManager.swift
│   │   └── Views/
│   │
│   ├── Screenshots/
│   │   ├── ScreenshotShortcutManager.swift
│   │   ├── ScreenshotHistoryManager.swift
│   │   ├── ScreenshotPreferences.swift
│   │   └── Views/
│   │
│   └── Shortcuts/
│       ├── GlobalShortcutManager.swift
│       └── ShortcutModels.swift
│
├── Services/
│   ├── LoginItemManager.swift
│   ├── PermissionManager.swift
│   ├── UpdateManager.swift
│   ├── DiagnosticsManager.swift
│   └── AppStateManager.swift
│
├── Settings/
│   ├── SettingsWindow.swift
│   ├── GeneralSettingsView.swift
│   ├── DisplaySettingsView.swift
│   ├── ScreenshotSettingsView.swift
│   ├── ShortcutSettingsView.swift
│   └── AdvancedSettingsView.swift
│
├── Resources/
│   ├── Assets.xcassets
│   ├── AppIcon.appiconset
│   └── BundledTools/
│
└── Tests/
    ├── DisplayParserTests.swift
    ├── ShortcutTests.swift
    ├── PreferenceTests.swift
    └── ProfileTests.swift
```

---

# 6. AppKit vs SwiftUI

Do not rewrite everything only because SwiftUI exists.

Recommended split:

## Keep AppKit for

- Status bar item
- Menu handling
- Global event taps
- Low-level keyboard interception
- Fine-grained menu-bar behavior

## Use SwiftUI for

- Settings
- Onboarding
- About window
- Diagnostics
- Profiles
- Reusable modern configuration screens

This gives mohos a modern interface without throwing away stable AppKit logic.

---

# 7. Remove the Homebrew Requirement

This is one of the most important improvements.

The user should not need to install:

```bash
brew install displayplacer
```

## Target experience

```text
Download mohos.dmg
↓
Drag mohos to Applications
↓
Open
↓
Done
```

## Recommended approach

Bundle a known compatible display engine with the application.

Example:

```text
mohos.app/
└── Contents/
    ├── MacOS/
    │   └── mohos
    │
    └── Resources/
        └── Tools/
            └── displayplacer
```

Then use:

```swift
Bundle.main.url(
    forResource: "displayplacer",
    withExtension: nil,
    subdirectory: "Tools"
)
```

instead of searching:

```text
/usr/local/bin
/opt/homebrew/bin
```

## Important

Pin the version of the bundled dependency.

Do not rely on whatever version Homebrew happens to install in the future.

Also include all required third-party license notices in the app bundle and About screen.

---

# 8. Improve the Display Engine Layer

Do not let the rest of the app directly depend on `displayplacer`.

Introduce an abstraction.

Example:

```swift
protocol DisplayEngine {
    func displays() async throws -> [Display]
    func apply(mode: DisplayMode, to display: Display) async throws
    func apply(profile: DisplayProfile) async throws
}
```

Then:

```swift
final class DisplayPlacerEngine: DisplayEngine {
    ...
}
```

Benefits:

- easier testing
- easier future replacement
- less fragile architecture
- cleaner separation between UI and external tool

---

# 9. Improve Display Data Models

Current display data is too small for future growth.

Recommended:

```swift
struct Display {
    let id: String
    let persistentID: String?
    let serialID: String?

    let name: String

    let isBuiltIn: Bool
    let isMain: Bool
    let isOnline: Bool

    let originX: Int?
    let originY: Int?

    let rotation: Int?

    let currentMode: DisplayMode?
    let modes: [DisplayMode]
}
```

Recommended mode model:

```swift
struct DisplayMode {
    let id: Int

    let pixelWidth: Int
    let pixelHeight: Int

    let logicalWidth: Int?
    let logicalHeight: Int?

    let refreshRate: Double?
    let colorDepth: Int?

    let isHiDPI: Bool
    let isCurrent: Bool
}
```

---

# 10. Safer Display Changes

Current behavior is approximately:

```text
Run displayplacer
↓
Wait 0.3 seconds
↓
Refresh menu
```

Improve this into:

```text
Request change
↓
Execute display command
↓
Capture stdout
↓
Capture stderr
↓
Check exit code
↓
Refresh display state
↓
Verify requested mode
↓
Return success/failure
```

Example result:

```swift
enum DisplayApplyResult {
    case success
    case modeUnavailable
    case displayDisconnected
    case commandFailed(String)
}
```

This allows proper error messaging.

---

# 11. Display Profiles

This should become one of mohos' strongest features.

Example profiles:

```text
AI Work
1280 × 720 HiDPI

Normal
1440 × 900 HiDPI

Maximum Workspace
1920 × 1200

Presentation
1920 × 1080

TV
3840 × 2160 · 60 Hz
```

Each profile can contain:

```text
Display
Resolution
HiDPI / LoDPI
Refresh rate
Rotation
Position
Primary display
Mirroring state
```

## Profile actions

```text
Apply
Rename
Duplicate
Delete
Assign Shortcut
Apply Automatically
```

---

# 12. Automatic Display Profiles

Later add automation rules.

Examples:

```text
WHEN LG UltraFine connects
THEN Apply "Desk Setup"
```

```text
WHEN external monitor disconnects
THEN Restore "Laptop"
```

```text
WHEN HDMI TV connects
THEN Apply "TV"
```

This should be event-driven using screen-change notifications.

Avoid constant polling.

---

# 13. Full Multi-Display Support

Future versions should expose more of the underlying display capabilities.

Potential features:

```text
Resolution
HiDPI / LoDPI
Refresh rate
Rotation
Display position
Primary display
Mirroring
Enable display
Disable display
```

Example UI:

```text
Displays

MacBook Pro
Built-in
1440 × 900
60 Hz
Primary

LG 4K
3840 × 2160
60 Hz

Use As:
• Extended
○ Mirror
○ Disabled

Rotation:
[0°] [90°] [180°] [270°]
```

---

# 14. Screenshot Workflow

The current screenshot feature is already a strong differentiator.

Current workflow:

```text
User presses ⌘⇧4
↓
mohos intercepts it
↓
original event suppressed
↓
mohos emits ⌃⌘⇧4
↓
Apple native screenshot selector appears
↓
image goes to clipboard
↓
no screenshot file created
```

Keep this behavior.

The app should never recreate the screenshot selection UI.

Use Apple's native screenshot system.

---

# 15. Screenshot Settings

Suggested Settings page:

```text
Screenshots

Clipboard Screenshots                   [ON]

Area Screenshot
⌘ ⇧ 4

Behavior
● Copy to clipboard
○ Save to file
○ Copy and save

Full Screen Screenshot                 [OFF]
⌘ ⇧ 3

Window Screenshot                      [OFF]

Remember last 10 screenshots           [OFF]

Clear screenshot history on quit       [ON]
```

For the first public version, keep only the features that are stable.

---

# 16. Screenshot History

Optional but valuable for AI workflows.

Recommended architecture:

```text
Screenshot
↓
Clipboard
↓
Optional RAM cache
```

Default behavior:

```text
Last 10 screenshots
Stored in memory only
Deleted when mohos quits
```

No automatic files.

Example menu:

```text
Recent Captures

[thumbnail] 20 sec ago
[thumbnail] 1 min ago
[thumbnail] 3 min ago

Clear
```

Actions:

```text
Copy
Save…
Open in Preview
Delete
```

---

# 17. Custom Global Shortcuts

Long-term, shortcuts should not be hard-coded.

Introduce:

```swift
struct KeyboardShortcut {
    var keyCode: CGKeyCode
    var modifiers: CGEventFlags
}
```

Settings example:

```text
Area Clipboard Screenshot
⌘ ⇧ 4

Apply AI Work Profile
⌃ ⌥ 1

Apply Normal Profile
⌃ ⌥ 2
```

Conflict detection should warn users when a shortcut is already used.

---

# 18. Accessibility Permission UX

Current permission detection is good, but can be improved.

Use internal states:

```swift
enum PermissionState {
    case notRequested
    case denied
    case authorized
    case unavailable
}
```

Then UI can show:

```text
Clipboard Screenshots              ON

Accessibility
✓ Allowed
```

or:

```text
Clipboard Screenshots              OFF

Accessibility permission required

[Open System Settings]
```

Avoid repeated prompts.

---

# 19. First-Run Onboarding

Add a simple onboarding flow.

## Screen 1

```text
Welcome to mohos

Fast display controls and
clipboard-first screenshots
for macOS.

[Continue]
```

## Screen 2

```text
Clipboard Screenshots

Press:

⌘ ⇧ 4

Select an area.

The screenshot goes directly
to your clipboard.

No files are created.

[Enable]
```

## Screen 3

```text
Accessibility Permission

mohos needs Accessibility permission
to translate your screenshot shortcut.

mohos does not record your keystrokes.

[Open System Settings]
```

## Screen 4

```text
You're ready.

[Start Using mohos]
```

---

# 20. Settings Window

Recommended sections:

## General

```text
Launch at Login                 [ON]

Show menu bar icon              [ON]

Check for Updates Automatically [ON]

Menu style
● Compact
○ Detailed
```

## Displays

```text
Default View
● Slider
○ List

Resolution Filter
● All
○ HiDPI
○ LoDPI

Remember Display Settings       [ON]

Restore on Reconnect            [ON]
```

## Screenshots

```text
Clipboard Screenshots           [ON]

Area Screenshot
⌘ ⇧ 4

Full Screen Screenshot          [OFF]

Screenshot History              [OFF]
```

## Profiles

```text
AI Work
Normal
Presentation
TV

[+] Add Profile
```

## Advanced

```text
Enable Debug Logging            [OFF]

Reset Preferences

Copy Diagnostics

Open Log Folder
```

---

# 21. Diagnostics

Add a diagnostics panel.

Example:

```text
mohos Diagnostics

Version:
1.0.0

macOS:
15.7

Architecture:
Intel

Accessibility:
Granted

Screenshot Event Tap:
Running

Display Engine:
Available

Display Engine Version:
1.4.0

Displays:
2

Launch at Login:
Enabled
```

Buttons:

```text
[Copy Diagnostics]
[Export Logs]
```

---

# 22. Logging

Replace:

```swift
print(...)
```

with Apple's unified logging.

Use:

```swift
import OSLog

let logger = Logger(
    subsystem: "com.moho.mohos",
    category: "Display"
)
```

Categories:

```text
App
Display
Screenshot
Permissions
Updater
Profiles
Shortcuts
```

Avoid logging sensitive user content.

---

# 23. Error Handling

The app should never silently fail.

Examples:

```text
Couldn’t change resolution.

The selected mode is no longer available.
```

```text
Clipboard shortcut unavailable.

Accessibility permission is required.
```

```text
Display disconnected.

The selected monitor is no longer connected.
```

Errors should be short and human-readable.

Technical details should go to logs.

---

# 24. Menu Bar UI Redesign

Keep the menu modern and minimal.

Design principles:

- Native macOS controls
- SF Symbols
- semantic colors
- no web-dashboard look
- no excessive cards
- no unnecessary borders
- compact spacing
- dark/light mode
- current accent color
- native keyboard glyphs

Example:

```text
🖥 MacBook Display
1280 × 720 · HiDPI · Active

Resolution
[ All | HiDPI | LoDPI ]

[────────────●──────────]
1280 × 720

Clipboard Screenshots       ●
⌘⇧4 → Clipboard

Settings…                  ⌘,
Quit mohos                 ⌘Q
```

---

# 25. Application Naming Cleanup

Replace all internal references to:

```text
DisplayMenu
```

with:

```text
mohos
```

Update:

```text
class comments
console logging
notification names
About menu
Quit menu
bundle strings
internal identifiers
```

Recommended identity:

```text
Product Name: mohos
Bundle ID: com.moho.mohos
```

---

# 26. Proper Xcode Build

Create:

```text
mohos.xcodeproj
```

Configure:

```text
Deployment Target
Bundle Identifier
App Icon
Version
Build Number
Signing
Hardened Runtime
Entitlements
Resources
Tests
```

`build.sh` may remain as a helper, but Xcode should become the source of truth.

---

# 27. Signing and Notarization

Public direct-download releases should use:

```text
Developer ID Application certificate
↓
Hardened Runtime
↓
codesign
↓
notarytool submit
↓
Apple notarization
↓
stapler
↓
DMG
```

Target:

```text
mohos-1.0.0.dmg
```

The app should open without Gatekeeper warnings when distributed correctly.

---

# 28. DMG Installer

Create a standard Mac installation DMG.

Example:

```text
┌───────────────────────────────┐
│                               │
│        mohos.app              │
│            ↓                  │
│        Applications           │
│                               │
└───────────────────────────────┘
```

No installer wizard is necessary.

---

# 29. Automatic Updates

Use Sparkle for direct-download releases.

Settings:

```text
Automatically check for updates [ON]
Automatically download updates   [OFF]
```

Flow:

```text
mohos
↓
Sparkle
↓
GitHub release
↓
Update downloaded
↓
Signature verified
↓
App replaced
```

---

# 30. GitHub Actions CI/CD

Recommended pipeline:

```text
Push / Pull Request
↓
Build
↓
Run Tests
↓
Lint
```

Release pipeline:

```text
Tag v1.0.0
↓
Build Release
↓
Sign
↓
Notarize
↓
Create DMG
↓
Generate Sparkle metadata
↓
Create GitHub Release
↓
Upload DMG
```

---

# 31. Testing Strategy

## Unit Tests

Test:

```text
display mode parsing
resolution sorting
HiDPI filtering
LoDPI filtering
profile serialization
preference persistence
shortcut matching
```

## Integration Tests

Test:

```text
display engine invocation
error handling
permission state
profile application
```

## Manual Tests

Test on:

```text
Intel Mac
Apple Silicon Mac
Single display
Multiple displays
External HDMI display
Display reconnect
Dark mode
Light mode
Accessibility allowed
Accessibility denied
Launch at login
```

---

# 32. Security and Privacy

This matters because mohos requests Accessibility permission.

The app should make it clear that:

```text
mohos does not record your typing.

The keyboard event listener is used only
to detect configured shortcuts.
```

Do not:

```text
store keystrokes
send keystrokes remotely
collect screenshot contents
upload screenshots
store screenshot history by default
```

Screenshot history should default to:

```text
OFF
```

or memory-only.

---

# 33. Performance Requirements

mohos should remain extremely lightweight.

Target:

```text
Idle CPU: approximately 0%
No continuous polling
No Electron
No browser engine
No Node runtime
Minimal memory footprint
```

Use events wherever possible.

Examples:

```text
screen change notifications
event taps
application activation
system callbacks
```

instead of polling.

---

# 34. Product Roadmap

## Phase 1 — Foundation

Focus on making the existing app production-ready.

### Tasks

- Create proper Xcode project
- Clean up product naming
- Improve architecture
- Bundle display engine
- Remove Homebrew requirement
- Improve error handling
- Improve logging
- Add Settings window
- Add onboarding
- Proper Developer ID signing
- Notarization
- DMG distribution
- GitHub Actions build
- Basic tests

### Target

```text
mohos 1.0
```

---

## Phase 2 — Display Profiles

### Add

- Saved profiles
- Rename profile
- Duplicate profile
- Delete profile
- Assign shortcuts
- Restore display state
- Auto-apply profiles

### Target

```text
mohos 1.1
```

---

## Phase 3 — Screenshot Expansion

### Add

- Custom screenshot shortcuts
- Full-screen clipboard screenshot
- Window screenshot
- RAM-only screenshot history
- Copy last screenshot
- Save selected history item

### Target

```text
mohos 1.2
```

---

## Phase 4 — Advanced Display Management

### Add

- Refresh rate
- Rotation
- Primary display
- Arrangement
- Mirroring
- Disable/enable display

### Target

```text
mohos 1.5
```

---

## Phase 5 — Productivity Automation

Potential future features:

```text
Application-based display profiles
Time-based profiles
Custom shortcut actions
Focus Mode integrations
Quick AI screenshot workflow
OCR
Pinned screenshot overlays
```

Only add these if they remain consistent with mohos' lightweight philosophy.

---

# 35. Recommended Version 1.0 Scope

Do not attempt to build every feature before shipping.

A strong 1.0 should include:

```text
✓ Menu bar app
✓ Display resolution switching
✓ HiDPI / LoDPI filtering
✓ Slider and list views
✓ Clipboard screenshot shortcut
✓ Accessibility permission flow
✓ Launch at login
✓ Settings window
✓ First-run onboarding
✓ Bundled display engine
✓ No Homebrew dependency
✓ Proper Xcode project
✓ Developer ID signing
✓ Notarization
✓ DMG
✓ Automatic updater
✓ Diagnostics
✓ Logging
✓ Basic automated tests
```

Do not require for 1.0:

```text
Screenshot history
OCR
Display automation
Complex profiles
Mirroring UI
Arrangement UI
Cloud sync
Account system
Telemetry
```

---

# 36. Recommended Product Philosophy

mohos should avoid feature bloat.

The app should remain:

```text
Native
Fast
Small
Private
Local
Predictable
Useful
```

Every new feature should answer:

> Does this make everyday macOS display or screenshot workflows faster?

If not, it probably does not belong in mohos.

---

# 37. Suggested Short Product Description

> **mohos is a lightweight native macOS utility for fast display management and clipboard-first screenshots. Switch resolutions instantly, use HiDPI and LoDPI modes, and capture screenshots directly to your clipboard without filling your Desktop with temporary files.**

---

# 38. Suggested GitHub Repository Description

```text
Native macOS utility for display management, HiDPI/LoDPI switching, and clipboard-first screenshots.
```

---

# 39. Suggested Release Milestones

```text
v0.9
Internal development build

v1.0
First stable public release

v1.1
Display profiles

v1.2
Advanced screenshot workflows

v1.5
Full display management

v2.0
Automation and workflow platform
```

---

# 40. Recommended Next Implementation Order

Work in this order:

```text
1. Create Xcode project
2. Move existing source without changing behavior
3. Confirm existing features still work
4. Rename remaining DisplayMenu references
5. Introduce DisplayEngine abstraction
6. Bundle displayplacer
7. Remove external Homebrew dependency
8. Add structured logging
9. Improve error handling
10. Add Settings window
11. Add onboarding
12. Add diagnostics
13. Add unit tests
14. Configure Developer ID signing
15. Configure notarization
16. Create DMG
17. Add Sparkle
18. Add GitHub Actions
19. Release v1.0
20. Start display profiles for v1.1
```

This order reduces the risk of breaking the working app while rebuilding its foundations.

---

# Final Goal

The finished experience should be:

```text
User downloads mohos.dmg

        ↓

Drags mohos to Applications

        ↓

Launches mohos

        ↓

Completes a short onboarding

        ↓

Grants Accessibility permission
if using clipboard screenshots

        ↓

mohos lives quietly in the menu bar

        ↓

⌘⇧4
Select area
⌘V into ChatGPT

No screenshot files created.

        ↓

Click menu bar icon

Instantly switch display resolution,
HiDPI/LoDPI mode, or profile.
```

No Terminal.

No Homebrew.

No setup scripts.

No unnecessary background processes.

That should be the standard for a full-fledged mohos release.
