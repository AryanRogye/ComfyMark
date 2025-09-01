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


vertex VertexOut
vertexImageShader (
                   const device VertexIn* vertices [[buffer(0)]],
                   uint vid [[vertex_id]]
                   ) {
    /// new_coordinate = (old_coordinate + 1) / 2
    /// Cuz Texture Coordinate is from (0,0) to (1,1)
    /// But Vertex Goes From (-1,-1) to (1,1)
    
    VertexOut out;
    
    float2 vertex_pos = vertices[vid].pos;  // Original -1 to 1 coords
    float2 tex_coords = (vertex_pos + 1) / 2;   /// Normalized
    tex_coords.y = 1.0 - tex_coords.y;
    
    out.texture_pos = tex_coords;
    out.position = float4(vertex_pos, 0.0, 1.0);
    
    return out;
}

fragment float4
fragmentImageShader(
                    VertexOut in [[stage_in]],
                    texture2d<float> textureIn [[texture(0)]]
                    ) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    float4 color = textureIn.sample(textureSampler, in.texture_pos);
    
    return color;  // Return the actual texture color instead of green
}
