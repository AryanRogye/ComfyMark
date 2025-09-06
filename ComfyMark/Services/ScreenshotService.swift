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
    func takeScreenshot() async throws -> CGImage
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
    /// - Currently selects the first available display.
    public func takeScreenshot() async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

        let currentApp = NSRunningApplication.current
        let excludedApps = content.applications.filter { $0.bundleIdentifier == currentApp.bundleIdentifier }

        // Pick the main display if possible; otherwise fall back sensibly.
        let targetDisplay: SCDisplay = {
            if let main = NSScreen.main,
               let id = main.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
               let match = content.displays.first(where: { $0.displayID == id }) {
                return match
            }
            // Fallback: choose the display with the largest native pixel area
            if let largest = content.displays.max(by: { a, b in
                let aw = Int(CGDisplayPixelsWide(a.displayID))
                let ah = Int(CGDisplayPixelsHigh(a.displayID))
                let bw = Int(CGDisplayPixelsWide(b.displayID))
                let bh = Int(CGDisplayPixelsHigh(b.displayID))
                return aw * ah < bw * bh
            }) {
                return largest
            }
            return content.displays.first!
        }()

        // Configure what to capture (main display)
        let filter = SCContentFilter(
            display: targetDisplay,
            excludingApplications: excludedApps,
            exceptingWindows: []
        )

        // Configure capture settings to the display's native pixel resolution (not logical points)
        let config = SCStreamConfiguration()
        
        let nss = ScreenshotService.screenUnderMouse() ?? NSScreen.main!
        let size = targetPixelSize(for: targetDisplay, screen: nss, mode: .nativePixels) // default
        config.width  = size.width
        config.height = size.height
        
        // Take screenshot
        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        
        // Save or process the image
        return image
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
