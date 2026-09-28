//
//  ScreenshotWorkflowView.swift
//  DisplayMenu
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import AppKit

public final class ScreenshotWorkflowView: NSView {
    private let titleLabel = NSTextField(labelWithString: "Clipboard Screenshots")
    private let subtitleLabel = NSTextField(labelWithString: "⌘⇧4 → Clipboard")
    private var toggleSwitch: NSControl?
    private let permissionNoticeView = NSView()
    private let permissionLabel = NSTextField(labelWithString: "Accessibility permission required")
    private let grantButton = NSButton(title: "Grant Permission", target: nil, action: nil)
    
    public init(width: CGFloat = 320, onToggle: @escaping (Bool) -> Void) {
        let isPermissionGranted = PermissionManager.shared.isAccessibilityGranted
        let viewHeight: CGFloat = isPermissionGranted ? 44.0 : 72.0
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
        
        // Title
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.frame = NSRect(x: 12, y: isPermissionGranted ? 22 : 48, width: containerW - 65, height: 16)
        addSubview(titleLabel)
        
        // Subtitle with native keyboard glyphs
        subtitleLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        subtitleLabel.textColor = NSColor.secondaryLabelColor
        subtitleLabel.frame = NSRect(x: 12, y: isPermissionGranted ? 6 : 32, width: containerW - 65, height: 15)
        addSubview(subtitleLabel)
        
        // NSSwitch Toggle
        let isEnabled = PreferencesManager.shared.isClipboardScreenshotEnabled
        if #available(macOS 10.15, *) {
            let sw = NSSwitch(frame: NSRect(x: containerW - 48, y: isPermissionGranted ? (44 - 24) / 2 : (72 - 24) / 2 - 12, width: 38, height: 24))
            sw.state = isEnabled ? .on : .off
            sw.target = self
            sw.action = #selector(switchToggled(_:))
            toggleSwitch = sw
            addSubview(sw)
        } else {
            let btn = NSButton(checkboxWithTitle: "", target: nil, action: nil)
            btn.state = isEnabled ? .on : .off
            btn.frame = NSRect(x: containerW - 30, y: isPermissionGranted ? (44 - 20) / 2 : (72 - 20) / 2 - 12, width: 20, height: 20)
            btn.target = self
            btn.action = #selector(switchToggled(_:))
            toggleSwitch = btn
            addSubview(btn)
        }
        
        self.onToggleClosure = onToggle
        
        // Permission Missing Row (Always added, visibility toggled dynamically)
        permissionNoticeView.frame = NSRect(x: 0, y: 0, width: containerW, height: 28)
        permissionNoticeView.isHidden = isPermissionGranted
        
        permissionLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        permissionLabel.textColor = NSColor.systemOrange
        permissionLabel.frame = NSRect(x: 12, y: 6, width: containerW - 130, height: 16)
        permissionNoticeView.addSubview(permissionLabel)
        
        grantButton.bezelStyle = .inline
        grantButton.font = NSFont.systemFont(ofSize: 10, weight: .bold)
        grantButton.frame = NSRect(x: containerW - 120, y: 4, width: 110, height: 20)
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
        titleLabel.frame = NSRect(x: 12, y: isGranted ? 22 : 48, width: containerW - 65, height: 16)
        subtitleLabel.frame = NSRect(x: 12, y: isGranted ? 6 : 32, width: containerW - 65, height: 15)
        
        if #available(macOS 10.15, *), let sw = toggleSwitch as? NSSwitch {
            sw.frame = NSRect(x: containerW - 48, y: isGranted ? (44 - 24) / 2 : (72 - 24) / 2 - 12, width: 38, height: 24)
        } else if let btn = toggleSwitch as? NSButton {
            btn.frame = NSRect(x: containerW - 30, y: isGranted ? (44 - 20) / 2 : (72 - 20) / 2 - 12, width: 20, height: 20)
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
    public init(width: CGFloat = 320, onToggle: @escaping (Bool) -> Void) {
        let isPermissionGranted = PermissionManager.shared.isAccessibilityGranted
        let totalH: CGFloat = isPermissionGranted ? 50.0 : 78.0
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: totalH))
        
        let card = ScreenshotWorkflowView(
            width: width,
            onToggle: onToggle
        )
        card.frame = NSRect(x: 10, y: 3, width: width - 20, height: isPermissionGranted ? 44.0 : 72.0)
        addSubview(card)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
