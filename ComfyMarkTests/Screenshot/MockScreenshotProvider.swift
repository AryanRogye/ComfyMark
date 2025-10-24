//
//  MockScreenshotProvider.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/12/25.
//

import SwiftUI
@testable import ComfyMark

// MARK: - MockScreenshotProvider
final class MockScreenshotProvider: ScreenshotProviding {
    
    // Add properties to make the mock more testable
    var shouldReturnNil = false
    var customWidth: Int?
    var customHeight: Int?
    var delayInSeconds: TimeInterval = 0
    
    func takeScreenshot() async -> CGImage? {
        if delayInSeconds > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delayInSeconds * 1_000_000_000))
        }
        
        guard !shouldReturnNil else { return nil }
        
        let width = customWidth ?? 100
        let height = customHeight ?? 50
        return makeTestImage(w: width, h: height)
    }
    
    func takeScreenshot(of screen: NSScreen, croppingTo rect: CGRect) async -> CGImage? {
        if delayInSeconds > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delayInSeconds * 1_000_000_000))
        }
        
        guard !shouldReturnNil else { return nil }
        
        // Handle edge cases in the mock
        let width = max(0, Int(rect.width))
        let height = max(0, Int(rect.height))
        
        // Return nil for zero dimensions if that's your expected behavior
        guard width > 0 && height > 0 else { return nil }
        
        return makeTestImage(w: width, h: height)
    }
    
    private func makeTestImage(w: Int, h: Int) -> CGImage? {
        // Handle zero or negative dimensions
        guard w > 0 && h > 0 else { return nil }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        // Create a more interesting test pattern instead of solid color
        ctx.setFillColor(NSColor.systemBlue.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        
        // Add some pattern to make images more distinguishable
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: min(w, 10), height: min(h, 10)))
        
        return ctx.makeImage()
    }
}
