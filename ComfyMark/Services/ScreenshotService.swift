//
//  ScreenshotService.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import ScreenCaptureKit

protocol ScreenshotProviding {
    /// Function to take a screenshot
    func takeScreenshot() async throws -> CGImage
}

class ScreenshotService: ScreenshotProviding {
    public func takeScreenshot() async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        
        let currentApp = NSRunningApplication.current
        let excludedApps = content.applications.filter { $0.bundleIdentifier == currentApp.bundleIdentifier }
        let display = content.displays.first!

        // Configure what to capture (main display)
        let filter = SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: [])

        // Configure capture settings
        let config = SCStreamConfiguration()
        config.width = Int(display.width)
        config.height = Int(display.height)
        
        // Take screenshot
        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        
        // Save or process the image
        return image
    }
}
