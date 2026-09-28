//
//  DisplayEngine.swift
//  mohos
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import Foundation

public enum DisplayEngineError: Error, LocalizedError {
    case engineNotFound
    case commandFailed(output: String)
    case invalidOutput
    
    public var errorDescription: String? {
        switch self {
        case .engineNotFound:
            return "Display engine executable not found."
        case .commandFailed(let output):
            return "Display engine command failed: \(output)"
        case .invalidOutput:
            return "Failed to parse display engine output."
        }
    }
}

public protocol DisplayEngine {
    var enginePath: String { get }
    func isEngineAvailable() -> Bool
    func fetchDisplays() -> [DisplayInfo]
    func applyMode(screenId: String, modeId: Int, completion: ((Result<Void, DisplayEngineError>) -> Void)?)
}
