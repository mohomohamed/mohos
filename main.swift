//
//  main.swift
//  DisplayMenu
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import AppKit
import Foundation
import QuartzCore

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

// MARK: - Modern macOS Control Center Capsule Slider View
class ModernControlCenterSliderView: NSView {
    var modes: [DisplayMode] = []
    var screenId: String = ""
    weak var delegate: AppDelegate?
    
    private var currentIndex: Int = 0 {
        didSet {
            updateLayout()
        }
    }
    
    private let fillView = NSView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")
    private let leftIconView = NSImageView()
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    convenience init(frame: NSRect, display: DisplayInfo, modes: [DisplayMode], delegate: AppDelegate) {
        self.init(frame: frame)
        configure(display: display, modes: modes, delegate: delegate)
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = 16
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.08).cgColor
        
        // Control Center accent fill track
        fillView.wantsLayer = true
        fillView.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.35).cgColor
        fillView.layer?.cornerRadius = 16
        addSubview(fillView)
        
        // Left SF Symbol Icon
        if #available(macOS 11.0, *) {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            leftIconView.image = NSImage(systemSymbolName: "display", accessibilityDescription: nil)?.withSymbolConfiguration(config)
            leftIconView.contentTintColor = NSColor.labelColor.withAlphaComponent(0.85)
            addSubview(leftIconView)
        }
        
        // Title Label (e.g. Built-in Display)
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        addSubview(titleLabel)
        
        // Resolution Detail Label (e.g. 1920×1080 HiDPI)
        detailLabel.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        detailLabel.textColor = NSColor.secondaryLabelColor
        detailLabel.alignment = .right
        addSubview(detailLabel)
    }
    
    func configure(display: DisplayInfo, modes: [DisplayMode], delegate: AppDelegate) {
        self.modes = modes
        self.screenId = display.screenId
        self.delegate = delegate
        self.titleLabel.stringValue = display.name
        
        let initialIdx = modes.firstIndex(where: { $0.isCurrent }) ?? (modes.count - 1)
        self.currentIndex = max(0, min(initialIdx, modes.count - 1))
        updateLayout()
    }
    
    override func layout() {
        super.layout()
        updateLayout()
    }
    
    private func updateLayout() {
        let w = bounds.width
        let h = bounds.height
        guard w > 0 && h > 0 else { return }
        
        let fraction = modes.count > 1 ? CGFloat(currentIndex) / CGFloat(modes.count - 1) : 1.0
        let minFillWidth: CGFloat = 36.0
        let fillWidth = max(minFillWidth, w * fraction)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fillView.frame = NSRect(x: 0, y: 0, width: fillWidth, height: h)
        CATransaction.commit()
        
        leftIconView.frame = NSRect(x: 14, y: (h - 18) / 2, width: 18, height: 18)
        titleLabel.frame = NSRect(x: 38, y: (h - 16) / 2, width: max(50, w - 210), height: 16)
        
        if currentIndex >= 0 && currentIndex < modes.count {
            let m = modes[currentIndex]
            let activeTag = m.isCurrent ? " • Active" : ""
            detailLabel.stringValue = "\(m.width)×\(m.height) (\(m.isScaled ? "HiDPI" : "LoDPI"))\(activeTag)"
        }
        detailLabel.frame = NSRect(x: w - 160 - 14, y: (h - 16) / 2, width: 160, height: 16)
    }
    
    private func updateFromLocation(_ point: CGPoint, isFinal: Bool) {
        guard !modes.isEmpty else { return }
        let fraction = max(0.0, min(1.0, point.x / bounds.width))
        let targetIndex = Int(round(fraction * CGFloat(modes.count - 1)))
        
        if targetIndex != currentIndex {
            currentIndex = targetIndex
        }
        
        if isFinal {
            let m = modes[currentIndex]
            if !m.isCurrent {
                delegate?.applyMode(screenId: screenId, modeId: m.modeId)
            }
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        updateFromLocation(loc, isFinal: false)
    }
    
    override func mouseDragged(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        updateFromLocation(loc, isFinal: false)
    }
    
    override func mouseUp(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        updateFromLocation(loc, isFinal: true)
    }
}

// MARK: - Slider Menu Item Container (Padding Wrapper)
class SliderContainerItemView: NSView {
    init(display: DisplayInfo, modes: [DisplayMode], delegate: AppDelegate) {
        super.init(frame: NSRect(x: 0, y: 0, width: 320, height: 54))
        
        let slider = ModernControlCenterSliderView(
            frame: NSRect(x: 10, y: 5, width: 300, height: 44),
            display: display,
            modes: modes,
            delegate: delegate
        )
        addSubview(slider)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
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
                    // Modern macOS Control Center Capsule Slider View
                    let sliderModes = Array(uniqueModes.reversed())
                    let containerView = SliderContainerItemView(
                        display: display,
                        modes: sliderModes,
                        delegate: self
                    )
                    let containerItem = NSMenuItem()
                    containerItem.view = containerView
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
        • macOS Sonoma/Sequoia Control Center Capsule Slider
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
