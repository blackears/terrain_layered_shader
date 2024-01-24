/**
* MIT License
*
* Copyright (c) 2023 Mark McKay
* https://github.com/blackears/terrain_layered_shader
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

#include "res://addons/terrain_layered_shader/shaders/random.gdshaderinc"


mat2 rot_mat(float angle)
{
	return mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
}

// Calculate a randomized uv transform matrix for a grid cell based on the position of the cell.
// @cell_uv - UV cooridnate of the cell.
mat2 get_cell_xform(vec2 uv) {
	//Quantize to cell coordinate.
	vec2 cell_uv = floor(uv);
	
	float angle = random_f2(cell_uv) * 2.0 * PI;
	mat2 r = rot_mat(angle);
	return r;
}

vec4 sample_tiling(in sampler2D tex, vec2 uv, float margin)
{
	//Find neighboring cells we interpolate with
	vec2 cell = floor(uv);
	vec2 frac = fract(uv);
	
	//Amount to interpolate between neighbors
	vec2 weights;
	
	if (frac.x < .5) {
		cell.x -= 1.0;
		weights.x = min(frac.x / margin, .5) + .5;
	}
	else {
		weights.x = .5 - min((1.0 - frac.x) / margin, .5);
	}
	
	if (frac.y < .5) {
		cell.y -= 1.0;
		weights.y = min(frac.y / margin, .5) + .5;
	}
	else {
		weights.y = .5 - min((1.0 - frac.y) / margin, .5);
	}

	//Points where we sample
	vec2 uv00 = get_cell_xform(cell) * uv;
	vec2 uv10 = get_cell_xform(cell + vec2(1.0, 0.0)) * uv;
	vec2 uv01 = get_cell_xform(cell + vec2(0.0, 1.0)) * uv;
	vec2 uv11 = get_cell_xform(cell + vec2(1.0, 1.0)) * uv;
	
	//Colors sampled at points
	vec4 c00 = texture(tex, uv00);
	vec4 c10 = texture(tex, uv10);
	vec4 c01 = texture(tex, uv01);
	vec4 c11 = texture(tex, uv11);
	
	//Do interpolation
	vec4 cx0 = mix(c00, c10, smoothstep(0, 1, weights.x));
	vec4 cx1 = mix(c01, c11, smoothstep(0, 1, weights.x));
	vec4 cxy = mix(cx0, cx1, smoothstep(0, 1, weights.y));
	
	return cxy;
}
