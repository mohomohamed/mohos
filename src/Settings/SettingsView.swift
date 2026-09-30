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
    @State private var viewModeRaw: Int = PreferencesManager.shared.viewMode.rawValue
    @State private var filterModeRaw: Int = PreferencesManager.shared.displayFilterMode.rawValue
    @State private var selectedDNSProfileRaw: Int = PreferencesManager.shared.dnsProfile.rawValue
    @State private var customPrimaryDNS: String = PreferencesManager.shared.customPrimaryDNS
    @State private var customSecondaryDNS: String = PreferencesManager.shared.customSecondaryDNS
    @State private var isAccessibilityGranted: Bool = PermissionManager.shared.isAccessibilityGranted
    @State private var copiedDiagnostics: Bool = false
    
    public init() {}
    
    public var body: some View {
        TabView {
            // MARK: - Tab 1: General Settings
            Form {
                Section(header: Text("Startup & Preferences")) {
                    Toggle("Launch at Login", isOn: $isLaunchAtLogin)
                        .onChange(of: isLaunchAtLogin) { newValue in
                            LoginItemManager.shared.isEnabled = newValue
                        }
                    
                    Picker("Default View Mode", selection: $viewModeRaw) {
                        Text("List View").tag(0)
                        Text("Resolution Slider").tag(1)
                        Text("Text Size Slider").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModeRaw) { newValue in
                        PreferencesManager.shared.viewMode = ViewMode(rawValue: newValue) ?? .slider
                    }
                    
                    Picker("Resolution Filter", selection: $filterModeRaw) {
                        Text("All Modes").tag(0)
                        Text("HiDPI Only").tag(1)
                        Text("LoDPI Only").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: filterModeRaw) { newValue in
                        PreferencesManager.shared.displayFilterMode = DisplayFilterMode(rawValue: newValue) ?? .all
                    }
                }
            }
            .padding(20)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
            
            // MARK: - Tab 2: Screenshots
            Form {
                Section(header: Text("Clipboard Screenshot Workflow")) {
                    Toggle("Clipboard Screenshots (⌘⇧4 → Clipboard)", isOn: $isClipboardScreenshot)
                        .onChange(of: isClipboardScreenshot) { newValue in
                            PreferencesManager.shared.isClipboardScreenshotEnabled = newValue
                        }
                    
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
            
            // MARK: - Tab 3: DNS Shield (Ad & Popup Blocker)
            Form {
                Section(header: Text("Ad-Blocking & Privacy DNS Protection")) {
                    Picker("DNS Provider", selection: $selectedDNSProfileRaw) {
                        ForEach(DNSProfile.allCases) { profile in
                            Text(profile.displayName).tag(profile.rawValue)
                        }
                    }
                    .onChange(of: selectedDNSProfileRaw) { newValue in
                        if let profile = DNSProfile(rawValue: newValue) {
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
                        Text("Protection Details:")
                        Spacer()
                        Text(DNSProfile(rawValue: selectedDNSProfileRaw)?.subtitle ?? "")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .padding(20)
            .tabItem {
                Label("DNS Shield", systemImage: "shield.checkerboard")
            }
            
            // MARK: - Tab 4: Diagnostics
            Form {
                Section(header: Text("System & Diagnostics")) {
                    HStack {
                        Text("mohos Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("macOS Version")
                        Spacer()
                        Text(ProcessInfo.processInfo.operatingSystemVersionString).foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Bundled Engine")
                        Spacer()
                        Text(DisplayManager.shared.isEngineAvailable() ? "Active (\(DisplayManager.shared.displayplacerPath))" : "Missing").foregroundColor(.secondary)
                    }
                    
                    Button(copiedDiagnostics ? "✓ Copied to Clipboard!" : "Copy Diagnostics Summary") {
                        copyDiagnosticsToClipboard()
                    }
                }
            }
            .padding(20)
            .tabItem {
                Label("Diagnostics", systemImage: "waveform.path.ecg")
            }
            
            // MARK: - Tab 5: About
            VStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)
                
                Text("mohos")
                    .font(.title)
                    .bold()
                
                Text("Created & Developed by Mohamed Moho")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Lightweight native macOS utility for display management, zero-file clipboard screenshots, and DNS ad-blocking.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                
                Link("View on GitHub (github.com/mohomohamed/mohos)", destination: URL(string: "https://github.com/mohomohamed/mohos")!)
                    .font(.footnote)
            }
            .padding(20)
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 490, height: 280)
        .onReceive(NotificationCenter.default.publisher(for: .accessibilityPermissionDidChange)) { _ in
            self.isAccessibilityGranted = PermissionManager.shared.isAccessibilityGranted
        }
        .onReceive(NotificationCenter.default.publisher(for: .dnsProfileDidChange)) { _ in
            self.selectedDNSProfileRaw = PreferencesManager.shared.dnsProfile.rawValue
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
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 260),
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
