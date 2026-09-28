//
//  Logging.swift
//  mohos
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import Foundation
import OSLog

public enum Log {
    public static let app = Logger(subsystem: "com.moho.mohos", category: "App")
    public static let display = Logger(subsystem: "com.moho.mohos", category: "Display")
    public static let screenshot = Logger(subsystem: "com.moho.mohos", category: "Screenshot")
    public static let permissions = Logger(subsystem: "com.moho.mohos", category: "Permissions")
}
