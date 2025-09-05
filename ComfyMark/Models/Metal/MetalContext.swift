//
//  MetalContext.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/1/25.
//

import Metal

final class MetalContext {
    
    static let shared = MetalContext()
    let device: MTLDevice
    let queue: MTLCommandQueue
    let library: MTLLibrary
    
    private init() {
        device = MTLCreateSystemDefaultDevice()!
        queue  = device.makeCommandQueue()!
        library = try! device.makeDefaultLibrary(bundle: .main)
    }
    
}
