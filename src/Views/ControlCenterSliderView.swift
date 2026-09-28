//
//  ControlCenterSliderView.swift
//  DisplayMenu
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import AppKit
import QuartzCore

public final class ModernControlCenterSliderView: NSView {
    public var modes: [DisplayMode] = []
    public var screenId: String = ""
    public var onApplyMode: ((String, Int) -> Void)?
    
    private var currentIndex: Int = 0 {
        didSet {
            updateLayout()
        }
    }
    
    private let fillView = NSView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")
    private let leftIconView = NSImageView()
    
    public override init(frame: NSRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    public convenience init(frame: NSRect, display: DisplayInfo, modes: [DisplayMode], onApplyMode: @escaping (String, Int) -> Void) {
        self.init(frame: frame)
        configure(display: display, modes: modes, onApplyMode: onApplyMode)
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.08).cgColor
        
        // Accent Fill Track
        fillView.wantsLayer = true
        fillView.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.35).cgColor
        fillView.layer?.cornerRadius = 14
        addSubview(fillView)
        
        // SF Symbol Monitor Icon
        if #available(macOS 11.0, *) {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            leftIconView.image = NSImage(systemSymbolName: "display", accessibilityDescription: nil)?.withSymbolConfiguration(config)
            leftIconView.contentTintColor = NSColor.labelColor.withAlphaComponent(0.85)
            addSubview(leftIconView)
        }
        
        // Title Label
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        addSubview(titleLabel)
        
        // Detail Resolution Label
        detailLabel.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        detailLabel.textColor = NSColor.secondaryLabelColor
        detailLabel.alignment = .right
        addSubview(detailLabel)
    }
    
    public func configure(display: DisplayInfo, modes: [DisplayMode], onApplyMode: @escaping (String, Int) -> Void) {
        self.modes = modes
        self.screenId = display.screenId
        self.onApplyMode = onApplyMode
        self.titleLabel.stringValue = display.name
        
        let initialIdx = modes.firstIndex(where: { $0.isCurrent }) ?? (modes.count - 1)
        self.currentIndex = max(0, min(initialIdx, modes.count - 1))
        updateLayout()
    }
    
    public override func layout() {
        super.layout()
        updateLayout()
    }
    
    private func updateLayout() {
        let w = bounds.width
        let h = bounds.height
        guard w > 0 && h > 0 else { return }
        
        let fraction = modes.count > 1 ? CGFloat(currentIndex) / CGFloat(modes.count - 1) : 1.0
        let minFillWidth: CGFloat = 32.0
        let fillWidth = max(minFillWidth, w * fraction)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fillView.frame = NSRect(x: 0, y: 0, width: fillWidth, height: h)
        CATransaction.commit()
        
        leftIconView.frame = NSRect(x: 12, y: (h - 18) / 2, width: 18, height: 18)
        titleLabel.frame = NSRect(x: 34, y: (h - 16) / 2, width: max(50, w - 200), height: 16)
        
        if currentIndex >= 0 && currentIndex < modes.count {
            let m = modes[currentIndex]
            let activeTag = m.isCurrent ? " • Active" : ""
            detailLabel.stringValue = "\(m.width)×\(m.height) (\(m.isScaled ? "HiDPI" : "LoDPI"))\(activeTag)"
        }
        detailLabel.frame = NSRect(x: w - 150 - 12, y: (h - 16) / 2, width: 150, height: 16)
    }
    
    private func updateFromLocation(_ point: CGPoint, isFinal: Bool) {
        guard !modes.isEmpty else { return }
        let fraction = max(0.0, min(1.0, point.x / bounds.width))
        let targetIndex = Int(round(fraction * CGFloat(modes.count - 1)))
        
        if targetIndex != currentIndex {
            currentIndex = targetIndex
        }
        
        if isFinal {
            let m = modes[currentIndex]
            if !m.isCurrent {
                onApplyMode?(screenId, m.modeId)
            }
        }
    }
    
    public override func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        updateFromLocation(loc, isFinal: false)
    }
    
    public override func mouseDragged(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        updateFromLocation(loc, isFinal: false)
    }
    
    public override func mouseUp(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        updateFromLocation(loc, isFinal: true)
    }
}

public final class ControlCenterSliderContainerItemView: NSView {
    public init(display: DisplayInfo, modes: [DisplayMode], width: CGFloat = 320, onApplyMode: @escaping (String, Int) -> Void) {
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: 50))
        
        let slider = ModernControlCenterSliderView(
            frame: NSRect(x: 10, y: 4, width: width - 20, height: 42),
            display: display,
            modes: modes,
            onApplyMode: onApplyMode
        )
        addSubview(slider)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
