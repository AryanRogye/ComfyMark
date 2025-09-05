//
//  MetalBrush.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/4/25.
//

import Metal
import MetalKit

/// Kernal Compute
/*
 Idea:
 ///    when u move ur finger/mouse, you’re basically saying:
 ///        “yo GPU, paint a lil circle here at (x,y)”
 ///
 ///    the GPU has a kernel shader that runs on a bunch of pixels at once → it figures out:
 ///        “is this pixel inside the circle?”
 ///            if yes → color it with ur brush color
 ///            if no → leave it alone
 */

final class MetalBrush {
    
    let computeCache : ComputeCache = .shared
    let ctx          : MetalContext = .shared
    
    var pso: MTLComputePipelineState!
    private var queue: MTLCommandQueue!

    var inkTexture  : MTLTexture
    var brushBuffer : MTLBuffer!
    var onStampDone: (() -> Void)?
    
    init(inkTexture: MTLTexture) {
        queue = ctx.queue
        do {
            pso = try computeCache.pipeline("should_draw")
        } catch {
            print("Couldnt load pipeline state object")
        }
        self.inkTexture = inkTexture
        
        // Allocate a uniform buffer for the brush parameters
        brushBuffer = ctx.device.makeBuffer(
            length: MemoryLayout<BrushUniform>.stride,
            options: [.storageModeShared]
        )
    }
    
    public func should_draw(at point: CGPoint) {
        guard let pso = pso,
              let cmd = queue.makeCommandBuffer(),
              let enc = cmd.makeComputeCommandEncoder() else { return }
        
        // Brush settings
        let radius : Float = 10.0
        
        // Compute minimal pixel bounding box for the brush stamp.
        // Assumes `point` is in texture pixel coordinates.
        let cx = Int(round(point.x))
        let cy = Int(round(point.y))
        let r  = Int(ceil(radius))
        
        let minX = max(0, cx - r)
        let minY = max(0, cy - r)
        let maxX = min(inkTexture.width  - 1, cx + r)
        let maxY = min(inkTexture.height - 1, cy + r)
        
        let regionW = max(0, maxX - minX + 1)
        let regionH = max(0, maxY - minY + 1)
        guard regionW > 0 && regionH > 0 else { return }
        
        /// Create A Buffer
        let content = brushBuffer.contents().bindMemory(to: BrushUniform.self, capacity: 1)
        content.pointee = BrushUniform(
            pressed_pos: SIMD2(Float(cx), Float(cy)),
            radius: radius,
            tex_size: SIMD2(Int32(inkTexture.width), Int32(inkTexture.height)),
            // Top-left origin of the region we will dispatch over
            minPx: SIMD2(Int32(minX), Int32(minY))
        )
        
        enc.setComputePipelineState(pso)

        /// Output is written to the inkTexture
        /// The Place we get this from needs to make sure it follows
        /// certain steps to be written into
        enc.setTexture(inkTexture, index: 0)
        enc.setBuffer(brushBuffer, offset: 0, index: 0)
        
        // Dispatch only the required region
        let w = pso.threadExecutionWidth
        let h = max(1, pso.maxTotalThreadsPerThreadgroup / w)
        let threadsPerThreadgroup = MTLSize(width: w, height: h, depth: 1)
        let threadsPerGrid = MTLSize(width: regionW, height: regionH, depth: 1)
        enc.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        enc.endEncoding()
        cmd.addCompletedHandler { [weak self] _ in
            Task { @MainActor in
                self?.onStampDone?()
            }
        }
        cmd.commit()
    }
}
