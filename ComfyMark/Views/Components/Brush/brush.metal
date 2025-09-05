//
//  brush.metal
//  ComfyMark
//
//  Created by Aryan Rogye on 9/4/25.
//

#include <metal_stdlib>
using namespace metal;

// Must match the Swift-side BrushUniform memory layout.
struct BrushUniform {
    float2 pressed_pos;
    float  radius;
    int2   tex_size;
    int2   minPx;
};

kernel void should_draw(
    texture2d<float, access::read_write> ink [[texture(0)]],
    constant BrushUniform& u [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    // Global pixel position = top-left of region + local gid
    uint2 pix = uint2(u.minPx) + gid;

    // Guard against out-of-bounds
    if (pix.x >= uint(u.tex_size.x) || pix.y >= uint(u.tex_size.y)) {
        return;
    }

    // Paint a solid circle
    float2 fpix = float2(pix);
    float  d    = distance(fpix, u.pressed_pos);
    if (d <= u.radius) {
        // Black ink with full alpha (adjust color as desired)
        ink.write(float4(0.0, 0.0, 0.0, 1.0), pix);
    }
}
