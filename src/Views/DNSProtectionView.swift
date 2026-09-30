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
    private let popUpButton = NSPopUpButton()
    
    public init(width: CGFloat = 340) {
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: 46))
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
            let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
            iconView.image = NSImage(systemSymbolName: "shield.checkerboard", accessibilityDescription: nil)?.withSymbolConfiguration(config)
            iconView.contentTintColor = NSColor.controlAccentColor
        }
        iconView.frame = NSRect(x: 10, y: (40 - 20) / 2, width: 20, height: 20)
        addSubview(iconView)
        
        // Title Label
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.frame = NSRect(x: 36, y: 20, width: containerW - 170, height: 16)
        addSubview(titleLabel)
        
        // Subtitle Label
        subtitleLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        subtitleLabel.textColor = NSColor.secondaryLabelColor
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.frame = NSRect(x: 36, y: 4, width: containerW - 170, height: 15)
        addSubview(subtitleLabel)
        
        // NSPopUpButton for 1-click DNS profile selection
        popUpButton.bezelStyle = .rounded
        popUpButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        popUpButton.frame = NSRect(x: containerW - 135, y: 8, width: 130, height: 24)
        
        for profile in DNSProfile.allCases {
            popUpButton.addItem(withTitle: profile.shortName)
        }
        
        popUpButton.target = self
        popUpButton.action = #selector(popUpSelectionChanged(_:))
        addSubview(popUpButton)
        
        updateUI()
    }
    
    private func updateUI() {
        let currentProfile = PreferencesManager.shared.dnsProfile
        popUpButton.selectItem(at: currentProfile.rawValue)
        
        if currentProfile == .defaultDHCP {
            subtitleLabel.stringValue = "Off · Router/ISP Defaults"
        } else {
            subtitleLabel.stringValue = "\(currentProfile.shortName) · Active"
        }
    }
    
    @objc private func popUpSelectionChanged(_ sender: NSPopUpButton) {
        let selectedIdx = sender.indexOfSelectedItem
        if let profile = DNSProfile(rawValue: selectedIdx) {
            DNSManager.shared.applyProfile(profile) { _ in
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
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: 50))
        let card = DNSProtectionView(width: width)
        card.frame = NSRect(x: 10, y: 3, width: width - 20, height: 44)
        addSubview(card)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
