//
//  SavingService.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/5/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

protocol SavingProviding {
    func comfyAppSupportURL() throws -> URL
    func saveCGImage(_ image: CGImage, name: String, type: UTType) throws -> URL
}

final class SavingService: SavingProviding {
    
    /// Public Facing Function to get the ComfyMark ApplicationSupport Folder
    public func comfyAppSupportURL() throws -> URL {
        let fm = FileManager.default
        let base = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let appID = Bundle.main.bundleIdentifier ?? "com.yourcompany.ComfyMark"
        let dir = base.appendingPathComponent(appID, isDirectory: true)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    /// Save CGImage to Application Support Folder
    public func saveCGImage(_ image: CGImage, name: String, type: UTType = .png) throws -> URL {
        let dir = try self.comfyAppSupportURL()
        let url = dir.appendingPathComponent(name).appendingPathExtension(type.preferredFilenameExtension ?? "png")
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil) else {
            throw NSError(domain: "ComfyMark", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create image destination"])
        }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else {
            throw NSError(domain: "ComfyMark", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to write image"])
        }
        return url
    }
}
