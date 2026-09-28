//
//  LoginItemManager.swift
//  DisplayMenu
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import AppKit
import ServiceManagement

public final class LoginItemManager {
    public static let shared = LoginItemManager()
    
    private init() {}
    
    public var isEnabled: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            } else {
                let plistPath = NSString(string: "~/Library/LaunchAgents/com.moho.DisplayMenu.plist").expandingTildeInPath
                return FileManager.default.fileExists(atPath: plistPath)
            }
        }
        set {
            setLaunchAtLogin(enabled: newValue)
        }
    }
    
    public func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("[DisplayMenu] SMAppService registration notice: \(error.localizedDescription). Falling back to LaunchAgent.")
                fallbackLaunchAgent(enabled: enabled)
            }
        } else {
            fallbackLaunchAgent(enabled: enabled)
        }
    }
    
    private func fallbackLaunchAgent(enabled: Bool) {
        let plistPath = NSString(string: "~/Library/LaunchAgents/com.moho.DisplayMenu.plist").expandingTildeInPath
        let fileManager = FileManager.default

        if enabled {
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
        } else {
            if fileManager.fileExists(atPath: plistPath) {
                try? fileManager.removeItem(atPath: plistPath)
            }
        }
    }
}
