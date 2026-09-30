//
//  DisplayHeaderView.swift
//  mohos
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import AppKit

public final class DisplayHeaderView: NSView {
    private let iconView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let statusDot = NSTextField(labelWithString: "●")
    private let resolutionLabel = NSTextField(labelWithString: "")
    
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
            let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
            iconView.image = NSImage(systemSymbolName: "display", accessibilityDescription: nil)?.withSymbolConfiguration(config)
            iconView.contentTintColor = NSColor.controlAccentColor
        }
        iconView.frame = NSRect(x: 10, y: (h - 20) / 2, width: 20, height: 20)
        addSubview(iconView)
        
        // Display Name Label
        nameLabel.stringValue = display.name
        nameLabel.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        nameLabel.textColor = NSColor.labelColor
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.frame = NSRect(x: 36, y: h / 2 + 1, width: w - 75, height: 16)
        addSubview(nameLabel)
        
        // Subtle Active Status Dot
        statusDot.font = NSFont.systemFont(ofSize: 9, weight: .bold)
        statusDot.textColor = NSColor.systemGreen
        statusDot.alignment = .right
        statusDot.frame = NSRect(x: w - 30, y: h / 2 + 1, width: 18, height: 16)
        addSubview(statusDot)
        
        // Active Resolution Subtitle (e.g. "1440 × 900 · LoDPI")
        if let currentMode = display.currentMode {
            let modeType = currentMode.isScaled ? "HiDPI" : "LoDPI"
            resolutionLabel.stringValue = "\(currentMode.width) × \(currentMode.height) · \(modeType)"
        } else {
            resolutionLabel.stringValue = "Connected"
        }
        resolutionLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        resolutionLabel.textColor = NSColor.secondaryLabelColor
        resolutionLabel.lineBreakMode = .byTruncatingTail
        resolutionLabel.frame = NSRect(x: 36, y: h / 2 - 15, width: w - 46, height: 14)
        addSubview(resolutionLabel)
    }
}

public final class DisplayHeaderContainerItemView: NSView {
    public init(display: DisplayInfo, width: CGFloat = 340) {
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: 46))
        let header = DisplayHeaderView(
            frame: NSRect(x: 10, y: 3, width: width - 20, height: 40),
            display: display
        )
        addSubview(header)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
