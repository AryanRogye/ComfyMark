//
//  ScreenshotService.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//
import AppKit
import ScreenCaptureKit

enum ScreenshotScaleMode {
    case nativePixels              // default
    case logicalPoints             // points * backingScaleFactor
    case percent(Double)           // 0.1 ... 1.0
    case cappedLongestEdge(Int)    // e.g., 3840
}

// MARK: - Protocol
/// Abstraction for capturing a screenshot as a `CGImage`.
///
/// Conformers handle any platform-specific permissions (e.g.,
/// Screen Recording on macOS) and return a bitmap of the current
/// display contents.
protocol ScreenshotProviding {
    /// Captures a screenshot and returns it as a `CGImage`.
    /// - Returns: A `CGImage` of the captured content.
    /// - Throws: An error if the capture fails or permission is denied.
    func takeScreenshot() async -> CGImage?
    /// Captures a screenshot of a specific `NSScreen`.
    func takeScreenshot(of screen: NSScreen) async -> CGImage?
}

// MARK: - Implementation
/// Default implementation backed by ScreenCaptureKit.
///     Fetches shareable content and exclude the current app
///     Selects the primary display
///     Configures stream dimensions to match the display
///     Captures a single `CGImage` via `SCScreenshotManager`
final class ScreenshotService: ScreenshotProviding {
    
    /// Takes a screenshot of the main display using ScreenCaptureKit.
    ///
    /// Notes:
    /// - Requires Screen Recording permission on macOS.
    public func takeScreenshot() async -> CGImage? {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            // Get current app to exclude
            let currentApp = NSRunningApplication.current
            let excludedApps = content.applications.filter { $0.bundleIdentifier == currentApp.bundleIdentifier }
            
            // Use the mouse location to determine which display to capture
            let mouseLocation = NSEvent.mouseLocation
            
            guard let targetScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) else {
                // Fallback to main screen
                guard let mainScreen = NSScreen.main else {
                    throw NSError(domain: "ScreenshotError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No screen available"])
                }
                return try await captureScreen(mainScreen, content: content, excludedApps: excludedApps)
            }
            
            return try await captureScreen(targetScreen, content: content, excludedApps: excludedApps)
        } catch {
            return nil
        }
    }

    public func takeScreenshot(of screen: NSScreen) async -> CGImage? {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            // Get current app to exclude
            let currentApp = NSRunningApplication.current
            let excludedApps = content.applications.filter { $0.bundleIdentifier == currentApp.bundleIdentifier }
            
            return try await captureScreen(screen, content: content, excludedApps: excludedApps)
        } catch {
            return nil
        }
    }
    
    
    private func captureScreen(_ screen: NSScreen, content: SCShareableContent, excludedApps: [SCRunningApplication]) async throws -> CGImage {
        // Find the SCDisplay that matches this NSScreen
        guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
              let display = content.displays.first(where: { $0.displayID == screenNumber }) else {
            throw NSError(domain: "ScreenshotError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not find matching display"])
        }
        
        // Create filter
        let filter = SCContentFilter(
            display: display,
            excludingApplications: excludedApps,
            exceptingWindows: []
        )
        
        // Configure for maximum quality
        let config = SCStreamConfiguration()
        
        // Use the display's actual pixel dimensions
        config.width = Int(CGDisplayPixelsWide(display.displayID))
        config.height = Int(CGDisplayPixelsHigh(display.displayID))
        
        // Ensure high quality settings
        config.scalesToFit = false
        config.showsCursor = true
        config.pixelFormat = kCVPixelFormatType_32BGRA
        
        // Capture the image
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }
    
    public static func screenUnderMouse() -> NSScreen? {
        let loc = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(loc, $0.frame, false) }
    }
    
    private func targetPixelSize(for display: SCDisplay,
                         screen: NSScreen,
                         mode: ScreenshotScaleMode) -> (width: Int, height: Int) {
        let nativeW = Int(CGDisplayPixelsWide(display.displayID))
        let nativeH = Int(CGDisplayPixelsHigh(display.displayID))
        
        switch mode {
        case .nativePixels:
            return (nativeW, nativeH)
            
        case .logicalPoints:
            // Points * backing scale = native pixels. If you want strictly “points”
            // output (1x), divide by backingScaleFactor instead.
            let scale = screen.backingScaleFactor
            // “Points” output (1x) would be native / scale
            let w = Int((Double(nativeW) / scale).rounded())
            let h = Int((Double(nativeH) / scale).rounded())
            return (w, h)
            
        case .percent(let p):
            let clamped = max(0.1, min(p, 1.0))
            return (Int(Double(nativeW) * clamped), Int(Double(nativeH) * clamped))
            
        case .cappedLongestEdge(let maxEdge):
            let maxEdgeD = Double(maxEdge)
            let (w, h) = (Double(nativeW), Double(nativeH))
            let longest = max(w, h)
            guard longest > maxEdgeD else { return (nativeW, nativeH) }
            let r = maxEdgeD / longest
            return (Int((w * r).rounded()), Int((h * r).rounded()))
        }
    }
}
