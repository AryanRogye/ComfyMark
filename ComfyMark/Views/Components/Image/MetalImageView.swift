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
        comfyMarkVM : ComfyMarkViewModel
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
        
        private var cancellables: Set<AnyCancellable> = []

        init(_ parent: MetalImageView) {
            self.parent = parent
            super.init()
            
            setupMetal()
        }
        
        @MainActor
        func setupUpdateSubscription() {
            parent.comfyMarkVM.$shouldUpdate
                .filter { $0 } // Only react to true values
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    
                    print("Combine received update trigger")
                    
                    if let view = self.currentView {
                        view.setNeedsDisplay(view.bounds)
                        print("Marked view as needing display")
                    }
                    
                    // Reset the flag
                    self.parent.comfyMarkVM.shouldUpdate = false
                }
                .store(in: &cancellables)
        }
        
        
        // Add this to store the current view
        private weak var currentView: MTKView?
        
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
        
        func triggerDraw(_ view: MTKView) { view.setNeedsDisplay(view.bounds) }
        
        func draw(in view: MTKView) {
            guard let rpd = view.currentRenderPassDescriptor,
                  let drw = view.currentDrawable else { return }
            currentView = view
            
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
            cmd.commit()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        public func setImageTexture(_ texture: MTLTexture) {
            self.imageTexture = texture
        }
        
        public func setInkTexture(_ texture: MTLTexture) {
            self.inkTexture = texture
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
    }
}
