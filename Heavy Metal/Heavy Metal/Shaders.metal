//
//  Shaders.metal
//  Heavy Metal
//
//  Created by SAFT on 25/07/23.
//

#include <metal_stdlib>
#include "ShaderDefs.h"

using namespace metal;

struct VertexOut {
    float4 color;
    float4 pos [[position]];
    float pointSize [[point_size]];
};

float3 cosPalette(float t)
{
    
    float3 a = float3(0.500, 0.500, 0.500);
    float3 b = float3(0.500, 0.500, 0.500);
    float3 c = float3(0.800, 0.800, 0.500);
    float3 d = float3(0.000, 0.200, 0.500);
    
    return a + b * cos(6.28318 * ( c * t + d));
}

vertex VertexOut vertexShader(const device Vertex *vertexArray [[buffer(0)]], constant FragmentUniforms &uniforms [[buffer(1)]], unsigned int vid [[vertex_id]])
{
    // Get the data for the current vertex.
    Vertex in = vertexArray[vid];
    VertexOut out;
    float3 finalColor = float3(0.0, 0.0, 0.0);

    for (float i = 0.0; i < 3.0; i++) {
        float2 newpos = fract(in.pos * 1.6) - 0.5;
        
        float d = length(newpos) * exp(i);
        
        float3 newcolor = cosPalette(length(in.pos) + uniforms.timestamp * 0.7);

        d = sin(d * 8.0 + uniforms.timestamp) / 8.0;
        d = abs(d);
        
        d = 0.02 / d;
        //d = pow(0.02 / d, 1.5);
        finalColor += newcolor * d;
    }
    
    // Pass the vertex color directly to the rasterizer
    out.color = float4(finalColor, 1.0);
    
    // Pass the already normalized screen-space coordinates to the rasterizer
    out.pos = float4(in.pos.x, in.pos.y, 0, 1);
    out.pointSize = 1 / 1024;

    return out;
}

fragment float4 fragmentShader(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]])
{
    return float4(interpolated.color.rgb, interpolated.color.a);
}


