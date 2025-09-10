//
//  Helpers.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/9/25.
//

import SwiftUI
import Metal
import MetalKit

// MARK: - 🖼️ ViewModel + Textures
/*
 // Responsible For Metal Helpers:
 --------------------------------------------------------------------------------
 //   getImageTexture : This is a helper to extract the metal texture from a CGImage
 --------------------------------------------------------------------------------
 //   getInkTexture   : This is a helper to extract the metal texture to write into for
 //                     a CGImage This is useful for the drawing and erasings
 --------------------------------------------------------------------------------
 //   renderSegment   : This is What is calling kernel to draw the Brush onto the screen,
 //                     This will modify the Ink Texture
 --------------------------------------------------------------------------------
 //     renderErase   : This Runs a kernel Compute which will turn the InkTexture back into
 //                     the original texture behind where the user pressed
 --------------------------------------------------------------------------------
 */
extension ComfyMarkViewModel {
    // MARK: - 🧱 Textures
    internal func getImageTexture(from cgImage: CGImage) throws -> MTLTexture? {
        let loader = MTKTextureLoader(device: MetalContext.shared.device)
        
        let tex = try loader.newTexture(
            cgImage: cgImage,
            options: [
                .SRGB: false as NSNumber,
                .generateMipmaps: true as NSNumber,
                .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
                .textureStorageMode: NSNumber(value: MTLStorageMode.shared.rawValue)
            ]
        )
        
        return tex
    }
    internal func getInkTexture(baseTexture: MTLTexture) throws -> MTLTexture? {
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: baseTexture.width,
            height: baseTexture.height,
            mipmapped: false
        )
        desc.usage = [.shaderRead, .shaderWrite, .renderTarget]
        desc.storageMode = .private
        
        return ctx.device.makeTexture(descriptor: desc)!
    }
    // MARK: - ✍️ Rendering
    internal func renderSegment(from a: CGPoint, to b: CGPoint) {
        guard let brush = metalBrush else { return }
        brush.drawSegment(from: a, to: b, radius: brushRadius)
    }
    // MARK: - 🧽 Erasing
    internal func renderErase(from a: CGPoint, to b: CGPoint) {
        guard let brush = metalBrush else { return }
        brush.drawErase(from: a, to: b, radius: brushRadius)
    }
}

// MARK: - ViewModel + Stroke Helpers

extension ComfyMarkViewModel {
    internal func replayStroke(_ s: Stroke) {
        let pts = s.smoothed ?? s.points
        guard pts.count > 1 else { return }
        for i in 0..<(pts.count - 1) {
            renderSegment(from: pts[i], to: pts[i+1])
        }
    }
    
    internal func replayErase(_ pts: [CGPoint]) {
        guard pts.count > 1 else { return }
        for i in 0..<(pts.count - 1) {
            renderErase(from: pts[i], to: pts[i+1])
        }
    }
    
    // Clear & rebuild everything from model (fallback if you don’t have region redraw)
    internal func rerenderAllFromModel() {
//        resetToBaseImage()                 // whatever you use to clear to original image/texture
        for stroke in strokeManager.allStrokesInOrder() {
            print("Using Stroke: \(stroke)")
            replayStroke(stroke)
        }
    }
}



// MARK: - 📐 ViewModel + Draw Helpers
/*
 // Responsible For Helping out during drawing
 --------------------------------------------------------------------------------
 //   clampToImageBounds  : This is a helper to clamp the point at which the user pressed
 //                         to a min of 0 and a max of the highest image texture
 ---------------------------------------------------------------------------------
 //   viewToImagePx       : Normalize To Image Px where it needs -1 to +1
 ---------------------------------------------------------------------------------
 */
extension ComfyMarkViewModel {
    // MARK: - 🎯 clampToImageBounds
    internal func clampToImageBounds(_ point: CGPoint) -> CGPoint {
        guard let imageTexture = imageTexture else { return point }
        
        let maxX = Float(imageTexture.width - 1)
        let maxY = Float(imageTexture.height - 1)
        
        return CGPoint(
            x: CGFloat(max(0, min(maxX, Float(point.x)))),
            y: CGFloat(max(0, min(maxY, Float(point.y))))
        )
    }
    // MARK: - 🗺️ viewToImagePx
    internal func viewToImagePx(_ p: CGPoint, viewSize: CGSize, viewport: Viewport) -> CGPoint {
        // First, convert SwiftUI view coordinates to normalized coordinates (-1 to +1)
        let normalizedX = (2.0 * p.x / viewSize.width) - 1.0
        let normalizedY = 1.0 - (2.0 * p.y / viewSize.height) // Flip Y for Metal coordinates
        
        // Apply viewport transformation
        let worldX = normalizedX / CGFloat(viewport.scale) + CGFloat(viewport.origin.x)
        let worldY = normalizedY / CGFloat(viewport.scale) + CGFloat(viewport.origin.y)
        
        // Convert to texture pixel coordinates
        // Assuming your texture coordinates go from (0,0) to (textureWidth, textureHeight)
        guard let imageTexture = imageTexture else { return CGPoint.zero }
        
        let textureX = (worldX + 1.0) * 0.5 * CGFloat(imageTexture.width)
        let textureY = (1.0 - worldY) * 0.5 * CGFloat(imageTexture.height) // Flip Y back for texture coordinates
        
        return CGPoint(x: textureX, y: textureY)
    }
}
