//
//  PreferencesManager.swift
//  DisplayMenu
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import Foundation

public final class PreferencesManager {
    public static let shared = PreferencesManager()
    
    private enum Keys {
        static let clipboardScreenshot = "IsClipboardScreenshotEnabled"
        static let viewMode = "ViewMode"
        static let displayFilterMode = "DisplayFilterMode"
        static let dnsProfile = "DNSProfile"
        static let customPrimaryDNS = "CustomPrimaryDNS"
        static let customSecondaryDNS = "CustomSecondaryDNS"
    }
    
    private init() {}
    
    public var isClipboardScreenshotEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: Keys.clipboardScreenshot) == nil {
                return true // Default ON
            }
            return UserDefaults.standard.bool(forKey: Keys.clipboardScreenshot)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.clipboardScreenshot)
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        }
    }
    
    public var viewMode: ViewMode {
        get {
            if UserDefaults.standard.object(forKey: Keys.viewMode) == nil {
                return .slider
            }
            let raw = UserDefaults.standard.integer(forKey: Keys.viewMode)
            return ViewMode(rawValue: raw) ?? .slider
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.viewMode)
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        }
    }
    
    public var displayFilterMode: DisplayFilterMode {
        get {
            let raw = UserDefaults.standard.integer(forKey: Keys.displayFilterMode)
            return DisplayFilterMode(rawValue: raw) ?? .all
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.displayFilterMode)
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        }
    }
    
    public var dnsProfile: DNSProfile {
        get {
            let raw = UserDefaults.standard.integer(forKey: Keys.dnsProfile)
            return DNSProfile(rawValue: raw) ?? .defaultDHCP
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.dnsProfile)
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        }
    }
    
    public var customPrimaryDNS: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.customPrimaryDNS) ?? "1.1.1.1"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.customPrimaryDNS)
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        }
    }
    
    public var customSecondaryDNS: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.customSecondaryDNS) ?? "1.0.0.1"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.customSecondaryDNS)
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        }
    }
}

public extension Notification.Name {
    static let preferencesDidChange = Notification.Name("DisplayMenu.preferencesDidChange")
}
