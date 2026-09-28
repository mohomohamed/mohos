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

class ResolutionSliderView: NSView {
    let titleLabel: NSTextField
    let slider: NSSlider
    let resLabel: NSTextField
    let modes: [DisplayMode]
    let screenId: String
    weak var delegate: AppDelegate?

    init(frame: NSRect, display: DisplayInfo, modes: [DisplayMode], delegate: AppDelegate) {
        self.modes = modes
        self.screenId = display.screenId
        self.delegate = delegate
        
        self.titleLabel = NSTextField(labelWithString: "📺 \(display.name)")
        self.titleLabel.font = NSFont.boldSystemFont(ofSize: 12)

        let maxVal = Double(max(0, modes.count - 1))
        self.slider = NSSlider(value: 0, minValue: 0, maxValue: maxVal, target: nil, action: nil)
        self.slider.numberOfTickMarks = max(2, modes.count)
        self.slider.allowsTickMarkValuesOnly = true
        self.slider.isContinuous = true
        
        let currentIdx = modes.firstIndex(where: { $0.isCurrent }) ?? 0
        self.slider.integerValue = currentIdx
        
        self.resLabel = NSTextField(labelWithString: "")
        self.resLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        self.resLabel.alignment = .center
        
        super.init(frame: frame)
        
        titleLabel.frame = NSRect(x: 16, y: frame.height - 24, width: frame.width - 32, height: 18)
        slider.frame = NSRect(x: 16, y: 30, width: frame.width - 32, height: 22)
        resLabel.frame = NSRect(x: 16, y: 8, width: frame.width - 32, height: 16)
        
        addSubview(titleLabel)
        addSubview(slider)
        addSubview(resLabel)
        
        slider.target = self
        slider.action = #selector(sliderChanged(_:))
        
        updateLabel(for: currentIdx)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func updateLabel(for index: Int) {
        guard index >= 0 && index < modes.count else { return }
        let m = modes[index]
        let currentTag = m.isCurrent ? " (Current)" : ""
        resLabel.stringValue = "\(m.width) × \(m.height) (\(m.isScaled ? "HiDPI" : "LoDPI"))\(currentTag)"
    }

    @objc func sliderChanged(_ sender: NSSlider) {
        let idx = sender.integerValue
        updateLabel(for: idx)
        
        if let event = NSApp.currentEvent, event.type == .leftMouseUp {
            guard idx >= 0 && idx < modes.count else { return }
            let mode = modes[idx]
            if !mode.isCurrent {
                delegate?.applyMode(screenId: screenId, modeId: mode.modeId)
            }
        }
    }
}

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
                
                // Preferred modes filter (8-bit or current)
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
                    // Slider View Mode: lower resolution at index 0 (left), higher resolution at max index (right)
                    let sliderModes = Array(uniqueModes.reversed())
                    let sliderView = ResolutionSliderView(
                        frame: NSRect(x: 0, y: 0, width: 270, height: 78),
                        display: display,
                        modes: sliderModes,
                        delegate: self
                    )
                    let sliderMenuItem = NSMenuItem()
                    sliderMenuItem.view = sliderView
                    menu.addItem(sliderMenuItem)
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

        // 1. View Mode Button (List vs Slider)
        let modeTitle = isSliderViewEnabled ? "Switch to List View" : "Switch to Slider View"
        let viewModeItem = NSMenuItem(title: modeTitle, action: #selector(toggleViewMode), keyEquivalent: "")
        viewModeItem.target = self
        prefMenu.addItem(viewModeItem)

        prefMenu.addItem(NSMenuItem.separator())

        // 2. HiDPI Switch / Toggle
        let hidpiItem = NSMenuItem(title: "Enable HiDPI Modes", action: #selector(toggleHiDPI), keyEquivalent: "")
        hidpiItem.target = self
        hidpiItem.state = isHiDPIEnabled ? .on : .off
        prefMenu.addItem(hidpiItem)

        // 3. LoDPI Switch / Toggle
        let lodpiItem = NSMenuItem(title: "Enable LoDPI Modes", action: #selector(toggleLoDPI), keyEquivalent: "")
        lodpiItem.target = self
        lodpiItem.state = isLoDPIEnabled ? .on : .off
        prefMenu.addItem(lodpiItem)

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

    @objc func toggleViewMode() {
        isSliderViewEnabled = !isSliderViewEnabled
    }

    @objc func toggleHiDPI() {
        isHiDPIEnabled = !isHiDPIEnabled
    }

    @objc func toggleLoDPI() {
        isLoDPIEnabled = !isLoDPIEnabled
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
        • Resolution Slider & List UI modes
        • HiDPI & LoDPI toggles
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
