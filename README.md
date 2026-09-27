# DisplayMenu

**DisplayMenu** is a lightweight, high-performance macOS menu bar utility for quickly switching display resolutions and HiDPI/LoDPI scaling modes.

Created & Developed by **Mohamed Moho**.

Powered by [`displayplacer`](https://github.com/jresh/displayplacer) as its native backend.

---

## 🚀 Features

- **Instant Resolution Switching**: Easily toggle between HiDPI (Retina) and LoDPI display modes directly from your menu bar.
- **Multi-Monitor Support**: Automatically detects all connected internal and external displays.
- **Dynamic Screen Detection**: Automatically updates the menu when displays are plugged in or unplugged (`NSApplication.didChangeScreenParametersNotification`).
- **Launch at Login**: Easily enable or disable auto-start via LaunchAgents.
- **Zero Resource Footprint**: Built with pure Swift and AppKit — no Electron, no background polling, zero idle CPU usage.

---

## 🖥 Dependencies

DisplayMenu relies on `displayplacer` to interact with macOS CoreGraphics display APIs:

```bash
brew install displayplacer
```

---

## 🛠 Building & Installing

Run the included build script:

```bash
chmod +x build.sh
./build.sh
```

This compiles the Swift source into `DisplayMenu.app`, signs it ad-hoc, installs it to `~/Applications/DisplayMenu.app`, and launches it immediately.

---

## 📁 Repository Structure

```
DisplayMenu/
├── main.swift         # Main Swift source code (AppKit NSStatusItem + displayplacer wrapper)
├── Info.plist         # App bundle metadata (configured as UIElement status bar app)
├── build.sh           # Build, package, code-sign, install, and launch script
└── README.md          # Documentation
```

---

## 👤 Author

Developed by **Mohamed Moho**.
