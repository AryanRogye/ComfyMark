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
    
    /// Passed in
    let windowID : String
    @Published var image: CGImage
    
    /// Textures
    @Published var imageTexture: MTLTexture?
    @Published var inkTexture : MTLTexture?
    
    init(image: CGImage, windowID: String) {
        self.image = image
        self.windowID = windowID
        
        
        do {
            imageTexture = try self.getImageTexture(from: image)
        } catch {
            print("Couldnt Get Image Texture")
        }
        do {
            if let imageTexture = imageTexture {
                inkTexture = try getInkTexture(baseTexture: imageTexture)
            }
        } catch {
            print("Couldnt Get Ink Texture")
        }
        
        if let inkTexture = inkTexture {
            metalBrush = MetalBrush(inkTexture: inkTexture)
            metalBrush?.onStampDone = { [weak self] in
                self?.shouldUpdate = true
            }
        }
    }
    

    /// View Related
    @Published var strokes: [Stroke] = []
    @Published var exported : ExportedData?
    @Published var exportDocument: ExportDocument?
    @Published var exportSuggestedName: (String) -> String = { $0 }
    
    @Published var currentState : EditorState = .move
    @Published var shouldUpdate : Bool = false

    var internalIndex: Int = 0
    var hasActiveStroke: Bool {
        strokes.indices.contains(internalIndex)
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
    
    /// This will be used/called to get the image from metal
    /// this will be used directly inside the metalView - `MetalImageView.swift`
    var getMetalImage: (() -> CGImage?)?
    
    var onExport : ((ExportFormat, CGImage) -> ExportedData?)?
    @Published var shouldExport = false
    
    var onCancelTapped: (() -> Void)?

    // MARK: - Closure Handling
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
    
    
    // MARK: - For Drawing
    func beginStroke(at point: CGPoint, viewSize: CGSize, viewport: Viewport) {
        let newP = viewToImagePx(point, viewSize: viewSize, viewport: viewport)
        metalBrush?.should_draw(at: newP)
    }
    
    func addPoint(_ viewPoint: CGPoint, viewSize: CGSize, viewport: Viewport) {
        guard let brush = metalBrush else { return }
        let imgPt = viewToImagePx(viewPoint, viewSize: viewSize, viewport: viewport)
        brush.should_draw(at: imgPt)      // compute writes into inkTexture
    }
    
    func viewToImagePx(_ p: CGPoint, viewSize: CGSize, viewport: Viewport) -> CGPoint {
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

    
    // MARK: - For Moving/Panning
    
    func panBy(dx: CGFloat, dy: CGFloat, viewSize: CGSize, viewport: inout Viewport) {
        let dx_c =  2 * Float(dx) / Float(viewSize.width)
        let dy_c = -2 * Float(dy) / Float(viewSize.height)
        
        viewport.origin.x -= dx_c / viewport.scale
        viewport.origin.y -= dy_c / viewport.scale
    }
    
    func endPan() {
        // reset anything if needed (like store new base)
    }
    
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

