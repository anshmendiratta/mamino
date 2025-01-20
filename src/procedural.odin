package main

import glm "core:math/linalg/glsl"
import rand "core:math/rand"

generate_polygon_vertices :: proc(n: u32, radius: f32, center: glm.vec2) -> [dynamic]glm.vec2 {
	angles: [dynamic]f32
	for i in 0 ..< n {
		angle: f32 = f32(i) * glm.radians(360. / f32(n))
		append(&angles, angle)
	}
	vertices: [dynamic]glm.vec2
	for i in 0 ..< n {
		vertex_position := glm.vec2 {
			center.x + radius * glm.cos(angles[i]),
			center.y + radius * glm.sin(angles[i]),
		}
		append(&vertices, vertex_position)
	}

	return vertices
}

generate_n_colors :: proc(n: u32) -> [dynamic]glm.vec3 {
	colors: [dynamic]glm.vec3
	lower_bound: f32 = 0.
	upper_bound: f32 = 0.5
	for i in 0 ..< n {
		color: glm.vec3 = {
			rand.float32_uniform(lower_bound, upper_bound),
			rand.float32_uniform(lower_bound, upper_bound),
			rand.float32_uniform(lower_bound, upper_bound),
		}
		append(&colors, color)
	}

	return colors
}


rgb_hex_to_color :: proc(hex_color : int) -> (ret : glm.vec3) {
	ret = {
		f32((hex_color & 0x00_FF_00_00) >> 16),
		f32((hex_color & 0x00_00_FF_00) >> 8 ),
		f32((hex_color & 0x00_00_00_FF) >> 0 ),
	} * 1.0/255.0

	return
}