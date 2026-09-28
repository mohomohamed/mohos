//
//  main.swift
//  DisplayMenu
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import AppKit
import Foundation

struct DisplayMode {
    let modeId: Int
    let width: Int
    let height: Int
    let colorDepth: Int
    let isScaled: Bool
    let isCurrent: Bool
}

struct DisplayInfo {
    let screenId: String
    let name: String
    let modes: [DisplayMode]
}

// MARK: - Modern macOS Resolution Slider Card
class ModernSliderView: NSView {
    let titleLabel: NSTextField
    let modeBadge: NSTextField
    let slider: NSSlider
    let modes: [DisplayMode]
    let screenId: String
    weak var delegate: AppDelegate?

    init(frame: NSRect, display: DisplayInfo, modes: [DisplayMode], delegate: AppDelegate) {
        self.modes = modes
        self.screenId = display.screenId
        self.delegate = delegate
        
        // Display Title (Icon + Name)
        let tLabel = NSTextField(labelWithString: "📺  \(display.name)")
        tLabel.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        tLabel.textColor = NSColor.labelColor
        tLabel.frame = NSRect(x: 14, y: frame.height - 26, width: 140, height: 18)
        self.titleLabel = tLabel
        
        // Current Resolution Badge
        let currentIdx = modes.firstIndex(where: { $0.isCurrent }) ?? 0
        let initialText = modes.indices.contains(currentIdx) ? "\(modes[currentIdx].width)×\(modes[currentIdx].height) (\(modes[currentIdx].isScaled ? "HiDPI" : "LoDPI"))" : ""
        
        let mBadge = NSTextField(labelWithString: initialText)
        mBadge.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        mBadge.textColor = NSColor.secondaryLabelColor
        mBadge.alignment = .right
        mBadge.frame = NSRect(x: frame.width - 154, y: frame.height - 26, width: 140, height: 18)
        self.modeBadge = mBadge

        // Modern Slider + SF Symbols
        let maxVal = Double(max(0, modes.count - 1))
        let sSlider = NSSlider(value: 0, minValue: 0, maxValue: maxVal, target: nil, action: nil)
        
        if #available(macOS 11.0, *) {
            sSlider.frame = NSRect(x: 36, y: 12, width: frame.width - 72, height: 20)
        } else {
            sSlider.frame = NSRect(x: 14, y: 12, width: frame.width - 28, height: 20)
        }
        
        sSlider.numberOfTickMarks = max(2, modes.count)
        sSlider.allowsTickMarkValuesOnly = true
        sSlider.isContinuous = true
        sSlider.integerValue = currentIdx
        self.slider = sSlider

        super.init(frame: frame)
        
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.06).cgColor
        
        addSubview(titleLabel)
        addSubview(modeBadge)
        
        if #available(macOS 11.0, *) {
            let lowIcon = NSImageView(frame: NSRect(x: 14, y: 14, width: 16, height: 16))
            let config = NSImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
            lowIcon.image = NSImage(systemSymbolName: "rectangle.compress.vertical", accessibilityDescription: nil)?.withSymbolConfiguration(config)
            lowIcon.contentTintColor = NSColor.tertiaryLabelColor
            addSubview(lowIcon)
            
            let highIcon = NSImageView(frame: NSRect(x: frame.width - 30, y: 14, width: 16, height: 16))
            highIcon.image = NSImage(systemSymbolName: "rectangle.expand.vertical", accessibilityDescription: nil)?.withSymbolConfiguration(config)
            highIcon.contentTintColor = NSColor.tertiaryLabelColor
            addSubview(highIcon)
        }
        
        slider.target = self
        slider.action = #selector(sliderChanged(_:))
        
        addSubview(slider)
        updateBadge(for: currentIdx)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func updateBadge(for index: Int) {
        guard index >= 0 && index < modes.count else { return }
        let m = modes[index]
        let currentTag = m.isCurrent ? " • Active" : ""
        modeBadge.stringValue = "\(m.width) × \(m.height) (\(m.isScaled ? "HiDPI" : "LoDPI"))\(currentTag)"
    }

    @objc func sliderChanged(_ sender: NSSlider) {
        let idx = sender.integerValue
        updateBadge(for: idx)
        
        if let event = NSApp.currentEvent, event.type == .leftMouseUp {
            guard idx >= 0 && idx < modes.count else { return }
            let mode = modes[idx]
            if !mode.isCurrent {
                delegate?.applyMode(screenId: screenId, modeId: mode.modeId)
            }
        }
    }
}

// MARK: - Modern macOS NSSwitch Preference Row
class PreferencesSwitchRow: NSView {
    let label: NSTextField
    var toggleControl: NSControl?
    let onChange: (Bool) -> Void

    init(frame: NSRect, title: String, isOn: Bool, onChange: @escaping (Bool) -> Void) {
        self.onChange = onChange
        
        let l = NSTextField(labelWithString: title)
        l.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        l.textColor = NSColor.labelColor
        l.frame = NSRect(x: 16, y: (frame.height - 18) / 2, width: frame.width - 70, height: 18)
        self.label = l

        super.init(frame: frame)
        
        addSubview(label)
        
        if #available(macOS 10.15, *) {
            let sw = NSSwitch(frame: NSRect(x: frame.width - 54, y: (frame.height - 24) / 2, width: 38, height: 24))
            sw.state = isOn ? .on : .off
            sw.target = self
            sw.action = #selector(switchToggled(_:))
            toggleControl = sw
            addSubview(sw)
        } else {
            let btn = NSButton(checkboxWithTitle: "", target: nil, action: nil)
            btn.state = isOn ? .on : .off
            btn.frame = NSRect(x: frame.width - 34, y: (frame.height - 20) / 2, width: 20, height: 20)
            btn.target = self
            btn.action = #selector(switchToggled(_:))
            toggleControl = btn
            addSubview(btn)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc func switchToggled(_ sender: Any) {
        if #available(macOS 10.15, *), let sw = sender as? NSSwitch {
            onChange(sw.state == .on)
        } else if let btn = sender as? NSButton {
            onChange(btn.state == .on)
        }
    }
}

// MARK: - Main Application Delegate
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    var menu: NSMenu!
    var displayplacerPath: String = ""

    // User preferences
    var isSliderViewEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "UseSliderView") }
        set { UserDefaults.standard.set(newValue, forKey: "UseSliderView"); refreshMenu() }
    }

    var isHiDPIEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "ShowHiDPI") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "ShowHiDPI"); refreshMenu() }
    }

    var isLoDPIEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "ShowLoDPI") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "ShowLoDPI"); refreshMenu() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Find displayplacer executable path
        let possiblePaths = [
            "/usr/local/bin/displayplacer",
            "/opt/homebrew/bin/displayplacer",
            "/usr/bin/displayplacer"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                displayplacerPath = path
                break
            }
        }
        
        if displayplacerPath.isEmpty {
            displayplacerPath = locateDisplayPlacer()
        }

        // Setup Menu Bar Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if #available(macOS 11.0, *) {
                let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
                if let img = NSImage(systemSymbolName: "display", accessibilityDescription: "Display Menu")?.withSymbolConfiguration(config) {
                    img.isTemplate = true
                    button.image = img
                }
            } else {
                button.title = "🖥"
            }
        }

        menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        // Register screen change listener
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        refreshMenu()
    }

    @objc func screenParametersChanged() {
        refreshMenu()
    }

    func locateDisplayPlacer() -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = ["displayplacer"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
                return output
            }
        } catch {}
        return "/usr/local/bin/displayplacer"
    }

    func runDisplayPlacer(args: [String]) -> String? {
        guard !displayplacerPath.isEmpty, FileManager.default.isExecutableFile(atPath: displayplacerPath) else {
            return nil
        }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: displayplacerPath)
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    func parseDisplays() -> [DisplayInfo] {
        guard let output = runDisplayPlacer(args: ["list"]) else { return [] }
        
        var displays: [DisplayInfo] = []
        let screenBlocks = output.components(separatedBy: "Persistent screen id: ")
        
        for block in screenBlocks {
            if block.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
            
            let lines = block.components(separatedBy: .newlines)
            guard let screenIdLine = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }
            let screenId = screenIdLine.components(separatedBy: .whitespaces).first ?? screenIdLine
            
            var name = "Display"
            var modes: [DisplayMode] = []
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.starts(with: "Type:") {
                    name = trimmed.replacingOccurrences(of: "Type:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                } else if trimmed.contains("mode ") && trimmed.contains("res:") {
                    if let mode = parseModeLine(trimmed) {
                        modes.append(mode)
                    }
                }
            }
            
            displays.append(DisplayInfo(screenId: screenId, name: name, modes: modes))
        }
        
        return displays
    }

    func parseModeLine(_ line: String) -> DisplayMode? {
        let isCurrent = line.contains("<-- current mode")
        let isScaled = line.contains("scaling:on")
        
        guard let modeRange = line.range(of: "mode ") else { return nil }
        let afterMode = line[modeRange.upperBound...]
        guard let colonIdx = afterMode.firstIndex(of: ":") else { return nil }
        guard let modeId = Int(afterMode[..<colonIdx].trimmingCharacters(in: .whitespaces)) else { return nil }
        
        guard let resRange = line.range(of: "res:") else { return nil }
        let afterRes = line[resRange.upperBound...]
        let resParts = afterRes.components(separatedBy: .whitespaces)
        guard let resString = resParts.first else { return nil }
        let dimensions = resString.components(separatedBy: "x")
        guard dimensions.count == 2, let width = Int(dimensions[0]), let height = Int(dimensions[1]) else { return nil }
        
        var colorDepth = 8
        if let cdRange = line.range(of: "color_depth:") {
            let afterCd = line[cdRange.upperBound...]
            if let cdStr = afterCd.components(separatedBy: .whitespaces).first, let cd = Int(cdStr) {
                colorDepth = cd
            }
        }
        
        return DisplayMode(modeId: modeId, width: width, height: height, colorDepth: colorDepth, isScaled: isScaled, isCurrent: isCurrent)
    }

    @objc func refreshMenu() {
        menu.removeAllItems()
        
        if displayplacerPath.isEmpty || !FileManager.default.fileExists(atPath: displayplacerPath) {
            let errorItem = NSMenuItem(title: "displayplacer not found!", action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            menu.addItem(errorItem)
            
            let infoItem = NSMenuItem(title: "Install via Homebrew: brew install displayplacer", action: nil, keyEquivalent: "")
            infoItem.isEnabled = false
            menu.addItem(infoItem)
            
            addStandardMenuItems()
            return
        }

        let displays = parseDisplays()
        if displays.isEmpty {
            let item = NSMenuItem(title: "Display not detected", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            for (index, display) in displays.enumerated() {
                if index > 0 {
                    menu.addItem(NSMenuItem.separator())
                }
                
                // Filter modes (8-bit depth or current)
                let preferredModes = display.modes.filter { $0.colorDepth == 8 || $0.isCurrent }
                let modesToShow = preferredModes.isEmpty ? display.modes : preferredModes
                
                // Sort modes by resolution descending
                let sortedModes = modesToShow.sorted { ($0.width * $0.height) > ($1.width * $1.height) }
                
                // Deduplicate & apply preferences filter
                var seen = Set<String>()
                var uniqueModes: [DisplayMode] = []
                for m in sortedModes {
                    if m.isScaled && !isHiDPIEnabled && !m.isCurrent { continue }
                    if !m.isScaled && !isLoDPIEnabled && !m.isCurrent { continue }
                    
                    let key = "\(m.width)x\(m.height)_\(m.isScaled)"
                    if m.isCurrent || !seen.contains(key) {
                        seen.insert(key)
                        uniqueModes.append(m)
                    }
                }
                
                if isSliderViewEnabled {
                    // Modern Slider Card View (lower res at left, higher res at right)
                    let sliderModes = Array(uniqueModes.reversed())
                    let sliderView = ModernSliderView(
                        frame: NSRect(x: 0, y: 0, width: 280, height: 60),
                        display: display,
                        modes: sliderModes,
                        delegate: self
                    )
                    let containerItem = NSMenuItem()
                    containerItem.view = sliderView
                    menu.addItem(containerItem)
                } else {
                    // List View Mode
                    let titleItem = NSMenuItem(title: "📺 \(display.name)", action: nil, keyEquivalent: "")
                    titleItem.isEnabled = false
                    menu.addItem(titleItem)

                    let hiDpiModes = uniqueModes.filter { $0.isScaled }
                    let loDpiModes = uniqueModes.filter { !$0.isScaled }
                    
                    if !hiDpiModes.isEmpty {
                        for mode in hiDpiModes {
                            let title = "    \(mode.width) × \(mode.height) (HiDPI)"
                            let item = NSMenuItem(title: title, action: #selector(selectMode(_:)), keyEquivalent: "")
                            item.target = self
                            item.representedObject = ["screenId": display.screenId, "modeId": mode.modeId] as [String: Any]
                            if mode.isCurrent {
                                item.state = .on
                            }
                            menu.addItem(item)
                        }
                    }
                    
                    if !hiDpiModes.isEmpty && !loDpiModes.isEmpty {
                        menu.addItem(NSMenuItem.separator())
                    }
                    
                    if !loDpiModes.isEmpty {
                        for mode in loDpiModes {
                            let title = "    \(mode.width) × \(mode.height) (LoDPI)"
                            let item = NSMenuItem(title: title, action: #selector(selectMode(_:)), keyEquivalent: "")
                            item.target = self
                            item.representedObject = ["screenId": display.screenId, "modeId": mode.modeId] as [String: Any]
                            if mode.isCurrent {
                                item.state = .on
                            }
                            menu.addItem(item)
                        }
                    }
                }
            }
        }

        menu.addItem(NSMenuItem.separator())
        addStandardMenuItems()
    }

    func addStandardMenuItems() {
        let refreshItem = NSMenuItem(title: "Refresh Displays", action: #selector(refreshMenu), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        // Preferences Submenu
        let prefItem = NSMenuItem(title: "Preferences", action: nil, keyEquivalent: "")
        let prefMenu = NSMenu()

        // 1. Slider View Switch Row
        let sliderRowView = PreferencesSwitchRow(
            frame: NSRect(x: 0, y: 0, width: 220, height: 32),
            title: "Resolution Slider",
            isOn: isSliderViewEnabled
        ) { [weak self] enabled in
            self?.isSliderViewEnabled = enabled
        }
        let sliderRowItem = NSMenuItem()
        sliderRowItem.view = sliderRowView
        prefMenu.addItem(sliderRowItem)

        prefMenu.addItem(NSMenuItem.separator())

        // 2. HiDPI NSSwitch Row
        let hidpiRowView = PreferencesSwitchRow(
            frame: NSRect(x: 0, y: 0, width: 220, height: 32),
            title: "HiDPI Modes",
            isOn: isHiDPIEnabled
        ) { [weak self] enabled in
            self?.isHiDPIEnabled = enabled
        }
        let hidpiRowItem = NSMenuItem()
        hidpiRowItem.view = hidpiRowView
        prefMenu.addItem(hidpiRowItem)

        // 3. LoDPI NSSwitch Row
        let lodpiRowView = PreferencesSwitchRow(
            frame: NSRect(x: 0, y: 0, width: 220, height: 32),
            title: "LoDPI Modes",
            isOn: isLoDPIEnabled
        ) { [weak self] enabled in
            self?.isLoDPIEnabled = enabled
        }
        let lodpiRowItem = NSMenuItem()
        lodpiRowItem.view = lodpiRowView
        prefMenu.addItem(lodpiRowItem)

        prefItem.submenu = prefMenu
        menu.addItem(prefItem)

        let loginItem = NSMenuItem(title: "Open at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(loginItem)

        let aboutItem = NSMenuItem(title: "About DisplayMenu", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit DisplayMenu", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    func applyMode(screenId: String, modeId: Int) {
        let command = "id:\(screenId) mode:\(modeId)"
        _ = runDisplayPlacer(args: [command])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.refreshMenu()
        }
    }

    @objc func selectMode(_ sender: NSMenuItem) {
        guard let dict = sender.representedObject as? [String: Any],
              let screenId = dict["screenId"] as? String,
              let modeId = dict["modeId"] as? Int else { return }
        
        applyMode(screenId: screenId, modeId: modeId)
    }

    @objc func toggleLaunchAtLogin() {
        let plistPath = NSString(string: "~/Library/LaunchAgents/com.moho.DisplayMenu.plist").expandingTildeInPath
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: plistPath) {
            try? fileManager.removeItem(atPath: plistPath)
        } else {
            let launchAgentsDir = NSString(string: "~/Library/LaunchAgents").expandingTildeInPath
            try? fileManager.createDirectory(atPath: launchAgentsDir, withIntermediateDirectories: true, attributes: nil)
            
            let appPath = Bundle.main.bundlePath + "/Contents/MacOS/DisplayMenu"
            let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
            "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>com.moho.DisplayMenu</string>
                <key>ProgramArguments</key>
                <array>
                    <string>\(appPath)</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
                <key>KeepAlive</key>
                <false/>
            </dict>
            </plist>
            """
            try? plistContent.write(toFile: plistPath, atomically: true, encoding: .utf8)
        }
        refreshMenu()
    }

    func isLaunchAtLoginEnabled() -> Bool {
        let plistPath = NSString(string: "~/Library/LaunchAgents/com.moho.DisplayMenu.plist").expandingTildeInPath
        return FileManager.default.fileExists(atPath: plistPath)
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "DisplayMenu"
        alert.informativeText = """
        Created & Developed by Mohamed Moho

        Lightweight resolution menu bar app for macOS.

        Backend: displayplacer (\(displayplacerPath))
        Designed for quickly switching between HiDPI (Retina) and LoDPI display modes.

        Features:
        • Instant display resolution switching
        • Modern macOS Slider Card UI
        • Native macOS NSSwitch toggles for HiDPI & LoDPI
        • Dynamic screen plug/unplug detection
        • Native macOS Menu Bar UI
        • Launch at Login support
        • Zero background CPU / battery drain
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
