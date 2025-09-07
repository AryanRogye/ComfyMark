//
//  ComfyMarkViewModel.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import Combine
import AppKit
import SwiftUI
import Metal
import MetalKit

@MainActor
class ComfyMarkViewModel: ObservableObject {
    
    /// Objects
    let ctx = MetalContext.shared
    var metalBrush : MetalBrush?
    var strokeManager : StrokeManager
    
    /// Passed in
    let windowID : String
    @Published var image: CGImage
    
    /// Textures
    @Published var imageTexture: MTLTexture?
    @Published var inkTexture : MTLTexture?
    
    init(image: CGImage, windowID: String) {
        self.image = image
        self.windowID = windowID
        strokeManager = StrokeManager()

        
        imageTexture = try? self.getImageTexture(from: image)
        if let imageTexture = imageTexture {
            inkTexture = try? getInkTexture(baseTexture: imageTexture)
        }
        
        if let inkTexture = inkTexture {
            metalBrush = MetalBrush(inkTexture: inkTexture)
            metalBrush?.onStampDone = { [weak self] in
                self?.shouldUpdate = true
            }
        }
    }
    
    /// Brush Related
    @Published var brushRadius: Float = 10
    @Published var shouldShowBrushRadiusPopover: Bool = false

    /// Export Related
    @Published var exported : ExportedData?
    @Published var exportDocument: ExportDocument?
    @Published var exportSuggestedName: (String) -> String = { $0 }
    
    var onExport : ((ExportFormat, CGImage) -> ExportedData?)?
    @Published var shouldExport = false

    /// Current State For Toolbar
    @Published var currentState : EditorState = .move
    
    /// Update State for ink
    @Published var shouldUpdate : Bool = false

    /// This will be used/called to get the image from metal
    /// this will be used directly inside the metalView - `MetalImageView.swift`
    var getMetalImage: (() -> CGImage?)?
    
    /// Cacel The View - Set by Coordinator
    var onCancelTapped: (() -> Void)?
    
    /// Save whatever we did - Set by Coordinator
    var onSaveTapped: ((CGImage) -> Void)?
    
    var onLastRenderTimeUpdated: ((TimeInterval) -> Void)?
    
    // MARK: - Undo/Redo, TODO
    func undo() {
    }
    func redo() {
    }
}

// MARK: - ViewModel + Metal MenuBar Related
extension ComfyMarkViewModel {
}

// MARK: - ViewModel + Radius {
extension ComfyMarkViewModel {
    public func shouldShowRadius() {
        shouldShowBrushRadiusPopover = true
    }
}

// MARK: - ViewModel + Closures
extension ComfyMarkViewModel {
    
    public func onLastRenderTime(_ time: TimeInterval) {
        guard let onLastRenderTimeUpdated = onLastRenderTimeUpdated else {
            print("Returned On Last Render Time Cuz No Closure Was Set")
            return
        }
        onLastRenderTimeUpdated(time)
    }

    /// Function handles what we do on Exporting
    /// - onExport is set by the coordinator that passes this into the view
    /// - getMetalImage is setup by our metalView - `MetalImageView.swift`
    ///
    func onExport(_ format: ExportFormat) {
        
        /// Verify We Have a onExport
        guard let onExport = onExport else { return }
        
        /// Verify we can call the metal to get the image
        guard let getMetalImage = getMetalImage else {
            print("Returned On Export Cuz No Metal Image Function Was Set")
            return
        }
        
        let cgimage = getMetalImage()
        guard let cgimage = cgimage else {
            return
        }
        
        exported = onExport(format, cgimage)
        
        // get raw bytes (handles both .data and .nsImage if you kept that case)
        let bytes: Data
        switch exported {
        case .data(let d):
            bytes = d
        default:
            return
        }
        
        exportDocument = ExportDocument(data: bytes, contentType: format.utType)
        exportSuggestedName = format.defaultFilename
        shouldExport = true // triggers .fileExporter
    }
    
    
    func onCancel() {
        guard let onCancelTapped = onCancelTapped else { return }
        onCancelTapped()
    }
    
    func onSave() {
        guard let onSaveTapped = onSaveTapped else { return }
        
        /// Verify we can call the metal to get the image
        guard let getMetalImage = getMetalImage else {
            print("Returned On Export Cuz No Metal Image Function Was Set")
            return
        }
        
        let cgimage = getMetalImage()
        guard let cgimage = cgimage else {
            return
        }
        onSaveTapped(cgimage)
    }
}

// MARK: - ViewModel + Drawing
extension ComfyMarkViewModel {
    func beginStroke(at point: CGPoint, viewSize: CGSize, viewport: Viewport) {
        let newP = viewToImagePx(point, viewSize: viewSize, viewport: viewport)
        let clampedPt = clampToImageBounds(newP)
        strokeManager.beginStroke(at: clampedPt)
    }
    
    func addPoint(_ viewPoint: CGPoint, viewSize: CGSize, viewport: Viewport) {
        let imgPt = clampToImageBounds(viewToImagePx(viewPoint, viewSize: viewSize, viewport: viewport))
        
        // 1) stash previous point (if any)
        let prev = strokeManager.activeStroke?.points.last
        
        // 2) update model
        strokeManager.addPoint(imgPt)
        
        // 3) render only the delta (prev -> imgPt)
        if let p0 = prev {
            renderSegment(from: p0, to: imgPt)
        }
    }
    
    func endStroke() {
        strokeManager.endStroke()
    }
}

// MARK: - ViewModel + Erase
extension ComfyMarkViewModel {
    
    func beginErase(at point: CGPoint, viewSize: CGSize, viewport: Viewport) {
        let newP = viewToImagePx(point, viewSize: viewSize, viewport: viewport)
        let clampedPt = clampToImageBounds(newP)
        strokeManager.beginStroke(at: clampedPt)
    }
    func addErasePoint(at point: CGPoint, viewSize: CGSize, viewport: Viewport) {
        let imgPt = clampToImageBounds(viewToImagePx(point, viewSize: viewSize, viewport: viewport))
        
        // 1) stash previous point (if any)
        let prev = strokeManager.activeStroke?.points.last
        
        // 2) update model
        strokeManager.addPoint(imgPt)
        
        // 3) render only the delta (prev -> imgPt)
        if let p0 = prev {
            renderErase(from: p0, to: imgPt)
        }
    }
    
    private func renderErase(from a: CGPoint, to b: CGPoint) {
        guard let brush = metalBrush else { return }
        brush.drawErase(from: a, to: b, radius: brushRadius)
    }
}

// MARK: - ViewModel + Draw Helpers
extension ComfyMarkViewModel {
    
    /// This Runs a Kernel Compute which modifies the InkTexture
    private func renderSegment(from a: CGPoint, to b: CGPoint) {
        guard let brush = metalBrush else { return }
        brush.drawSegment(from: a, to: b, radius: brushRadius)
    }
    
    private func clampToImageBounds(_ point: CGPoint) -> CGPoint {
        guard let imageTexture = imageTexture else { return point }
        
        let maxX = Float(imageTexture.width - 1)
        let maxY = Float(imageTexture.height - 1)
        
        return CGPoint(
            x: CGFloat(max(0, min(maxX, Float(point.x)))),
            y: CGFloat(max(0, min(maxY, Float(point.y))))
        )
    }
    
    private func viewToImagePx(_ p: CGPoint, viewSize: CGSize, viewport: Viewport) -> CGPoint {
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

// MARK: - ViewModel + Moving/Panning
extension ComfyMarkViewModel {
    func panBy(dx: CGFloat, dy: CGFloat, viewSize: CGSize, viewport: inout Viewport) {
        let dx_c =  2 * Float(dx) / Float(viewSize.width)
        let dy_c = -2 * Float(dy) / Float(viewSize.height)
        
        viewport.origin.x -= dx_c / viewport.scale
        viewport.origin.y -= dy_c / viewport.scale
    }
    
    func endPan() {
        // reset anything if needed (like store new base)
    }
}


// MARK: - ViewModel + Textures
extension ComfyMarkViewModel {
    private func getImageTexture(from cgImage: CGImage) throws -> MTLTexture? {
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
    
    private func getInkTexture(baseTexture: MTLTexture) throws -> MTLTexture? {
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
}
