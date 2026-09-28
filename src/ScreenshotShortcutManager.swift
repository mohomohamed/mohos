//
//  ScreenshotShortcutManager.swift
//  DisplayMenu
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import AppKit
import CoreGraphics

public final class ScreenshotShortcutManager {
    public static let shared = ScreenshotShortcutManager()
    
    // Magic uint64 tag used to mark synthesized events and prevent infinite loop recursion
    private static let magicEventTag: Int64 = 0x5343524E // 'SCRN'
    private static let keycodeFour: CGKeyCode = 0x15     // Keycode for '4'
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) public var isRunning: Bool = false
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesOrPermissionsChanged),
            name: .preferencesDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesOrPermissionsChanged),
            name: .accessibilityPermissionDidChange,
            object: nil
        )
    }
    
    public func start() {
        guard PreferencesManager.shared.isClipboardScreenshotEnabled else {
            stop()
            return
        }
        
        guard PermissionManager.shared.isAccessibilityGranted else {
            stop()
            return
        }
        
        if isRunning { return }
        
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: ScreenshotShortcutManager.eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("[DisplayMenu] Error: Failed to create CGEventTap for ⌘⇧4 shortcut translation.")
            return
        }
        
        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.isRunning = true
        print("[DisplayMenu] ScreenshotShortcutManager started: ⌘⇧4 -> ⌃⌘⇧4 active.")
    }
    
    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
        }
        eventTap = nil
        runLoopSource = nil
        isRunning = false
        print("[DisplayMenu] ScreenshotShortcutManager stopped.")
    }
    
    @objc private func preferencesOrPermissionsChanged() {
        if PreferencesManager.shared.isClipboardScreenshotEnabled && PermissionManager.shared.isAccessibilityGranted {
            start()
        } else {
            stop()
        }
    }
    
    // CGEventTap callback function
    private static let eventTapCallback: CGEventTapCallBack = { proxy, type, event, userInfo in
        // Re-enable tap if disabled by system timeout
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let info = userInfo {
                let manager = Unmanaged<ScreenshotShortcutManager>.fromOpaque(info).takeUnretainedValue()
                if let tap = manager.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
            }
            return Unmanaged.passUnretained(event)
        }
        
        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }
        
        // 1. Check if event is tagged with our magic tag (synthesized event -> pass through directly!)
        let tag = event.getIntegerValueField(.eventSourceUserData)
        if tag == ScreenshotShortcutManager.magicEventTag {
            return Unmanaged.passUnretained(event)
        }
        
        // 2. Check keycode for '4' (0x15)
        let keycode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        guard keycode == ScreenshotShortcutManager.keycodeFour else {
            return Unmanaged.passUnretained(event)
        }
        
        // 3. Check flags: Command + Shift without Control or Alt/Option
        let flags = event.flags
        let isCmdShift = flags.contains(.maskCommand) && flags.contains(.maskShift)
        let isControlOrAlt = flags.contains(.maskControl) || flags.contains(.maskAlternate)
        
        if isCmdShift && !isControlOrAlt {
            // Target ⌘⇧4 detected!
            if type == .keyDown {
                // Synthesize ⌃⌘⇧4 (Control + Command + Shift + 4) -> Native macOS Clipboard Screenshot!
                ScreenshotShortcutManager.synthesizeClipboardScreenshot()
            }
            // Suppress original ⌘⇧4 event so no desktop file is created
            return nil
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private static func synthesizeClipboardScreenshot() {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keycodeFour, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keycodeFour, keyDown: false) else {
            return
        }
        
        let targetFlags: CGEventFlags = [.maskCommand, .maskShift, .maskControl]
        
        keyDown.flags = targetFlags
        keyDown.setIntegerValueField(.eventSourceUserData, value: magicEventTag)
        
        keyUp.flags = targetFlags
        keyUp.setIntegerValueField(.eventSourceUserData, value: magicEventTag)
        
        // Post synthesized ⌃⌘⇧4 events
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
