//
//  BrushUniform.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/5/25.
//

struct SegmentUniform {
    var p0: SIMD2<Float>
    var p1: SIMD2<Float>
    var radius: Float
    var feather: Float
    var color: SIMD4<Float>   // straight RGBA
    var tex_size: SIMD2<Int32>
    var minPx: SIMD2<Int32>
}
