//
//  ComfyMarkTests.swift
//  ComfyMarkTests
//
//  Created by Aryan Rogye on 9/7/25.
//

import XCTest
@testable import ComfyMark
import CoreGraphics

final class ScreenshotProviderTests: XCTestCase {
    func testTakeScreenshotReturnsImage() async throws {
        let mock = MockScreenshotProvider()
        let img = await mock.takeScreenshot()
        XCTAssertNotNil(img)
        XCTAssertEqual(img?.width, 100)
        XCTAssertEqual(img?.height, 50)
    }
}

final class MockScreenshotProvider: ScreenshotProviding {
    func takeScreenshot() async -> CGImage? { makeTestImage(w: 100, h: 50) }
    func takeScreenshot(of screen: NSScreen) async -> CGImage? { makeTestImage(w: 80, h: 60) }
    
    private func makeTestImage(w: Int, h: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: w*4,
            space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.setFillColor(NSColor.systemBlue.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        return ctx.makeImage()
    }
}

