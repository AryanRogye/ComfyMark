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
    
    /// Where the image actually is when .aspectRatio(.fit) is applied.
    private func fittedImageRect(in viewSize: CGSize, imageSize: CGSize) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect  = viewSize.width / viewSize.height
        
        if viewAspect > imageAspect {
            // pillarbox (bars left/right)
            let h = viewSize.height
            let w = h * imageAspect
            return CGRect(x: (viewSize.width - w) * 0.5, y: 0, width: w, height: h)
        } else {
            // letterbox (bars top/bottom)
            let w = viewSize.width
            let h = w / imageAspect
            return CGRect(x: 0, y: (viewSize.height - h) * 0.5, width: w, height: h)
        }
    }
    
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
    
    private func clampPoint(_ p: CGPoint, to rect: CGRect) -> CGPoint {
        CGPoint(x: min(max(p.x, rect.minX), rect.maxX),
                y: min(max(p.y, rect.minY), rect.maxY))
    }
    
    internal func viewToImagePx(_ p: CGPoint,
                                viewSize: CGSize,
                                viewport: Viewport) -> CGPoint {
        let imgSize = CGSize(width: image.width, height: image.height)
        let rect = fittedImageRect(in: viewSize, imageSize: imgSize)
        
        // Clamp to the image rect instead of bailing
        let clamped = clampPoint(p, to: rect)
        let lp = CGPoint(x: clamped.x - rect.minX, y: clamped.y - rect.minY)
        
        let nx = (2.0 * lp.x / rect.width)  - 1.0
        let ny = 1.0 - (2.0 * lp.y / rect.height)
        
        let worldX = nx / CGFloat(viewport.scale) + CGFloat(viewport.origin.x)
        let worldY = ny / CGFloat(viewport.scale) + CGFloat(viewport.origin.y)
        
        let tex = imageTexture!
        var tx = (worldX + 1.0) * 0.5 * CGFloat(tex.width)
        var ty = (1.0 - worldY) * 0.5 * CGFloat(tex.height)
        tx = max(0, min(CGFloat(tex.width  - 1), tx))
        ty = max(0, min(CGFloat(tex.height - 1), ty))
        return CGPoint(x: tx, y: ty)
    }
}
