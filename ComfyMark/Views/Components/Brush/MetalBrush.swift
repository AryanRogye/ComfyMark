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
    
    private var psoSegment: MTLComputePipelineState!
    private var queue: MTLCommandQueue!

    var inkTexture  : MTLTexture
    
    private var uniformBuf: MTLBuffer!
    var onStampDone: (() -> Void)?
    
    init(inkTexture: MTLTexture) {
        queue = ctx.queue
        
        psoSegment = try? computeCache.pipeline("draw_segment")
        self.inkTexture = inkTexture
        
        // Allocate a uniform buffer for the brush parameters
        uniformBuf = ctx.device.makeBuffer(
            length: MemoryLayout<SegmentUniform>.stride,
            options: [.storageModeShared]
        )
    }
    
    public func drawSegment(from a: CGPoint, to b: CGPoint,
                            radius: Float = 10,
                            color: SIMD4<Float> = SIMD4(0,0,0,1),
                            feather: Float? = nil)
    {
        guard let pso = psoSegment,
              let cmd = queue.makeCommandBuffer(),
              let enc = cmd.makeComputeCommandEncoder() else { return }
        
        let r = radius
        let f = feather ?? max(0.75 * r, 0.5)
        
        /*
         //           Take For Example The Whole Texture We Pass In
         //
         //            |------------------------------|
         //            |                              |
         //            |                              |
         //            |                              |
         //            |                              |
         //            |                              |
         //            |                              |
         //            |------------------------------|
         //
         //            if we draw a point, we get the bounding box around it:
         //            by the radius of the brush
         //
         //            r = radius
         //           
         //            let minXf = Float(min(a.x, b.x)) - r
         //            let minYf = Float(min(a.y, b.y)) - r
         //            let maxXf = Float(max(a.x, b.x)) + r
         //            let maxYf = Float(max(a.y, b.y)) + r
         //
         //            the last step we do is to clamp it nicely
         
         //            let minX = max(0, Int(floor(minXf)))
         //            let minY = max(0, Int(floor(minYf)))
         //            let maxX = min(inkTexture.width  - 1, Int(ceil(maxXf)))
         //            let maxY = min(inkTexture.height - 1, Int(ceil(maxYf)))

         //
         //            if our values turned out:
         //             x = [5.3, 15.3], y = [15.7, 25.7]
         //
         //            our clamp logic would turn it into:
         //             x = [5, 16], y = [16, 26]
         //
         //            |------------------------------|
         //            |                              |
         //            |           |-----|            |
         //            |           |     |            |
         //            |           |  x  |            |
         //            |           |_____|            |
         //            |                              |
         //            |------------------------------|
         //
         //
         //
         //
         */
        
        // Compute expanded AABB for the segment
        let minXf = Float(min(a.x, b.x)) - r
        let minYf = Float(min(a.y, b.y)) - r
        let maxXf = Float(max(a.x, b.x)) + r
        let maxYf = Float(max(a.y, b.y)) + r
        
        let minX = max(0, Int(floor(minXf)))
        let minY = max(0, Int(floor(minYf)))
        let maxX = min(inkTexture.width  - 1, Int(ceil(maxXf)))
        let maxY = min(inkTexture.height - 1, Int(ceil(maxYf)))
        
        let regionW = max(0, maxX - minX + 1)
        let regionH = max(0, maxY - minY + 1)
        guard regionW > 0 && regionH > 0 else { return }
        /// Make sure that the regions, we're hitting are valid
        
        /// Fill uniforms
        let u = uniformBuf.contents().bindMemory(to: SegmentUniform.self, capacity: 1)
        u.pointee = SegmentUniform(
            /// Point A Value
            p0: SIMD2(Float(a.x), Float(a.y)),
            /// Point B Value
            p1: SIMD2(Float(b.x), Float(b.y)),
            radius: r,
            feather: f,
            color: color,
            tex_size: SIMD2(Int32(inkTexture.width), Int32(inkTexture.height)),
            minPx: SIMD2(Int32(minX), Int32(minY))
        )
        
        enc.setComputePipelineState(pso)
        enc.setTexture(inkTexture, index: 0)
        enc.setBuffer(uniformBuf, offset: 0, index: 0)
        
        let w = pso.threadExecutionWidth
        let h = max(1, pso.maxTotalThreadsPerThreadgroup / w)
        let tptg = MTLSize(width: w, height: h, depth: 1)
        let tpg  = MTLSize(width: regionW, height: regionH, depth: 1)
        enc.dispatchThreads(tpg, threadsPerThreadgroup: tptg)
        
        enc.endEncoding()
        cmd.addCompletedHandler { [weak self] _ in
            Task { @MainActor in self?.onStampDone?() }
        }
        cmd.commit()
    }
}
