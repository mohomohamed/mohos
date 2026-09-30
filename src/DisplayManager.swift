//
//  DisplayManager.swift
//  mohos
//
//  Created & Developed by Mohamed Moho
//  Copyright © 2026 Mohamed Moho. All rights reserved.
//

import AppKit
import Foundation

public final class DisplayManager: DisplayEngine {
    public static let shared = DisplayManager()
    
    public private(set) var displayplacerPath: String = ""
    
    public var enginePath: String {
        return displayplacerPath
    }
    
    private init() {
        locateDisplayPlacer()
    }
    
    public func locateDisplayPlacer() {
        // 1. Check Bundled Engine inside mohos.app/Contents/Resources/Tools/displayplacer
        if let bundleToolsPath = Bundle.main.resourcePath?.appending("/Tools/displayplacer"),
           FileManager.default.fileExists(atPath: bundleToolsPath) {
            displayplacerPath = bundleToolsPath
            Log.display.info("Found bundled displayplacer engine at: \(bundleToolsPath, privacy: .public)")
            return
        }
        
        if let bundleUrl = Bundle.main.url(forResource: "displayplacer", withExtension: nil, subdirectory: "Tools"),
           FileManager.default.fileExists(atPath: bundleUrl.path) {
            displayplacerPath = bundleUrl.path
            Log.display.info("Found bundled displayplacer engine via Bundle URL: \(bundleUrl.path, privacy: .public)")
            return
        }

        // 2. System Fallback Paths
        let possiblePaths = [
            "/usr/local/bin/displayplacer",
            "/opt/homebrew/bin/displayplacer",
            "/usr/bin/displayplacer"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                displayplacerPath = path
                Log.display.info("Using system displayplacer engine at: \(path, privacy: .public)")
                return
            }
        }
        
        // 3. Fallback search via which
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = ["displayplacer"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
                displayplacerPath = output
                Log.display.info("Found displayplacer via which: \(output, privacy: .public)")
                return
            }
        } catch {}
        
        displayplacerPath = "/usr/local/bin/displayplacer"
    }
    
    public func isEngineAvailable() -> Bool {
        return !displayplacerPath.isEmpty && FileManager.default.isExecutableFile(atPath: displayplacerPath)
    }
    
    public func runDisplayPlacer(args: [String]) -> String? {
        guard isEngineAvailable() else {
            Log.display.error("Display engine unavailable at path: \(self.displayplacerPath, privacy: .public)")
            return nil
        }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: displayplacerPath)
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            Log.display.error("Error executing displayplacer: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
    
    public func fetchDisplays() -> [DisplayInfo] {
        guard let output = runDisplayPlacer(args: ["list"]) else { return [] }
        
        var displays: [DisplayInfo] = []
        let screenBlocks = output.components(separatedBy: "Persistent screen id: ")
        
        for block in screenBlocks {
            if block.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
            
            let lines = block.components(separatedBy: .newlines)
            guard let screenIdLine = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }
            let screenId = screenIdLine.components(separatedBy: .whitespaces).first ?? screenIdLine
            
            var name = "Display"
            var modes: [DisplayMode] = []
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.starts(with: "Type:") {
                    name = trimmed.replacingOccurrences(of: "Type:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                } else if trimmed.contains("mode ") && trimmed.contains("res:") {
                    if let mode = parseModeLine(trimmed) {
                        modes.append(mode)
                    }
                }
            }
            
            displays.append(DisplayInfo(screenId: screenId, name: name, modes: modes))
        }
        
        return displays
    }
    
    public func parseModeLine(_ line: String) -> DisplayMode? {
        let isCurrent = line.contains("<-- current mode")
        let isScaled = line.contains("scaling:on")
        
        guard let modeRange = line.range(of: "mode ") else { return nil }
        let afterMode = line[modeRange.upperBound...]
        guard let colonIdx = afterMode.firstIndex(of: ":") else { return nil }
        guard let modeId = Int(afterMode[..<colonIdx].trimmingCharacters(in: .whitespaces)) else { return nil }
        
        guard let resRange = line.range(of: "res:") else { return nil }
        let afterRes = line[resRange.upperBound...]
        let resParts = afterRes.components(separatedBy: .whitespaces)
        guard let resString = resParts.first else { return nil }
        let dimensions = resString.components(separatedBy: "x")
        guard dimensions.count == 2, let width = Int(dimensions[0]), let height = Int(dimensions[1]) else { return nil }
        
        var colorDepth = 8
        if let cdRange = line.range(of: "color_depth:") {
            let afterCd = line[cdRange.upperBound...]
            if let cdStr = afterCd.components(separatedBy: .whitespaces).first, let cd = Int(cdStr) {
                colorDepth = cd
            }
        }
        
        return DisplayMode(modeId: modeId, width: width, height: height, colorDepth: colorDepth, isScaled: isScaled, isCurrent: isCurrent)
    }
    
    public func applyMode(screenId: String, modeId: Int, completion: ((Result<Void, DisplayEngineError>) -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, self.isEngineAvailable() else {
                DispatchQueue.main.async {
                    completion?(.failure(.engineNotFound))
                }
                return
            }
            
            let command = "id:\(screenId) mode:\(modeId)"
            let task = Process()
            task.executableURL = URL(fileURLWithPath: self.displayplacerPath)
            task.arguments = [command]
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            do {
                try task.run()
                task.waitUntilExit()
                if task.terminationStatus == 0 {
                    Log.display.info("Successfully applied mode \(modeId) for screen \(screenId, privacy: .public)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        completion?(.success(()))
                    }
                } else {
                    Log.display.error("Failed to apply mode \(modeId) for screen \(screenId, privacy: .public)")
                    DispatchQueue.main.async {
                        completion?(.failure(.commandFailed(output: "Could not apply resolution")))
                    }
                }
            } catch {
                Log.display.error("Error applying mode: \(error.localizedDescription, privacy: .public)")
                DispatchQueue.main.async {
                    completion?(.failure(.commandFailed(output: error.localizedDescription)))
                }
            }
        }
    }
}
