//
//  image.metal
//  ComfyMark
//
//  Created by Aryan Rogye on 9/1/25.
//

#include <metal_stdlib>
using namespace metal;


// MARK: - Vertex Structs
struct VertexIn {
    float2 pos;
};

struct VertexOut {
    float4 position [[position]]; // required so rasterizer knows screen pos
    float2 texture_pos;
    float4 color;                 // any extra varyings you want to interpolate
};

/*
 Swift Side:
 /// struct Viewport {
 ///    var origin: CGPoint = .zero
 ///    var scale: CGFloat = 1.0
 /// }
 
*/
struct Viewport {
    float2 origin;
    float scale;
};

vertex VertexOut
vertexImageShader (
                   const device VertexIn* vertices [[buffer(0)]],
                   constant Viewport& vp [[buffer(1)]],
                   uint vid [[vertex_id]]
                   ) {
    /// new_coordinate = (old_coordinate + 1) / 2
    /// Cuz Texture Coordinate is from (0,0) to (1,1)
    /// But Vertex Goes From (-1,-1) to (1,1)
    
    VertexOut out;
    
    float2 vertex_pos = vertices[vid].pos;  // Original -1 to 1 coords
    /// Scaling based on the zoom or whatever the user chooses
    vertex_pos = (vertex_pos - vp.origin) * vp.scale;
    
    // Texture sampling position: apply the INVERSE transform so that
    // scale > 1 samples a smaller region (magnifies), and origin pans.
    float2 sample_pos = (vertex_pos / vp.scale) + vp.origin;
    // Convert to 0..1 texture coords and flip Y
    float2 tex_coords = (sample_pos + 1) / 2;
    tex_coords.y = 1.0 - tex_coords.y;
    
    out.texture_pos = tex_coords;
    out.position = float4(vertex_pos, 0.0, 1.0);
    
    return out;
}

fragment float4
fragmentImageShader(
                    VertexOut in [[stage_in]],
                    texture2d<float> baseTex  [[texture(0)]],
                    texture2d<float> inkTex   [[texture(1)]]
                    ) {
    // Use nearest for magnification (crisper when zooming in),
    // keep linear for minification (smoother when zooming out).
    
    constexpr sampler s(mag_filter::nearest, min_filter::linear);

    float4 base = baseTex.sample(s, in.texture_pos);
    float4 ink  = inkTex.sample(s,  in.texture_pos);
    
    float3 rgb = mix(base.rgb, ink.rgb, ink.a);
    return float4(rgb, 1.0);
}
