# mohos macOS Menu Bar UI Simplification Prompt

## Role

You are a senior macOS product designer and SwiftUI/AppKit engineer.

Your task is to redesign the **mohos** menu bar app so the menu bar popover is much simpler, cleaner, more native to macOS, and focused only on actions that should be accessible in one or two clicks.

The current UI is too dense because it mixes:

- Current display status
- Display filtering
- Resolution display modes
- DNS settings
- Screenshot permissions
- App settings
- Troubleshooting actions
- Launch-at-login controls
- About information

The goal is to move configuration-heavy controls into a proper **Settings window** while keeping the menu bar popover extremely lightweight.

---

# Primary UX Goal

The menu bar popover should behave like a **quick-control surface**, not a full settings dashboard.

The user should immediately be able to:

1. See the active display and current resolution
2. Change the display resolution
3. Toggle DNS Shield
4. Toggle clipboard screenshots
5. Open Settings
6. Quit the app

Everything else should move to Settings.

---

# Main Menu Bar Popover

Redesign the menu bar popover into approximately this structure:

```text
┌──────────────────────────────────────┐
│  mohos                         ⚙︎    │
├──────────────────────────────────────┤
│  DISPLAY                             │
│                                      │
│  🖥 Built-in Display             ●   │
│     1440 × 900 · LoDPI              │
│                                      │
│  Resolution                          │
│  [ 1440 × 900 ▾ ]                   │
├──────────────────────────────────────┤
│  QUICK TOOLS                         │
│                                      │
│  🛡 DNS Shield                  ON   │
│     AdGuard DNS                      │
│                                      │
│  ⧉ Screenshots → Clipboard      ON   │
├──────────────────────────────────────┤
│  Settings…                       ⌘,  │
│  Quit mohos                      ⌘Q  │
└──────────────────────────────────────┘
```

Use native macOS spacing, typography, separators, hover states, and controls.

Do not make the UI look like a web dashboard.

---

# Remove Redundant Display UI

The current interface shows the selected display information more than once.

Remove duplicated display cards.

Instead of showing:

```text
MacBook built in screen
1440 × 900 (LoDPI) · Active

[All] [HiDPI] [LoDPI] [List] [Res] [Text Size]

MacBook built in...
1440 × 900 (LoDPI) · Active
```

reduce it to one clear display row:

```text
🖥 Built-in Display
   1440 × 900 · LoDPI
```

or:

```text
🖥 Built-in Display                ●
   1440 × 900 · LoDPI
```

Do not repeatedly write `Active`.

The visual selection state or a subtle status indicator is enough.

---

# Remove the Filter Toolbar from the Popover

Remove the following controls from the main menu:

```text
All
HiDPI
LoDPI
List
Res
Text Size
```

These are configuration and filtering controls, not quick actions.

Move them into:

```text
Settings → Display
```

---

# Display Settings

Create a dedicated Display settings section.

Suggested structure:

```text
Display
────────────────────────

Default display
[ MacBook Built-in Display ▾ ]

Resolution filtering

○ Recommended
○ HiDPI only
○ All resolutions

Resolution display

○ Resolution
○ Effective text size
○ Detailed

☑ Show refresh rates
☑ Show scaled resolutions
☐ Show unsupported resolutions

Advanced…
```

The actual implementation can vary slightly if needed, but the functionality should remain logically grouped.

---

# Resolution Switching

The menu bar popover should provide a simple resolution control.

Preferred design:

```text
Resolution
[ 1440 × 900 ▾ ]
```

Clicking it should show the available resolutions.

Do not expose advanced filtering controls directly in the main popover.

If useful, resolution entries may include metadata such as:

```text
1440 × 900
1280 × 800 · HiDPI
1152 × 720 · HiDPI
```

Keep the list readable.

---

# HiDPI Handling

Do not use a global HiDPI ON/OFF switch unless the app can reliably map the current resolution to a valid equivalent HiDPI mode.

Prefer representing HiDPI at the resolution level.

Example:

```text
Recommended

✓ 1440 × 900

HiDPI

  1280 × 800
  1152 × 720

Other

  1680 × 1050
  1920 × 1200
```

Avoid presenting controls that can put the user into an invalid or unsupported display configuration.

---

# DNS Shield in the Popover

The menu bar should only expose:

```text
🛡 DNS Shield                   ON
   AdGuard DNS
```

The row should contain:

- Feature name
- Current provider
- Toggle
- Optional subtle disclosure indicator if clicking the row opens settings

Do not expose provider selection directly in the main popover unless it can remain visually simple.

---

# DNS Settings

Move detailed DNS configuration into Settings.

Suggested structure:

```text
DNS Shield
────────────────────────

☑ Enable DNS Shield

Provider
[ AdGuard DNS ▾ ]

DNS mode
[ Default ▾ ]

☑ Start DNS Shield when mohos launches

Status
Protected
```

If additional DNS configuration exists, place it here instead of expanding the main popover.

---

# Clipboard Screenshots

The main menu should show only:

```text
⧉ Screenshots → Clipboard        ON
```

Optionally add one short secondary line if needed.

The main popover should not permanently display permission-management controls.

---

# Screenshot Settings

Move screenshot-related configuration into Settings.

Suggested structure:

```text
Clipboard Screenshots
────────────────────────

☑ Copy screenshots directly to clipboard

Shortcut
⌘ ⇧ 4

Save screenshot to disk
☐ Enabled

Permissions

Accessibility        ✓ Allowed
Screen Recording     ✓ Allowed
```

If the app uses a different shortcut or capture method, preserve the actual implementation.

---

# Permission Warning Behavior

Do not permanently show:

```text
Accessibility permission required
Grant Permission
```

inside the menu bar UI.

Only display a permission warning when a required permission is missing.

Example temporary state:

```text
⚠ Screenshots need Accessibility permission
   [Allow]
```

Once the permission is granted, the warning should disappear completely.

Permission management should also be available under Settings.

---

# General Settings

Move the following items into Settings:

- Open at Login
- About mohos
- Version information
- Update controls
- Other application preferences

Suggested General settings page:

```text
General
────────────────────────

☑ Launch mohos at login
☑ Show status icons in menu

Check for Updates

About mohos
Version 1.x
```

---

# Refresh Displays

Remove `Refresh Displays` from the permanent menu.

Display detection should refresh automatically when possible.

If a manual refresh action is still required for troubleshooting, put it in either:

```text
Settings → Display → Advanced
```

or an optional overflow menu:

```text
…
```

Do not make it a primary menu-bar action.

---

# Bottom Menu Items

Keep the bottom section minimal.

Only show:

```text
Settings…                      ⌘,
Quit mohos                     ⌘Q
```

Avoid adding About, Launch at Login, Refresh, diagnostics, or other secondary actions here.

---

# Visual Design Direction

Use native macOS design conventions.

Prefer:

- SF Symbols
- System typography
- Native macOS toggles
- Native menus and pickers
- Proper menu row heights
- Subtle section labels
- System separators
- macOS hover states
- Standard corner radii where appropriate
- Dark mode and light mode support

Avoid:

- Large web-style cards everywhere
- Excessive pills
- Thick borders
- Too many rounded containers
- Oversized section headers
- Repeated status labels
- Excessive use of accent color
- Dense control toolbars

The UI should look like a polished macOS utility, not an Electron dashboard.

---

# Suggested Final Popover

A strong final target is:

```text
DISPLAY

🖥 Built-in Display                      ●
   1440 × 900 · LoDPI                   ›

Resolution
[ 1440 × 900 ▾ ]


QUICK TOOLS

🛡 DNS Shield                            ON
   AdGuard DNS

⧉ Screenshots → Clipboard                ON


────────────────────────────────────────

Settings…                               ⌘,
Quit mohos                              ⌘Q
```

Keep the overall popover compact.

---

# Interaction Requirements

## Display row

Clicking the display row may:

- Select the display if multiple displays exist
- Open a lightweight resolution subview
- Open display settings

Choose the interaction that produces the cleanest UX.

If multiple displays are connected, show them in a compact list.

---

## DNS Shield

The toggle should immediately enable or disable DNS protection.

Secondary DNS configuration belongs in Settings.

---

## Clipboard Screenshots

The toggle should immediately enable or disable clipboard screenshot behavior.

If required permissions are missing:

1. Show a concise warning
2. Provide one clear action
3. Do not flood the interface with technical permission details

---

# Multiple Display Support

If more than one display exists, keep the UI scalable.

Example:

```text
DISPLAY

🖥 MacBook Built-in Display          ●
   1440 × 900 · LoDPI

▣ External Display
   2560 × 1440 · HiDPI
```

Selecting a display should update the resolution control beneath it.

Do not duplicate the entire display settings interface for each monitor.

---

# Settings Window Navigation

Use a native macOS Settings window.

Recommended sections:

```text
General
Display
DNS Shield
Screenshots
Advanced
```

If the app is small enough, a sidebar is acceptable.

A toolbar-style Settings layout is also acceptable if it feels more native.

---

# Advanced Settings

Create an Advanced section for low-frequency or potentially risky options.

Possible items:

```text
Advanced
────────────────────────

Refresh display list

☐ Show unsupported display modes
☐ Show low-level resolution information
☐ Enable debugging

Reset display preferences

Export diagnostics
```

Do not place these in the normal menu bar popover.

---

# State Persistence

Ensure user preferences persist across app launches, including:

- DNS Shield enabled state
- DNS provider
- Clipboard screenshot enabled state
- Display filtering preference
- Resolution presentation style
- Launch at Login preference
- Other Settings selections

Use the existing storage system if already implemented.

Do not unnecessarily rewrite working persistence code.

---

# Important Engineering Requirement

Do not remove working app functionality just to simplify the interface.

Refactor where controls live.

Preserve existing logic for:

- Display detection
- Resolution switching
- HiDPI detection
- DNS Shield
- DNS provider handling
- Screenshot capture
- Clipboard functionality
- Permission checking
- Login item handling

Only change underlying logic if required to support the new interface cleanly.

---

# Accessibility

The redesigned UI must support:

- VoiceOver labels
- Keyboard navigation
- Proper focus states
- High contrast
- Dynamic system appearance
- Clear toggle states

Avoid relying only on color to communicate status.

---

# Performance

The menu bar popover should open immediately.

Avoid expensive operations when the menu opens.

Cache display information where appropriate and refresh display data asynchronously.

Do not block the main UI thread while checking:

- DNS state
- Display modes
- Permissions
- Screenshot state

---

# Code Quality

While implementing the redesign:

- Break major UI areas into reusable views
- Avoid one giant SwiftUI view
- Separate Settings views from popover views
- Keep state management centralized
- Reuse existing managers/services where possible
- Do not duplicate display or DNS logic inside view code
- Maintain current functionality unless explicitly changed above

Suggested architecture:

```text
MenuBarView
├── DisplayQuickControlView
├── ResolutionPickerView
├── DNSQuickControlView
├── ScreenshotQuickControlView
└── MenuFooterView

SettingsView
├── GeneralSettingsView
├── DisplaySettingsView
├── DNSSettingsView
├── ScreenshotSettingsView
└── AdvancedSettingsView
```

Adapt this to the current project architecture rather than forcing a rewrite.

---

# Acceptance Criteria

The redesign is complete when:

- [ ] The menu bar popover is visibly less cluttered
- [ ] Duplicate display information is removed
- [ ] All / HiDPI / LoDPI filters are removed from the main popover
- [ ] List / Res / Text Size controls are removed from the main popover
- [ ] Display filters are available in Settings
- [ ] Resolution switching remains quick
- [ ] DNS Shield can still be toggled directly
- [ ] DNS provider configuration is moved to Settings
- [ ] Clipboard screenshot mode can still be toggled directly
- [ ] Permission management is moved to Settings
- [ ] Permission warnings appear only when required
- [ ] Open at Login is moved to Settings
- [ ] About is moved to Settings
- [ ] Refresh Displays is no longer a permanent menu item
- [ ] Settings and Quit remain easily accessible
- [ ] The interface works in light and dark mode
- [ ] Existing application functionality continues to work
- [ ] UI looks and behaves like a native macOS menu bar utility

---

# Final Instruction

First inspect the current project structure and identify how the existing menu bar, display manager, DNS manager, screenshot manager, permissions, and settings are implemented.

Then implement this redesign **without unnecessarily rewriting working backend functionality**.

Prioritize:

1. Simplicity
2. Native macOS behavior
3. Fast access to common actions
4. Clear hierarchy
5. Minimal visual clutter
6. Safe preservation of existing functionality

Do not merely restyle the existing crowded UI.

Actually reorganize the application so advanced configuration lives in Settings and the menu bar becomes a focused quick-control interface.
