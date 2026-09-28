//
//  SegmentedControlViews.swift
//  DisplayMenu
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import AppKit

public final class ControlRowView: NSView {
    public init(width: CGFloat = 320, delegate: AnyObject, onModeChange: @escaping (DisplayFilterMode) -> Void, onViewChange: @escaping (ViewMode) -> Void) {
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: 40))
        
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.03).cgColor
        
        let label = NSTextField(labelWithString: "Mode")
        label.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        label.textColor = NSColor.labelColor
        label.frame = NSRect(x: 12, y: 12, width: 38, height: 16)
        addSubview(label)
        
        // Display Filter Mode Segmented Control [ HiDPI | LoDPI | All ]
        let currentFilter = PreferencesManager.shared.displayFilterMode
        let filterSeg = NSSegmentedControl(labels: ["All", "HiDPI", "LoDPI"], trackingMode: .selectOne, target: nil, action: nil)
        switch currentFilter {
        case .all: filterSeg.selectedSegment = 0
        case .hiDPIOnly: filterSeg.selectedSegment = 1
        case .loDPIOnly: filterSeg.selectedSegment = 2
        }
        filterSeg.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        filterSeg.frame = NSRect(x: 52, y: 9, width: 130, height: 22)
        addSubview(filterSeg)
        
        // View Mode Segmented Control [ List | Slider ]
        let currentView = PreferencesManager.shared.viewMode
        let viewSeg = NSSegmentedControl(labels: ["List", "Slider"], trackingMode: .selectOne, target: nil, action: nil)
        viewSeg.selectedSegment = (currentView == .slider) ? 1 : 0
        viewSeg.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        viewSeg.frame = NSRect(x: width - 100 - 12, y: 9, width: 100, height: 22)
        addSubview(viewSeg)
        
        // Target Actions
        filterSeg.target = self
        filterSeg.action = #selector(filterSegmentChanged(_:))
        self.onModeChangeClosure = onModeChange
        
        viewSeg.target = self
        viewSeg.action = #selector(viewSegmentChanged(_:))
        self.onViewChangeClosure = onViewChange
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private var onModeChangeClosure: ((DisplayFilterMode) -> Void)?
    private var onViewChangeClosure: ((ViewMode) -> Void)?
    
    @objc private func filterSegmentChanged(_ sender: NSSegmentedControl) {
        let mode: DisplayFilterMode
        switch sender.selectedSegment {
        case 1: mode = .hiDPIOnly
        case 2: mode = .loDPIOnly
        default: mode = .all
        }
        PreferencesManager.shared.displayFilterMode = mode
        onModeChangeClosure?(mode)
    }
    
    @objc private func viewSegmentChanged(_ sender: NSSegmentedControl) {
        let mode: ViewMode = (sender.selectedSegment == 1) ? .slider : .list
        PreferencesManager.shared.viewMode = mode
        onViewChangeClosure?(mode)
    }
}

public final class ControlRowContainerItemView: NSView {
    public init(width: CGFloat = 320, onModeChange: @escaping (DisplayFilterMode) -> Void, onViewChange: @escaping (ViewMode) -> Void) {
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: 46))
        let row = ControlRowView(
            width: width - 20,
            delegate: self,
            onModeChange: onModeChange,
            onViewChange: onViewChange
        )
        row.frame = NSRect(x: 10, y: 3, width: width - 20, height: 40)
        addSubview(row)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
