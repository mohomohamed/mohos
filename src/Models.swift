//
//  Models.swift
//  DisplayMenu
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import Foundation

public struct DisplayMode: Equatable {
    public let modeId: Int
    public let width: Int
    public let height: Int
    public let colorDepth: Int
    public let isScaled: Bool
    public let isCurrent: Bool
    
    public init(modeId: Int, width: Int, height: Int, colorDepth: Int, isScaled: Bool, isCurrent: Bool) {
        self.modeId = modeId
        self.width = width
        self.height = height
        self.colorDepth = colorDepth
        self.isScaled = isScaled
        self.isCurrent = isCurrent
    }
}

public struct DisplayInfo: Equatable {
    public let screenId: String
    public let name: String
    public let modes: [DisplayMode]
    
    public init(screenId: String, name: String, modes: [DisplayMode]) {
        self.screenId = screenId
        self.name = name
        self.modes = modes
    }
    
    public var currentMode: DisplayMode? {
        return modes.first(where: { $0.isCurrent })
    }
}

public enum ViewMode: Int {
    case list = 0
    case slider = 1
}

public enum DisplayFilterMode: Int {
    case all = 0
    case hiDPIOnly = 1
    case loDPIOnly = 2
}
