//
//  MetalImageView.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/1/25.
//

import AppKit
import Metal
import MetalKit
import SwiftUI
import Combine

struct MetalImageView: NSViewRepresentable {
    
    var imageTexture: MTLTexture?
    var inkTexture: MTLTexture?
    
    @Binding var viewport: Viewport
    var comfyMarkVM : ComfyMarkViewModel
    
    init(
        viewport: Binding<Viewport>,
        comfyMarkVM : ComfyMarkViewModel,
    ) {
        self.imageTexture = comfyMarkVM.imageTexture
        self.inkTexture   = comfyMarkVM.inkTexture
        self._viewport = viewport
        self.comfyMarkVM = comfyMarkVM
    }

    
    private let ctx = MetalContext.shared
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = ctx.device
        mtkView.delegate = context.coordinator
        mtkView.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        mtkView.autoResizeDrawable = true
        mtkView.framebufferOnly = true
        mtkView.enableSetNeedsDisplay = true
        
        context.coordinator.setupUpdateSubscription()
        context.coordinator.setupExportImage()
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        // push viewport every time (uniform update)
        context.coordinator.viewport = viewport
        
        
        if let imageTexture = imageTexture {
            context.coordinator.setImageTexture(imageTexture)
        }
        if let inkTexture = inkTexture {
            context.coordinator.setInkTexture(inkTexture)
        }
        
        // request a redraw (needed for both new texture and viewport changes)
        nsView.setNeedsDisplay(nsView.bounds)
        nsView.draw()
    }
    
    class Coordinator : NSObject, MTKViewDelegate {
        private var device: MTLDevice!
        private var queue: MTLCommandQueue!
        private var pso: MTLRenderPipelineState!
        
        private var vertexBuffer   : MTLBuffer!
        private var viewportBuffer : MTLBuffer!
        
        /// Textures
        private var imageTexture   : MTLTexture!
        private var inkTexture     : MTLTexture!
        
        public var viewport: Viewport?

        /// Parent
        var parent: MetalImageView
        
        /// Verticies Of The Thing we're gonna show it on
        let verts: [Vertex] = [
            /// Bottom Left
            .init(pos: [-1, -1]),
            /// Top Left
            .init(pos: [-1, 1]),
            /// Top Right
            .init(pos: [1, 1]),
            
            /// Bottom Left
            .init(pos: [-1, -1]),
            /// Bottom Right
            .init(pos: [1, -1]),
            /// Top Right
            .init(pos: [1, 1]),
        ]
        
        private weak var currentView: MTKView?
        private var cancellables: Set<AnyCancellable> = []

        init(_ parent: MetalImageView) {
            self.parent = parent
            super.init()
            
            setupMetal()
        }
        
        /// Function to setup the buffers at the start, this is nice for the vertex and the viewport
        private func setupMetal() {
            device = parent.ctx.device
            queue = parent.ctx.queue
            let lib = parent.ctx.library
            
            let desc = MTLRenderPipelineDescriptor()
            desc.vertexFunction   = lib.makeFunction(name: "vertexImageShader")
            desc.fragmentFunction = lib.makeFunction(name: "fragmentImageShader")
            desc.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            pso = try! device.makeRenderPipelineState(descriptor: desc)
            
            vertexBuffer = device.makeBuffer(
                bytes: verts,
                length: MemoryLayout<Vertex>.stride * verts.count
            )
            
            viewportBuffer = device.makeBuffer(
                length: MemoryLayout<Viewport>.stride,
                options: []
            )
        }
        
        @MainActor
        func setupExportImage() {
            parent.comfyMarkVM.getMetalImage = { [weak self] in
                self?.exportToCGImage()
            }
        }

        /// This has to be called on the main actor, because comfyMarkVM is on the
        /// the MainActor
        @MainActor
        func setupUpdateSubscription() {
            parent.comfyMarkVM.$shouldUpdate
                .filter { $0 } // Only react to true values
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    
                    if let view = self.currentView {
                        view.setNeedsDisplay(view.bounds)
                    }
                    
                    // Reset the flag
                    self.parent.comfyMarkVM.shouldUpdate = false
                }
                .store(in: &cancellables)
        }
        
        // MARK: - Main Draw
        func draw(in view: MTKView) {
            guard let rpd = view.currentRenderPassDescriptor,
                  let drw = view.currentDrawable else { return }
            currentView = view
            // Start timing
            let startTime = CACurrentMediaTime()

            
            if let viewport = viewport {
                let viewportBufferInfo = viewportBuffer.contents().bindMemory(to: Viewport.self, capacity: 1)
                viewportBufferInfo.pointee = Viewport(
                    origin: viewport.origin,
                    scale: viewport.scale
                )
            }
            
            let cmd = queue.makeCommandBuffer()!
            let enc = cmd.makeRenderCommandEncoder(descriptor: rpd)!
            
            enc.setRenderPipelineState(pso)
            enc.setVertexBuffer(
                vertexBuffer,
                offset: 0,
                index: 0
            )
            enc.setVertexBuffer(
                viewportBuffer,
                offset: 0,
                index: 1
            )
            
            enc.setFragmentTexture(imageTexture, index: 0)
            enc.setFragmentTexture(inkTexture, index: 1)
            
            enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            
            enc.endEncoding()
            cmd.present(drw)
            
            
            // Add completion handler to measure GPU time
            cmd.addCompletedHandler { [weak self] _ in
                let endTime = CACurrentMediaTime()
                let renderTime = (endTime - startTime) * 1000 // Convert to milliseconds
                
                DispatchQueue.main.async {
                    // Update your view model with the timing
                    self?.parent.comfyMarkVM.onLastRenderTime(renderTime)
                }
            }
            
            cmd.commit()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        // MARK: - Setters For Textures
        
        public func setImageTexture(_ texture: MTLTexture) {
            self.imageTexture = texture
        }
        
        public func setInkTexture(_ texture: MTLTexture) {
            self.inkTexture = texture
        }
        
        // MARK: - Export
        /// Renders the current Metal view to a CIImage
        /// - Parameters:
        ///   - size: The desired output size (defaults to current textures' size)
        ///   - viewport: The viewport to use for rendering (defaults to current viewport)
        /// - Returns: A CIImage of the rendered output, or nil if rendering fails
        func exportToCGImage(size: CGSize = CGSize(width: 3840, height: 2160), viewport: Viewport? = nil) -> CGImage? {
            guard let imageTexture = imageTexture,
                  let inkTexture = inkTexture else {
                print("Missing required textures for export")
                return nil
            }
            
            // Determine output size
            let outputSize = size ?? CGSize(
                width: imageTexture.width,
                height: imageTexture.height
            )
            
            // Use provided viewport or current one
            let exportViewport = viewport ?? self.viewport ?? Viewport(origin: SIMD2(0, 0), scale: 1.0)
            
            // Create offscreen render target
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .bgra8Unorm,
                width: Int(outputSize.width),
                height: Int(outputSize.height),
                mipmapped: false
            )
            textureDescriptor.usage = [.renderTarget, .shaderRead]
            
            guard let offscreenTexture = device.makeTexture(descriptor: textureDescriptor) else {
                print("Failed to create offscreen texture")
                return nil
            }
            
            // Render pass descriptor
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = offscreenTexture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
                red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0
            )
            
            // Update viewport buffer
            let viewportBufferInfo = viewportBuffer.contents().bindMemory(to: Viewport.self, capacity: 1)
            viewportBufferInfo.pointee = Viewport(
                origin: exportViewport.origin,
                scale: exportViewport.scale
            )
            
            // Render
            guard let commandBuffer = queue.makeCommandBuffer(),
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                print("Failed to create command buffer or render encoder")
                return nil
            }
            
            renderEncoder.setRenderPipelineState(pso)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(viewportBuffer, offset: 0, index: 1)
            renderEncoder.setFragmentTexture(imageTexture, index: 0)
            renderEncoder.setFragmentTexture(inkTexture, index: 1)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder.endEncoding()
            
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
            // Convert to CGImage
            guard let ci = CIImage(mtlTexture: offscreenTexture, options: [
                .colorSpace: CGColorSpaceCreateDeviceRGB()
            ]) else {
                print("Failed to create CIImage from texture")
                return nil
            }
            
            let h = ci.extent.height
            let flipped = ci
                .transformed(by: CGAffineTransform(scaleX: 1, y: -1)
                    .translatedBy(x: 0, y: -h))
            
            let ciContext = CIContext(mtlDevice: device)
            return ciContext.createCGImage(flipped, from: flipped.extent)
        }
    }
}
