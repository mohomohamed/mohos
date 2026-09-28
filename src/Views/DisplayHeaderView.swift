//
//  DisplayHeaderView.swift
//  DisplayMenu
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import AppKit

public final class DisplayHeaderView: NSView {
    private let iconView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let statusLabel = NSTextField(labelWithString: "")
    
    public init(frame: NSRect, display: DisplayInfo) {
        super.init(frame: frame)
        setupUI(display: display)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupUI(display: DisplayInfo) {
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.04).cgColor
        
        let w = frame.width
        let h = frame.height
        
        // SF Symbol Monitor Icon
        if #available(macOS 11.0, *) {
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            iconView.image = NSImage(systemSymbolName: "display", accessibilityDescription: nil)?.withSymbolConfiguration(config)
            iconView.contentTintColor = NSColor.controlAccentColor
        }
        iconView.frame = NSRect(x: 12, y: (h - 22) / 2, width: 22, height: 22)
        addSubview(iconView)
        
        // Display Name Label
        nameLabel.stringValue = display.name
        nameLabel.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        nameLabel.textColor = NSColor.labelColor
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.frame = NSRect(x: 42, y: h / 2 + 1, width: w - 54, height: 17)
        addSubview(nameLabel)
        
        // Active Resolution Status (e.g., "1280 × 720 · Active")
        if let currentMode = display.currentMode {
            let modeType = currentMode.isScaled ? "HiDPI" : "LoDPI"
            statusLabel.stringValue = "\(currentMode.width) × \(currentMode.height) (\(modeType)) · Active"
        } else {
            statusLabel.stringValue = "Connected"
        }
        statusLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        statusLabel.textColor = NSColor.secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail
        statusLabel.frame = NSRect(x: 42, y: h / 2 - 16, width: w - 54, height: 15)
        addSubview(statusLabel)
    }
}

public final class DisplayHeaderContainerItemView: NSView {
    public init(display: DisplayInfo, width: CGFloat = 320) {
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: 50))
        let header = DisplayHeaderView(
            frame: NSRect(x: 10, y: 4, width: width - 20, height: 42),
            display: display
        )
        addSubview(header)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
