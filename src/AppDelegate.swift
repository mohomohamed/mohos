//
//  AppDelegate.swift
//  DisplayMenu
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import AppKit
import Foundation

public final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    public var statusItem: NSStatusItem!
    public var menu: NSMenu!
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Status Bar Item
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

        // Register Notification Observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshMenu),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshMenu),
            name: .preferencesDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshMenu),
            name: .accessibilityPermissionDidChange,
            object: nil
        )

        // Start Screenshot Shortcut Interceptor
        ScreenshotShortcutManager.shared.start()

        // Build Initial Menu
        refreshMenu()
    }

    @objc public func refreshMenu() {
        menu.removeAllItems()
        let menuWidth: CGFloat = 320
        
        let displayplacerPath = DisplayManager.shared.displayplacerPath
        if displayplacerPath.isEmpty || !FileManager.default.fileExists(atPath: displayplacerPath) {
            let errorItem = NSMenuItem(title: "displayplacer not found!", action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            menu.addItem(errorItem)
            
            let infoItem = NSMenuItem(title: "Install via Homebrew: brew install displayplacer", action: nil, keyEquivalent: "")
            infoItem.isEnabled = false
            menu.addItem(infoItem)
            
            menu.addItem(NSMenuItem.separator())
            addScreenshotAndStandardMenuItems(menuWidth: menuWidth)
            return
        }

        let displays = DisplayManager.shared.fetchDisplays()
        if displays.isEmpty {
            let item = NSMenuItem(title: "Display not detected", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            for (index, display) in displays.enumerated() {
                if index > 0 {
                    menu.addItem(NSMenuItem.separator())
                }
                
                // 1. Display Header Card
                let headerContainer = DisplayHeaderContainerItemView(display: display, width: menuWidth)
                let headerItem = NSMenuItem()
                headerItem.view = headerContainer
                menu.addItem(headerItem)
                
                // Filter modes (8-bit depth or current)
                let preferredModes = display.modes.filter { $0.colorDepth == 8 || $0.isCurrent }
                let modesToShow = preferredModes.isEmpty ? display.modes : preferredModes
                let sortedModes = modesToShow.sorted { ($0.width * $0.height) > ($1.width * $1.height) }
                
                // Apply Preferences Filter (HiDPI / LoDPI / All)
                let filterMode = PreferencesManager.shared.displayFilterMode
                var seen = Set<String>()
                var uniqueModes: [DisplayMode] = []
                for m in sortedModes {
                    if filterMode == .hiDPIOnly && !m.isScaled && !m.isCurrent { continue }
                    if filterMode == .loDPIOnly && m.isScaled && !m.isCurrent { continue }
                    
                    let key = "\(m.width)x\(m.height)_\(m.isScaled)"
                    if m.isCurrent || !seen.contains(key) {
                        seen.insert(key)
                        uniqueModes.append(m)
                    }
                }
                
                // 2. Control Row: Mode Filter & View Segmented Controls
                let controlRow = ControlRowContainerItemView(
                    width: menuWidth,
                    onModeChange: { [weak self] _ in self?.refreshMenu() },
                    onViewChange: { [weak self] _ in self?.refreshMenu() }
                )
                let controlItem = NSMenuItem()
                controlItem.view = controlRow
                menu.addItem(controlItem)
                
                // 3. Resolutions Display (List or Control Center Slider)
                if PreferencesManager.shared.viewMode == .slider {
                    let sliderModes = Array(uniqueModes.reversed())
                    let sliderContainer = ControlCenterSliderContainerItemView(
                        display: display,
                        modes: sliderModes,
                        width: menuWidth,
                        onApplyMode: { [weak self] screenId, modeId in
                            DisplayManager.shared.applyMode(screenId: screenId, modeId: modeId) {
                                self?.refreshMenu()
                            }
                        }
                    )
                    let sliderMenuItem = NSMenuItem()
                    sliderMenuItem.view = sliderContainer
                    menu.addItem(sliderMenuItem)
                } else {
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
        addScreenshotAndStandardMenuItems(menuWidth: menuWidth)
    }

    private func addScreenshotAndStandardMenuItems(menuWidth: CGFloat) {
        // Screenshot Workflow Card
        let screenshotContainer = ScreenshotWorkflowContainerItemView(
            width: menuWidth,
            onToggle: { enabled in
                PreferencesManager.shared.isClipboardScreenshotEnabled = enabled
            }
        )
        let screenshotItem = NSMenuItem()
        screenshotItem.view = screenshotContainer
        menu.addItem(screenshotItem)

        menu.addItem(NSMenuItem.separator())

        // Refresh Displays
        let refreshItem = NSMenuItem(title: "Refresh Displays", action: #selector(refreshMenu), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        // Open at Login
        let loginItem = NSMenuItem(title: "Open at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = LoginItemManager.shared.isEnabled ? .on : .off
        menu.addItem(loginItem)

        // About DisplayMenu
        let aboutItem = NSMenuItem(title: "About DisplayMenu", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        // Quit DisplayMenu
        let quitItem = NSMenuItem(title: "Quit DisplayMenu", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func selectMode(_ sender: NSMenuItem) {
        guard let dict = sender.representedObject as? [String: Any],
              let screenId = dict["screenId"] as? String,
              let modeId = dict["modeId"] as? Int else { return }
        
        DisplayManager.shared.applyMode(screenId: screenId, modeId: modeId) { [weak self] in
            self?.refreshMenu()
        }
    }

    @objc private func toggleLaunchAtLogin() {
        LoginItemManager.shared.isEnabled = !LoginItemManager.shared.isEnabled
        refreshMenu()
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "DisplayMenu"
        alert.informativeText = """
        Created & Developed by Mohamed Moho

        Lightweight native resolution & screenshot menu bar utility for macOS.

        Backend: displayplacer (\(DisplayManager.shared.displayplacerPath))
        Designed for quickly switching between HiDPI (Retina) and LoDPI display modes.

        Features:
        • Instant display resolution switching
        • ⌘⇧4 → Clipboard Screenshot Workflow (no files created on disk)
        • macOS Control Center Capsule Slider View
        • Segmented HiDPI / LoDPI & List / Slider controls
        • Dynamic screen plug/unplug detection
        • Native macOS Menu Bar UI
        • Launch at Login support (SMAppService)
        • Zero background CPU / battery drain
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quitApp() {
        ScreenshotShortcutManager.shared.stop()
        NSApplication.shared.terminate(nil)
    }
}
