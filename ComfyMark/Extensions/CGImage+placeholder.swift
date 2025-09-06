//
//  CGImage+placeholder.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/2/25.
//

import SwiftUI

extension CGImage {
    static func placeholder(width: Int = 1, height: Int = 1) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            fatalError("Could not create CGContext for placeholder CGImage")
        }
        
        ctx.setFillColor(CGColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        return ctx.makeImage()!
    }
}
