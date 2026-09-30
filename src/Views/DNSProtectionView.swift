//
//  DNSProtectionView.swift
//  mohos
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import AppKit

public final class DNSProtectionView: NSView {
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "DNS Shield")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private var toggleSwitch: NSControl?
    
    public init(width: CGFloat = 340) {
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: 42))
        setupUI(width: width)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dnsProfileChanged),
            name: .dnsProfileDidChange,
            object: nil
        )
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupUI(width: CGFloat) {
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.04).cgColor
        
        let containerW = width - 20
        
        // SF Symbol Shield Icon
        if #available(macOS 11.0, *) {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            iconView.image = NSImage(systemSymbolName: "shield.checkerboard", accessibilityDescription: nil)?.withSymbolConfiguration(config)
            iconView.contentTintColor = NSColor.controlAccentColor
        }
        iconView.frame = NSRect(x: 10, y: (40 - 20) / 2, width: 20, height: 20)
        addSubview(iconView)
        
        // Title Label
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.frame = NSRect(x: 36, y: 20, width: containerW - 90, height: 16)
        addSubview(titleLabel)
        
        // Subtitle Label (e.g. "AdGuard DNS" or "Off · DHCP")
        subtitleLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        subtitleLabel.textColor = NSColor.secondaryLabelColor
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.frame = NSRect(x: 36, y: 4, width: containerW - 90, height: 15)
        addSubview(subtitleLabel)
        
        // NSSwitch Toggle
        let currentProfile = PreferencesManager.shared.dnsProfile
        let isEnabled = (currentProfile != .defaultDHCP)
        if #available(macOS 10.15, *) {
            let sw = NSSwitch(frame: NSRect(x: containerW - 48, y: (40 - 24) / 2, width: 38, height: 24))
            sw.state = isEnabled ? .on : .off
            sw.target = self
            sw.action = #selector(switchToggled(_:))
            toggleSwitch = sw
            addSubview(sw)
        } else {
            let btn = NSButton(checkboxWithTitle: "", target: nil, action: nil)
            btn.state = isEnabled ? .on : .off
            btn.frame = NSRect(x: containerW - 30, y: (40 - 20) / 2, width: 20, height: 20)
            btn.target = self
            btn.action = #selector(switchToggled(_:))
            toggleSwitch = btn
            addSubview(btn)
        }
        
        updateUI()
    }
    
    private func updateUI() {
        let currentProfile = PreferencesManager.shared.dnsProfile
        let isEnabled = (currentProfile != .defaultDHCP)
        
        if #available(macOS 10.15, *), let sw = toggleSwitch as? NSSwitch {
            sw.state = isEnabled ? .on : .off
        } else if let btn = toggleSwitch as? NSButton {
            btn.state = isEnabled ? .on : .off
        }
        
        if currentProfile == .defaultDHCP {
            subtitleLabel.stringValue = "Off · Router Defaults"
        } else {
            subtitleLabel.stringValue = currentProfile.shortName
        }
    }
    
    @objc private func switchToggled(_ sender: Any) {
        let isOn: Bool
        if #available(macOS 10.15, *), let sw = sender as? NSSwitch {
            isOn = (sw.state == .on)
        } else if let btn = sender as? NSButton {
            isOn = (btn.state == .on)
        } else {
            return
        }
        
        if isOn {
            let targetProfile: DNSProfile = (PreferencesManager.shared.dnsProfile == .defaultDHCP) ? .adGuard : PreferencesManager.shared.dnsProfile
            DNSManager.shared.applyProfile(targetProfile) { _ in
                self.updateUI()
            }
        } else {
            DNSManager.shared.applyProfile(.defaultDHCP) { _ in
                self.updateUI()
            }
        }
    }
    
    @objc private func dnsProfileChanged() {
        updateUI()
    }
}

public final class DNSProtectionContainerItemView: NSView {
    public init(width: CGFloat = 340) {
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: 46))
        let card = DNSProtectionView(width: width)
        card.frame = NSRect(x: 10, y: 3, width: width - 20, height: 40)
        addSubview(card)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
