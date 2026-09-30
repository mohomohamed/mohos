//
//  SettingsView.swift
//  mohos
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import SwiftUI
import AppKit

public struct SettingsView: View {
    @State private var isLaunchAtLogin: Bool = LoginItemManager.shared.isEnabled
    @State private var isClipboardScreenshot: Bool = PreferencesManager.shared.isClipboardScreenshotEnabled
    @State private var isDNSShieldEnabled: Bool = PreferencesManager.shared.dnsProfile != .defaultDHCP
    @State private var viewModeRaw: Int = PreferencesManager.shared.viewMode.rawValue
    @State private var filterModeRaw: Int = PreferencesManager.shared.displayFilterMode.rawValue
    @State private var selectedDNSProfileRaw: Int = PreferencesManager.shared.dnsProfile.rawValue
    @State private var customPrimaryDNS: String = PreferencesManager.shared.customPrimaryDNS
    @State private var customSecondaryDNS: String = PreferencesManager.shared.customSecondaryDNS
    @State private var isAccessibilityGranted: Bool = PermissionManager.shared.isAccessibilityGranted
    @State private var copiedDiagnostics: Bool = false
    @State private var refreshStatusMessage: String? = nil
    
    public init() {}
    
    public var body: some View {
        TabView {
            // MARK: - Tab 1: General
            Form {
                Section(header: Text("Startup & Integration")) {
                    Toggle("Launch mohos at login", isOn: $isLaunchAtLogin)
                        .onChange(of: isLaunchAtLogin) { newValue in
                            LoginItemManager.shared.isEnabled = newValue
                        }
                    
                    HStack {
                        Text("Application Version")
                        Spacer()
                        Text("mohos 1.0.0 (Native)").foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("About")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("mohos is a lightweight native macOS menu bar utility.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Created & Developed by Mohamed Moho")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Link("GitHub: github.com/mohomohamed/mohos", destination: URL(string: "https://github.com/mohomohamed/mohos")!)
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(20)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
            
            // MARK: - Tab 2: Display
            Form {
                Section(header: Text("Resolution Filtering")) {
                    Picker("Display Modes", selection: $filterModeRaw) {
                        Text("All Modes").tag(0)
                        Text("HiDPI Only").tag(1)
                        Text("LoDPI Only").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: filterModeRaw) { newValue in
                        PreferencesManager.shared.displayFilterMode = DisplayFilterMode(rawValue: newValue) ?? .all
                        NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
                    }
                }
                
                Section(header: Text("Resolution Presentation")) {
                    Picker("Presentation Style", selection: $viewModeRaw) {
                        Text("Submenu List").tag(0)
                        Text("Capsule Slider").tag(1)
                        Text("Text Size Slider").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModeRaw) { newValue in
                        PreferencesManager.shared.viewMode = ViewMode(rawValue: newValue) ?? .slider
                        NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
                    }
                }
                
                Section(header: Text("Display Detection")) {
                    HStack {
                        Button("Refresh Displays Now") {
                            _ = DisplayManager.shared.fetchDisplays()
                            NotificationCenter.default.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)
                            refreshStatusMessage = "Displays refreshed"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                refreshStatusMessage = nil
                            }
                        }
                        if let msg = refreshStatusMessage {
                            Spacer()
                            Text(msg)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .padding(20)
            .tabItem {
                Label("Display", systemImage: "display")
            }
            
            // MARK: - Tab 3: DNS Shield
            Form {
                Section(header: Text("Ad & Tracker Blocking")) {
                    Toggle("Enable DNS Shield", isOn: $isDNSShieldEnabled)
                        .onChange(of: isDNSShieldEnabled) { enabled in
                            if enabled {
                                let profile = DNSProfile(rawValue: selectedDNSProfileRaw) ?? .adGuard
                                if profile == .defaultDHCP {
                                    selectedDNSProfileRaw = DNSProfile.adGuard.rawValue
                                    DNSManager.shared.applyProfile(.adGuard)
                                } else {
                                    DNSManager.shared.applyProfile(profile)
                                }
                            } else {
                                DNSManager.shared.applyProfile(.defaultDHCP)
                            }
                        }
                    
                    Picker("DNS Provider", selection: $selectedDNSProfileRaw) {
                        ForEach(DNSProfile.allCases) { profile in
                            Text(profile.displayName).tag(profile.rawValue)
                        }
                    }
                    .onChange(of: selectedDNSProfileRaw) { newValue in
                        if let profile = DNSProfile(rawValue: newValue) {
                            isDNSShieldEnabled = (profile != .defaultDHCP)
                            DNSManager.shared.applyProfile(profile)
                        }
                    }
                    
                    if selectedDNSProfileRaw == DNSProfile.custom.rawValue {
                        TextField("Primary DNS IP", text: $customPrimaryDNS)
                            .onSubmit {
                                PreferencesManager.shared.customPrimaryDNS = customPrimaryDNS
                                DNSManager.shared.applyProfile(.custom)
                            }
                        TextField("Secondary DNS IP", text: $customSecondaryDNS)
                            .onSubmit {
                                PreferencesManager.shared.customSecondaryDNS = customSecondaryDNS
                                DNSManager.shared.applyProfile(.custom)
                            }
                    }
                    
                    HStack {
                        Text("Current Status:")
                        Spacer()
                        if PreferencesManager.shared.dnsProfile != .defaultDHCP {
                            Text("🛡 Active (\(PreferencesManager.shared.dnsProfile.shortName))")
                                .foregroundColor(.green)
                                .bold()
                        } else {
                            Text("Off (Default DHCP)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(20)
            .tabItem {
                Label("DNS Shield", systemImage: "shield.checkerboard")
            }
            
            // MARK: - Tab 4: Screenshots
            Form {
                Section(header: Text("Clipboard Screenshot Workflow")) {
                    Toggle("Copy screenshots directly to clipboard", isOn: $isClipboardScreenshot)
                        .onChange(of: isClipboardScreenshot) { newValue in
                            PreferencesManager.shared.isClipboardScreenshotEnabled = newValue
                            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
                        }
                    
                    HStack {
                        Text("Global Shortcut")
                        Spacer()
                        Text("⌘ ⇧ 4").bold().foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Permissions")) {
                    HStack {
                        Text("Accessibility Permission:")
                        Spacer()
                        if isAccessibilityGranted {
                            Text("✓ Allowed")
                                .foregroundColor(.green)
                                .bold()
                        } else {
                            Text("● Permission Required")
                                .foregroundColor(.orange)
                                .bold()
                        }
                    }
                    
                    if !isAccessibilityGranted {
                        Button("Open System Settings") {
                            PermissionManager.shared.openAccessibilitySettings()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding(20)
            .tabItem {
                Label("Screenshots", systemImage: "camera")
            }
            
            // MARK: - Tab 5: Advanced
            Form {
                Section(header: Text("Diagnostics & Backend")) {
                    HStack {
                        Text("macOS Version")
                        Spacer()
                        Text(ProcessInfo.processInfo.operatingSystemVersionString).foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Displayplacer Binary")
                        Spacer()
                        Text(DisplayManager.shared.isEngineAvailable() ? "Active" : "Not Found").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Binary Path")
                        Spacer()
                        Text(DisplayManager.shared.displayplacerPath).font(.caption).foregroundColor(.secondary)
                    }
                    
                    Button(copiedDiagnostics ? "✓ Copied to Clipboard!" : "Copy Diagnostics Summary") {
                        copyDiagnosticsToClipboard()
                    }
                }
            }
            .padding(20)
            .tabItem {
                Label("Advanced", systemImage: "gearshape.2")
            }
        }
        .frame(width: 520, height: 320)
        .onReceive(NotificationCenter.default.publisher(for: .accessibilityPermissionDidChange)) { _ in
            self.isAccessibilityGranted = PermissionManager.shared.isAccessibilityGranted
        }
        .onReceive(NotificationCenter.default.publisher(for: .dnsProfileDidChange)) { _ in
            self.selectedDNSProfileRaw = PreferencesManager.shared.dnsProfile.rawValue
            self.isDNSShieldEnabled = PreferencesManager.shared.dnsProfile != .defaultDHCP
        }
    }
    
    private func copyDiagnosticsToClipboard() {
        let text = """
        mohos Diagnostics Summary:
        - Version: 1.0.0
        - macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        - Display Engine: \(DisplayManager.shared.displayplacerPath) (Available: \(DisplayManager.shared.isEngineAvailable()))
        - Accessibility Granted: \(PermissionManager.shared.isAccessibilityGranted)
        - Shortcut Event Tap: \(ScreenshotShortcutManager.shared.isRunning)
        - DNS Profile: \(PreferencesManager.shared.dnsProfile.displayName)
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copiedDiagnostics = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            copiedDiagnostics = false
        }
    }
}

public final class SettingsWindowManager {
    public static let shared = SettingsWindowManager()
    private var windowController: NSWindowController?
    
    private init() {}
    
    public func showSettings() {
        if windowController == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 320),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "mohos Settings"
            window.contentViewController = hostingController
            window.center()
            window.isReleasedWhenClosed = false
            
            windowController = NSWindowController(window: window)
        }
        
        windowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
