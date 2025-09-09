//
//  ComfyMarkTests.swift
//  ComfyMarkTests
//
//  Created by Aryan Rogye on 9/7/25.
//

import XCTest
@testable import ComfyMark
import CoreGraphics

/// I want to make sure certain settings are right, when using this

// Mock ScreenshotProviding
class MockScreenshotProviding: ScreenshotProviding {
    var capturedImage: CGImage?
    
    func takeScreenshot() async throws -> CGImage {
        // Simulate a screenshot with a mock CGImage
        guard let image = CGImage(
            width: 100,
            height: 100,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 400,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: CGDataProvider(data: CFDataCreate(nil, [UInt8](repeating: 0, count: 40000), 0)!)!,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            throw NSError(domain: "MockScreenshotError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create mock CGImage"])
        }
        capturedImage = image
        return image
    }
}


