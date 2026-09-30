//
//  DNSManager.swift
//  mohos
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import Foundation
import AppKit

public enum DNSProfile: Int, CaseIterable, Identifiable {
    case defaultDHCP = 0
    case adGuard = 1
    case adGuardFamily = 2
    case cloudflareSecurity = 3
    case cloudflare = 4
    case quad9 = 5
    case google = 6
    case custom = 7
    
    public var id: Int { rawValue }
    
    public var displayName: String {
        switch self {
        case .defaultDHCP: return "Default (DHCP)"
        case .adGuard: return "AdGuard DNS (Ads & Popups)"
        case .adGuardFamily: return "AdGuard Family"
        case .cloudflareSecurity: return "Cloudflare Security (1.1.1.2)"
        case .cloudflare: return "Cloudflare Speed (1.1.1.1)"
        case .quad9: return "Quad9 (Threat Protection)"
        case .google: return "Google Public DNS"
        case .custom: return "Custom DNS"
        }
    }
    
    public var shortName: String {
        switch self {
        case .defaultDHCP: return "DHCP Default"
        case .adGuard: return "AdGuard DNS"
        case .adGuardFamily: return "AdGuard Family"
        case .cloudflareSecurity: return "Cloudflare Sec"
        case .cloudflare: return "Cloudflare 1.1.1.1"
        case .quad9: return "Quad9"
        case .google: return "Google DNS"
        case .custom: return "Custom"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .defaultDHCP: return "Automatic router/ISP DNS"
        case .adGuard: return "Blocks ads, trackers & malicious popups"
        case .adGuardFamily: return "Blocks ads, popups & adult content"
        case .cloudflareSecurity: return "Blocks malware, phishing & ad networks"
        case .cloudflare: return "Ultra-fast DNS with privacy"
        case .quad9: return "Enterprise threat protection"
        case .google: return "High-performance public DNS"
        case .custom: return "User-configured primary & secondary DNS"
        }
    }
    
    public var primaryDNS: String {
        switch self {
        case .defaultDHCP: return ""
        case .adGuard: return "94.140.14.14"
        case .adGuardFamily: return "94.140.14.15"
        case .cloudflareSecurity: return "1.1.1.2"
        case .cloudflare: return "1.1.1.1"
        case .quad9: return "9.9.9.9"
        case .google: return "8.8.8.8"
        case .custom: return PreferencesManager.shared.customPrimaryDNS
        }
    }
    
    public var secondaryDNS: String {
        switch self {
        case .defaultDHCP: return ""
        case .adGuard: return "94.140.15.15"
        case .adGuardFamily: return "94.140.15.16"
        case .cloudflareSecurity: return "1.0.0.2"
        case .cloudflare: return "1.0.0.1"
        case .quad9: return "149.112.112.112"
        case .google: return "8.8.4.4"
        case .custom: return PreferencesManager.shared.customSecondaryDNS
        }
    }
}

public final class DNSManager {
    public static let shared = DNSManager()
    
    private init() {}
    
    /// Returns a list of active network services on macOS (e.g. ["Wi-Fi", "USB 10/100/1000 LAN"])
    public func getNetworkServices() -> [String] {
        let task = Process()
        task.launchPath = "/usr/sbin/networksetup"
        task.arguments = ["-listallnetworkservices"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                return lines.filter { line in
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    return !trimmed.isEmpty &&
                           !trimmed.contains("*") &&
                           !trimmed.contains("An asterisk")
                }
            }
        } catch {
            print("[DNSManager] Error fetching network services: \(error)")
        }
        return ["Wi-Fi"]
    }
    
    /// Gets current DNS servers for a network service
    public func getCurrentDNSServers(for service: String = "Wi-Fi") -> [String] {
        let task = Process()
        task.launchPath = "/usr/sbin/networksetup"
        task.arguments = ["-getdnsservers", service]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty && !$0.contains("There aren't") }
                return lines
            }
        } catch {
            print("[DNSManager] Error getting DNS servers: \(error)")
        }
        return []
    }
    
    /// Applies a DNS Profile to network services
    public func applyProfile(_ profile: DNSProfile, customPrimary: String? = nil, customSecondary: String? = nil, completion: ((Bool) -> Void)? = nil) {
        let services = getNetworkServices()
        let targetService = services.contains("Wi-Fi") ? "Wi-Fi" : (services.first ?? "Wi-Fi")
        
        var args = ["-setdnsservers", targetService]
        
        if profile == .defaultDHCP {
            args.append("empty")
        } else if profile == .custom {
            let p = customPrimary ?? PreferencesManager.shared.customPrimaryDNS
            let s = customSecondary ?? PreferencesManager.shared.customSecondaryDNS
            if !p.isEmpty { args.append(p) }
            if !s.isEmpty { args.append(s) }
            if args.count == 2 { args.append("empty") }
        } else {
            let p = profile.primaryDNS
            let s = profile.secondaryDNS
            if !p.isEmpty { args.append(p) }
            if !s.isEmpty { args.append(s) }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.launchPath = "/usr/sbin/networksetup"
            task.arguments = args
            
            do {
                try task.run()
                task.waitUntilExit()
                let success = (task.terminationStatus == 0)
                DispatchQueue.main.async {
                    PreferencesManager.shared.dnsProfile = profile
                    if let p = customPrimary { PreferencesManager.shared.customPrimaryDNS = p }
                    if let s = customSecondary { PreferencesManager.shared.customSecondaryDNS = s }
                    NotificationCenter.default.post(name: .dnsProfileDidChange, object: nil)
                    completion?(success)
                }
            } catch {
                print("[DNSManager] Error applying DNS settings: \(error)")
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
    }
}

public extension Notification.Name {
    static let dnsProfileDidChange = Notification.Name("mohos.dnsProfileDidChange")
}
