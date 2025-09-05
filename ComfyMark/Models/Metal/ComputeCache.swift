//
//  ComputeCache.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/4/25.
//

import Metal

enum ComputeCacheError: Error {
    case couldntMakeFunction
}

final class ComputeCache {
    static let shared = ComputeCache()
    private let ctx = MetalContext.shared
    private var cache: [String: MTLComputePipelineState] = [:]
    private let lock = DispatchQueue(label: "ComputeCache.lock")
    
    enum Err: Error { case fnMissing(String) }
    
    func pipeline(_ name: String) throws -> MTLComputePipelineState {
        try lock.sync {
            if let p = cache[name] { return p }
            guard let fn = ctx.library.makeFunction(name: name)
            else { throw Err.fnMissing(name) }
            let pso = try ctx.device.makeComputePipelineState(function: fn)
            cache[name] = pso
            return pso
        }
    }
}
