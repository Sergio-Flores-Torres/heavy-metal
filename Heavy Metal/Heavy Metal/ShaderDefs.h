//
//  ShaderDefs.h
//  Heavy Metal
//
//  Created by SAFT on 25/07/23.
//

#ifndef ShaderDefs_h
#define ShaderDefs_h

#include <simd/simd.h>

struct Vertex {
    vector_float4 color;
    vector_float2 pos;
};

struct FragmentUniforms {
    float timestamp;
};


#endif /* ShaderDefs_h */
