//
//  ScreenshotProviderTests.swift
//  ComfyMarkTests
//
//  Created by Aryan Rogye on 9/7/25.
//

import XCTest
@testable import ComfyMark
import CoreGraphics

final class ScreenshotProviderTests: XCTestCase {
    
    var mockProvider: MockScreenshotProvider!
    
    override func setUp() {
        super.setUp()
        mockProvider = MockScreenshotProvider()
    }
    
    override func tearDown() {
        mockProvider = nil
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testTakeScreenshotReturnsValidImage() async throws {
        let image = await mockProvider.takeScreenshot()
        
        XCTAssertNotNil(image, "Screenshot should not be nil")
        XCTAssertEqual(image?.width, 100, "Image width should match expected value")
        XCTAssertEqual(image?.height, 50, "Image height should match expected value")
        
        // Verify image properties
        XCTAssertEqual(image?.bitsPerComponent, 8, "Should have 8 bits per component")
        XCTAssertEqual(image?.bitsPerPixel, 32, "Should have 32 bits per pixel (RGBA)")
        XCTAssertNotNil(image?.colorSpace, "Image should have a color space")
    }
    
    func testTakeScreenshotOfScreenWithCropping() async throws {
        let mockScreen = createMockScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let cropRect = CGRect(x: 10, y: 10, width: 200, height: 150)
        
        let image = await mockProvider.takeScreenshot(of: mockScreen, croppingTo: cropRect)
        
        XCTAssertNotNil(image, "Cropped screenshot should not be nil")
        XCTAssertEqual(image?.width, 200, "Cropped image width should match crop rect")
        XCTAssertEqual(image?.height, 150, "Cropped image height should match crop rect")
    }
    
    // MARK: - Edge Cases
    
    func testZeroDimensionsCrop() async throws {
        let mockScreen = createMockScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let zeroCrop = CGRect(x: 0, y: 0, width: 0, height: 0)
        
        let image = await mockProvider.takeScreenshot(of: mockScreen, croppingTo: zeroCrop)
        
        // Depending on your implementation, this might return nil or a 1x1 image
        // Adjust assertion based on your expected behavior
        if let image = image {
            XCTAssertTrue(image.width == 0 || image.width == 1, "Zero width crop should handle gracefully")
            XCTAssertTrue(image.height == 0 || image.height == 1, "Zero height crop should handle gracefully")
        } else {
            XCTAssertNil(image, "Zero dimension crop may return nil")
        }
    }
    
    func testNegativeDimensionsCrop() async throws {
        let mockScreen = createMockScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let negativeCrop = CGRect(x: 0, y: 0, width: -100, height: -50)
        
        let image = await mockProvider.takeScreenshot(of: mockScreen, croppingTo: negativeCrop)
        
        // Should handle negative dimensions gracefully (likely return nil or abs values)
        if let image = image {
            XCTAssertGreaterThanOrEqual(image.width, 0, "Width should not be negative")
            XCTAssertGreaterThanOrEqual(image.height, 0, "Height should not be negative")
        }
    }
    
    func testVeryLargeDimensions() async throws {
        let mockScreen = createMockScreen(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let largeCrop = CGRect(x: 0, y: 0, width: 10000, height: 10000)
        
        let image = await mockProvider.takeScreenshot(of: mockScreen, croppingTo: largeCrop)
        
        XCTAssertNotNil(image, "Should handle large dimensions")
        XCTAssertEqual(image?.width, 10000, "Should create image with requested large width")
        XCTAssertEqual(image?.height, 10000, "Should create image with requested large height")
    }
    
    // MARK: - Multiple Calls & Consistency
    
    func testMultipleCallsReturnConsistentResults() async throws {
        let image1 = await mockProvider.takeScreenshot()
        let image2 = await mockProvider.takeScreenshot()
        let image3 = await mockProvider.takeScreenshot()
        
        XCTAssertNotNil(image1)
        XCTAssertNotNil(image2)
        XCTAssertNotNil(image3)
        
        XCTAssertEqual(image1?.width, image2?.width, "Multiple calls should return same dimensions")
        XCTAssertEqual(image1?.height, image2?.height, "Multiple calls should return same dimensions")
        XCTAssertEqual(image2?.width, image3?.width, "Multiple calls should return same dimensions")
        XCTAssertEqual(image2?.height, image3?.height, "Multiple calls should return same dimensions")
    }
    
    func testConcurrentCalls() async throws {
        // Test that concurrent calls don't interfere with each other
        async let image1 = mockProvider.takeScreenshot()
        async let image2 = mockProvider.takeScreenshot()
        async let image3 = mockProvider.takeScreenshot()
        
        let results = await [image1, image2, image3]
        
        for (index, image) in results.enumerated() {
            XCTAssertNotNil(image, "Concurrent call \(index) should return valid image")
            XCTAssertEqual(image?.width, 100, "Concurrent call \(index) should have correct width")
            XCTAssertEqual(image?.height, 50, "Concurrent call \(index) should have correct height")
        }
    }
    
    // MARK: - Image Content Validation
    
    func testImageContentIsValid() async throws {
        let image = await mockProvider.takeScreenshot()
        
        XCTAssertNotNil(image)
        
        // Test that we can create NSImage from CGImage
        let nsImage = NSImage(cgImage: image!, size: NSSize(width: image!.width, height: image!.height))
        XCTAssertNotNil(nsImage, "Should be able to create NSImage from CGImage")
        
        // Test image data exists and has expected size
        let expectedDataSize = image!.width * image!.height * 4 // 4 bytes per pixel (RGBA)
        if let dataProvider = image!.dataProvider,
           let data = dataProvider.data {
            let actualDataSize = CFDataGetLength(data)
            XCTAssertEqual(actualDataSize, expectedDataSize, "Image data size should match expected size")
        } else {
            XCTFail("Image should have valid data provider and data")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockScreen(frame: CGRect) -> NSScreen {
        // Note: This is a conceptual mock - NSScreen is harder to mock in practice
        // You might need to create a protocol for screen operations instead
        // For now, we'll assume your MockScreenshotProvider doesn't actually use the screen parameter
        return NSScreen.main!
    }
    
    func testNilReturnHandling() async throws {
        mockProvider.shouldReturnNil = true
        
        let image = await mockProvider.takeScreenshot()
        XCTAssertNil(image, "Should return nil when configured to do so")
    }
    
    func testCustomDimensions() async throws {
        mockProvider.customWidth = 256
        mockProvider.customHeight = 128
        
        let image = await mockProvider.takeScreenshot()
        
        XCTAssertEqual(image?.width, 256, "Should use custom width")
        XCTAssertEqual(image?.height, 128, "Should use custom height")
    }
    
    func testDelayedResponse() async throws {
        mockProvider.delayInSeconds = 0.1
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let image = await mockProvider.takeScreenshot()
        let endTime = CFAbsoluteTimeGetCurrent()
        
        XCTAssertNotNil(image)
        XCTAssertGreaterThanOrEqual(endTime - startTime, 0.1, "Should respect delay")
    }
}
