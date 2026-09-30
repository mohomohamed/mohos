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
                if let img = NSImage(systemSymbolName: "display", accessibilityDescription: "mohos")?.withSymbolConfiguration(config) {
                    img.isTemplate = true
                    button.image = img
                }
            } else {
                button.title = "🖥"
            }
        }

        menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        statusItem.menu = menu

        // Register Notification Observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshMenu),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // Start Screenshot Shortcut Interceptor
        ScreenshotShortcutManager.shared.start()

        // Build Initial Menu
        refreshMenu()
    }

    @objc public func refreshMenu() {
        menu.removeAllItems()
        let menuWidth: CGFloat = 340
        
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
            // Header for DISPLAY section
            let displaySection = NSMenuItem(title: "DISPLAY", action: nil, keyEquivalent: "")
            displaySection.isEnabled = false
            menu.addItem(displaySection)

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
                
                // 2. Resolution Submenu
                let currentMode = display.modes.first { $0.isCurrent }
                let currentResString = currentMode != nil ? "\(currentMode!.width) × \(currentMode!.height)" : "Select"
                let resSubmenuItem = NSMenuItem(title: "    Resolution (\(currentResString))", action: nil, keyEquivalent: "")
                let resSubmenu = NSMenu()
                resSubmenu.autoenablesItems = false
                
                let hiDpiModes = uniqueModes.filter { $0.isScaled }
                let loDpiModes = uniqueModes.filter { !$0.isScaled }
                
                if !hiDpiModes.isEmpty {
                    let hiDpiHeader = NSMenuItem(title: "HiDPI (Retina)", action: nil, keyEquivalent: "")
                    hiDpiHeader.isEnabled = false
                    resSubmenu.addItem(hiDpiHeader)
                    
                    for mode in hiDpiModes {
                        let title = "\(mode.width) × \(mode.height)"
                        let item = NSMenuItem(title: title, action: #selector(selectMode(_:)), keyEquivalent: "")
                        item.target = self
                        item.representedObject = ["screenId": display.screenId, "modeId": mode.modeId] as [String: Any]
                        if mode.isCurrent {
                            item.state = .on
                        }
                        resSubmenu.addItem(item)
                    }
                }
                
                if !hiDpiModes.isEmpty && !loDpiModes.isEmpty {
                    resSubmenu.addItem(NSMenuItem.separator())
                }
                
                if !loDpiModes.isEmpty {
                    let loDpiHeader = NSMenuItem(title: "Standard (LoDPI)", action: nil, keyEquivalent: "")
                    loDpiHeader.isEnabled = false
                    resSubmenu.addItem(loDpiHeader)
                    
                    for mode in loDpiModes {
                        let title = "\(mode.width) × \(mode.height)"
                        let item = NSMenuItem(title: title, action: #selector(selectMode(_:)), keyEquivalent: "")
                        item.target = self
                        item.representedObject = ["screenId": display.screenId, "modeId": mode.modeId] as [String: Any]
                        if mode.isCurrent {
                            item.state = .on
                        }
                        resSubmenu.addItem(item)
                    }
                }
                
                resSubmenuItem.submenu = resSubmenu
                menu.addItem(resSubmenuItem)
            }
        }

        menu.addItem(NSMenuItem.separator())
        addScreenshotAndStandardMenuItems(menuWidth: menuWidth)
        menu.update()
    }

    private func addScreenshotAndStandardMenuItems(menuWidth: CGFloat) {
        // Section Header for QUICK TOOLS
        let quickToolsSection = NSMenuItem(title: "QUICK TOOLS", action: nil, keyEquivalent: "")
        quickToolsSection.isEnabled = false
        menu.addItem(quickToolsSection)

        // DNS Shield Card
        let dnsContainer = DNSProtectionContainerItemView(width: menuWidth)
        let dnsItem = NSMenuItem()
        dnsItem.view = dnsContainer
        menu.addItem(dnsItem)

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

        // Settings… (⌘,)
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        // Quit mohos (⌘Q)
        let quitItem = NSMenuItem(title: "Quit mohos", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
    }

    @objc public func openSettings() {
        SettingsWindowManager.shared.showSettings()
    }

    @objc public func selectMode(_ sender: NSMenuItem) {
        guard let dict = sender.representedObject as? [String: Any],
              let screenId = dict["screenId"] as? String,
              let modeId = dict["modeId"] as? Int else { return }
        
        DisplayManager.shared.applyMode(screenId: screenId, modeId: modeId) { [weak self] _ in
            self?.refreshMenu()
        }
    }

    @objc public func selectDNSProfile(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? Int,
              let profile = DNSProfile(rawValue: rawValue) else { return }
        
        if profile == .custom && (PreferencesManager.shared.customPrimaryDNS.isEmpty || PreferencesManager.shared.customPrimaryDNS == "1.1.1.1") {
            SettingsWindowManager.shared.showSettings()
        } else {
            DNSManager.shared.applyProfile(profile) { [weak self] _ in
                self?.refreshMenu()
            }
        }
    }

    @objc public func toggleLaunchAtLogin() {
        LoginItemManager.shared.isEnabled = !LoginItemManager.shared.isEnabled
        refreshMenu()
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "mohos"
        alert.informativeText = """
        Created & Developed by Mohamed Moho

        Lightweight native resolution & screenshot menu bar utility for macOS.

        Backend: displayplacer (\(DisplayManager.shared.displayplacerPath))
        Designed for quickly switching between HiDPI (Retina) and LoDPI display modes.

        Features:
        • Instant display resolution switching
        • ⌘⇧4 → Clipboard Screenshot Workflow (zero disk writes)
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

    public func menuWillOpen(_ menu: NSMenu) {
        PermissionManager.shared.startPermissionPollingIfNeeded()
        refreshMenu()
    }

    @objc private func quitApp() {
        ScreenshotShortcutManager.shared.stop()
        NSApplication.shared.terminate(nil)
    }
}
