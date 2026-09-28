//
//  PermissionManager.swift
//  DisplayMenu
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import AppKit
import ApplicationServices

public final class PermissionManager {
    public static let shared = PermissionManager()
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    public var isAccessibilityGranted: Bool {
        return AXIsProcessTrusted()
    }
    
    @discardableResult
    public func checkAndPromptAccessibility(promptIfNeeded: Bool = false) -> Bool {
        if promptIfNeeded {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }
        return AXIsProcessTrusted()
    }
    
    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        } else if let url = URL(string: "https://support.apple.com/guide/mac-help/allow-accessibility-apps-to-access-your-mac-mh43185/mac") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func applicationDidBecomeActive() {
        NotificationCenter.default.post(name: .accessibilityPermissionDidChange, object: nil)
    }
}

public extension Notification.Name {
    static let accessibilityPermissionDidChange = Notification.Name("DisplayMenu.accessibilityPermissionDidChange")
}
