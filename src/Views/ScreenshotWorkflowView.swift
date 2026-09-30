//
//  ScreenshotWorkflowView.swift
//  mohos
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import AppKit

public final class ScreenshotWorkflowView: NSView {
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "Screenshots → Clipboard")
    private let subtitleLabel = NSTextField(labelWithString: "⌘⇧4 copies to clipboard")
    private var toggleSwitch: NSControl?
    private let permissionNoticeView = NSView()
    private let permissionLabel = NSTextField(labelWithString: "⚠ Accessibility permission needed")
    private let grantButton = NSButton(title: "Grant", target: nil, action: nil)
    
    public init(width: CGFloat = 340, onToggle: @escaping (Bool) -> Void) {
        let isPermissionGranted = PermissionManager.shared.isAccessibilityGranted
        let viewHeight: CGFloat = isPermissionGranted ? 42.0 : 68.0
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: viewHeight))
        
        setupUI(width: width, isPermissionGranted: isPermissionGranted, onToggle: onToggle)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(permissionDidChangeNotification),
            name: .accessibilityPermissionDidChange,
            object: nil
        )
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupUI(width: CGFloat, isPermissionGranted: Bool, onToggle: @escaping (Bool) -> Void) {
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.04).cgColor
        
        let containerW = width - 20
        
        // SF Symbol Camera Icon
        if #available(macOS 11.0, *) {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            iconView.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: nil)?.withSymbolConfiguration(config)
            iconView.contentTintColor = NSColor.controlAccentColor
        }
        iconView.frame = NSRect(x: 10, y: isPermissionGranted ? (40 - 20) / 2 : (40 - 20) / 2 + 26, width: 20, height: 20)
        addSubview(iconView)
        
        // Title
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.frame = NSRect(x: 36, y: isPermissionGranted ? 20 : 46, width: containerW - 90, height: 16)
        addSubview(titleLabel)
        
        // Subtitle with native keyboard glyphs
        subtitleLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        subtitleLabel.textColor = NSColor.secondaryLabelColor
        subtitleLabel.frame = NSRect(x: 36, y: isPermissionGranted ? 4 : 30, width: containerW - 90, height: 15)
        addSubview(subtitleLabel)
        
        // NSSwitch Toggle
        let isEnabled = PreferencesManager.shared.isClipboardScreenshotEnabled
        if #available(macOS 10.15, *) {
            let sw = NSSwitch(frame: NSRect(x: containerW - 48, y: isPermissionGranted ? (40 - 24) / 2 : (40 - 24) / 2 + 26, width: 38, height: 24))
            sw.state = isEnabled ? .on : .off
            sw.target = self
            sw.action = #selector(switchToggled(_:))
            toggleSwitch = sw
            addSubview(sw)
        } else {
            let btn = NSButton(checkboxWithTitle: "", target: nil, action: nil)
            btn.state = isEnabled ? .on : .off
            btn.frame = NSRect(x: containerW - 30, y: isPermissionGranted ? (40 - 20) / 2 : (40 - 20) / 2 + 26, width: 20, height: 20)
            btn.target = self
            btn.action = #selector(switchToggled(_:))
            toggleSwitch = btn
            addSubview(btn)
        }
        
        self.onToggleClosure = onToggle
        
        // Permission Missing Notice (Only rendered if permission missing)
        permissionNoticeView.frame = NSRect(x: 0, y: 0, width: containerW, height: 26)
        permissionNoticeView.isHidden = isPermissionGranted
        
        permissionLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        permissionLabel.textColor = NSColor.systemOrange
        permissionLabel.frame = NSRect(x: 36, y: 4, width: containerW - 120, height: 16)
        permissionNoticeView.addSubview(permissionLabel)
        
        grantButton.bezelStyle = .inline
        grantButton.font = NSFont.systemFont(ofSize: 10, weight: .bold)
        grantButton.frame = NSRect(x: containerW - 75, y: 3, width: 65, height: 20)
        grantButton.target = self
        grantButton.action = #selector(grantPermissionClicked)
        permissionNoticeView.addSubview(grantButton)
        
        addSubview(permissionNoticeView)
    }
    
    private var onToggleClosure: ((Bool) -> Void)?
    
    @objc private func permissionDidChangeNotification() {
        let isGranted = PermissionManager.shared.isAccessibilityGranted
        permissionNoticeView.isHidden = isGranted
        
        let containerW = bounds.width > 0 ? bounds.width : (340 - 20)
        iconView.frame = NSRect(x: 10, y: isGranted ? (40 - 20) / 2 : (40 - 20) / 2 + 26, width: 20, height: 20)
        titleLabel.frame = NSRect(x: 36, y: isGranted ? 20 : 46, width: containerW - 90, height: 16)
        subtitleLabel.frame = NSRect(x: 36, y: isGranted ? 4 : 30, width: containerW - 90, height: 15)
        
        if #available(macOS 10.15, *), let sw = toggleSwitch as? NSSwitch {
            sw.frame = NSRect(x: containerW - 48, y: isGranted ? (40 - 24) / 2 : (40 - 24) / 2 + 26, width: 38, height: 24)
        } else if let btn = toggleSwitch as? NSButton {
            btn.frame = NSRect(x: containerW - 30, y: isGranted ? (40 - 20) / 2 : (40 - 20) / 2 + 26, width: 20, height: 20)
        }
    }
    
    @objc private func switchToggled(_ sender: Any) {
        if #available(macOS 10.15, *), let sw = sender as? NSSwitch {
            onToggleClosure?(sw.state == .on)
        } else if let btn = sender as? NSButton {
            onToggleClosure?(btn.state == .on)
        }
    }
    
    @objc private func grantPermissionClicked() {
        PermissionManager.shared.openAccessibilitySettings()
    }
}

public final class ScreenshotWorkflowContainerItemView: NSView {
    public init(width: CGFloat = 340, onToggle: @escaping (Bool) -> Void) {
        let isPermissionGranted = PermissionManager.shared.isAccessibilityGranted
        let totalH: CGFloat = isPermissionGranted ? 46.0 : 72.0
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: totalH))
        
        let card = ScreenshotWorkflowView(
            width: width,
            onToggle: onToggle
        )
        card.frame = NSRect(x: 10, y: 3, width: width - 20, height: isPermissionGranted ? 40.0 : 66.0)
        addSubview(card)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
