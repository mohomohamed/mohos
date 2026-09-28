# DisplayMenu

**DisplayMenu** is a lightweight, high-performance native macOS menu bar utility for managing display resolutions and streamlining screenshot workflows.

Created & Developed by **Mohamed Moho**.

---

## 🚀 Features

- **Clipboard Screenshot Workflow (`⌘⇧4` → Clipboard)**:
  - Intercepts `⌘⇧4` globally using native macOS Quartz `CGEventTap` and translates it to `⌃⌘⇧4`.
  - Opens Apple's native area-selection UI and copies the image directly to the clipboard.
  - **No screenshot files are created on disk or Desktop**.
  - No Karabiner-Elements or shell scripts required.
- **Display Resolution Management**:
  - Switch between **HiDPI (Retina)** and **LoDPI** display resolutions instantly.
  - Dynamic screen connect/disconnect detection (`didChangeScreenParametersNotification`).
  - Powered by [`displayplacer`](https://github.com/jresh/displayplacer) as its native backend.
- **Modern macOS Control Center UI**:
  - Native monochromatic SF Symbol menu bar icon.
  - Compact display header with active resolution indicator (`1280 × 720 · Active`).
  - Segmented controls for filtering modes (`HiDPI`, `LoDPI`, `All`) and switching views (`List`, `Slider`).
  - macOS Sonoma/Sequoia Control Center capsule slider.
- **System Integration**:
  - Auto-starts via `SMAppService` (macOS 13+) with LaunchAgent fallback.
  - Automatic, non-intrusive Accessibility permission detection.
  - Zero idle CPU usage and zero background battery drain.

---

## 🛠 Building & Installing

Run the included build script:

```bash
chmod +x build.sh
./build.sh
```

This compiles all Swift source modules in `src/`, creates `DisplayMenu.app`, signs it ad-hoc, installs it to `~/Applications/DisplayMenu.app`, and launches it immediately.

---

## 📁 Modular Project Structure

```
DisplayMenu/
├── src/
│   ├── Models.swift                  # DisplayInfo, DisplayMode, ViewMode, DisplayFilterMode
│   ├── PreferencesManager.swift      # UserDefaults persistence wrapper
│   ├── DisplayManager.swift          # displayplacer wrapper & resolution switching
│   ├── PermissionManager.swift       # Accessibility permission & System Settings launcher
│   ├── ScreenshotShortcutManager.swift # CGEventTap ⌘⇧4 shortcut interceptor & synthesizer
│   ├── LoginItemManager.swift        # SMAppService & LaunchAgent login item manager
│   ├── Views/
│   │   ├── DisplayHeaderView.swift   # Display name, SF symbol, active resolution badge
│   │   ├── ControlCenterSliderView.swift # Sonoma/Sequoia Control Center capsule slider
│   │   ├── ScreenshotWorkflowView.swift  # ⌘⇧4 → Clipboard toggle & permission row
│   │   └── SegmentedControlViews.swift   # Mode filter & List/Slider view segmented controls
│   ├── AppDelegate.swift             # Application delegate & menu controller
│   └── main.swift                    # Main application entry point
├── Info.plist                        # App bundle metadata
├── AppIcon.icns                      # macOS App Icon
├── build.sh                          # Build & installation script
└── README.md                         # Documentation
```

---

## 👤 Author

Developed by **Mohamed Moho**.
