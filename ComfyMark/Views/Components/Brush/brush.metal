//
//  brush.metal
//  ComfyMark
//
//  Created by Aryan Rogye on 9/4/25.
//

#include <metal_stdlib>
using namespace metal;

/*
 All coordinates are in *texture pixel space* (not NDC).
 - p0, p1:   segment endpoints in pixel coords (x,y)
 - radius:   brush radius in pixels (hard core radius before feather)
 - feather:  soft falloff width in pixels (anti-aliased edge)
 - color:    STRAIGHT RGBA (not premultiplied). We'll blend as SrcOver.
 - tex_size: ink texture size (width, height)
 - minPx:    top-left pixel of the dispatched region's AABB
 */
struct SegmentUniform {
    float2  p0;
    float2  p1;
    
    float  radius;
    float  feather;
    
    float4 color;
    int2   tex_size;
    int2   minPx;
};

/* --- Utility: distance from a point to a line segment (p0..p1) ---
 Computes the closest point on the segment to p, then returns Euclidean
 distance between p and that closest point. We clamp t to [0,1] so it’s
 a *segment*, not the infinite line.
 */
static inline float distance_to_segment(float2 p, float2 a, float2 b) {
    float2 ab = b - a;
    float  t  = dot(p - a, ab) / max(dot(ab, ab), 1e-6);
    t = clamp(t, 0.0, 1.0);
    float2 proj = a + t * ab;
    return distance(p, proj);
}

/* --- Utility: Porter–Duff SrcOver for STRAIGHT alpha ---
 dst,out are straight RGBA. We convert using the standard formula:
 out.a = src.a + dst.a * (1 - src.a)
 out.rgb = (src.rgb*src.a + dst.rgb*dst.a*(1 - src.a)) / out.a
 Division is guarded to avoid NaNs when out.a == 0.
 If your pipeline uses *premultiplied* alpha textures, change this accordingly.
 */
static inline float4 blend_src_over(float4 dst, float4 src) {
    // Treat src as straight (non-premultiplied) RGBA:
    float a = src.a + dst.a * (1.0 - src.a);
    float3 c = (src.rgb * src.a + dst.rgb * dst.a * (1.0 - src.a)) / max(a, 1e-6);
    return float4(c, a);
}


/* --- Kernel: draw a soft, blended stroke segment onto 'ink' ---
 We dispatch only over the segment’s AABB (expanded by radius/feather).
 Each thread shades exactly one pixel in that region.
 
 Thread mapping:
 - gid is the thread's local index within the region (0..regionW-1, 0..regionH-1)
 - u.minPx shifts that local index into absolute texture coords
 */
kernel void draw_segment(
    texture2d<float, access::read_write> ink [[texture(0)]],
    constant SegmentUniform& u [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    // Convert local grid index to absolute pixel coordinate in the texture.
    // We dispatched just the minimal bounding box for performance, so we add
    // the region origin (u.minPx) to get the true texture pixel.
    uint2 pix = uint2(u.minPx) + gid;
    
    // (defensive; region should already be clipped).
    if (pix.x >= uint(u.tex_size.x) || pix.y >= uint(u.tex_size.y)) {
        return;
    }
    
    // Evaluate at pixel center to reduce aliasing (rather than top-left corner).
    // This helps when radius/feather are fractional.
    float2 p = float2(pix) + 0.5; // center of pixel
    
    // Geometric coverage: distance from pixel center to the infinite segment,
    // clamped to the endpoints (true segment distance).
    float  d = distance_to_segment(p, u.p0, u.p1);
    
    // Build a soft mask in [0,1]:
    //   m = 1 inside the "solid" radius
    //   m fades to 0 across the 'feather' ring using smoothstep
    //
    // smoothstep(edge0, edge1, x) maps:
    //   x <= edge0 -> 0
    //   x >= edge1 -> 1
    // so we invert it (1 - smoothstep(...)) to get coverage that’s 1 at center.
    float m = 1.0 - smoothstep(u.radius - u.feather, u.radius, d);
    
    // Early out for pixels entirely outside the soft edge.
    if (m <= 0.0) {
        return;
    }
    
    // Construct the source “ink” for this pixel.
    // We keep color as straight RGBA and encode the coverage 'm' into alpha,
    // so partially covered pixels blend correctly.
    float4 src = float4(u.color.rgb, u.color.a * m);
    

    // Read destination pixel *once* (read/modify/write pattern).
    float4 dst = ink.read(pix);
    
    // Porter–Duff SrcOver composite: new ink over existing ink.
    float4 out = blend_src_over(dst, src);
    
    // Write back the composited result.
    ink.write(out, pix);
}
