#+feature dynamic-literals

package main

import glm "core:math/linalg/glsl"
import rand "core:math/rand"

generate_polygon_vertices :: proc(n: u32, radius: f32, center: glm.vec2) -> [dynamic]glm.vec2{
	angles: [dynamic]f32
	for i in 0..<n {
		angle: f32 = f32(i) * glm.radians(360./f32(n))
		append(&angles, angle)
	}
	vertices: [dynamic]glm.vec2
	for i in 0..<n {
		vertex_position := glm.vec2{
			center.x + radius * glm.cos(angles[i]),
			center.y + radius * glm.sin(angles[i])
		}
		append(&vertices, vertex_position)
	}
	
	return vertices
}

generate_n_colors :: proc(n: u32) -> [dynamic]glm.vec3 {
	base_color: glm.vec3 = {1.0, 0.2, 0.0}
	end_color: glm.vec3 = {0.0, 1.0, 0.2}

	// r_step_size: f32 = (end_color.r - base_color.r)/f32(n)
	// g_step_size: f32 = (end_color.g - base_color.g)/f32(n)
	// b_step_size: f32 = (end_color.b - base_color.b)/f32(n)
	colors: [dynamic]glm.vec3
	for i in 0..<n {
		// color: glm.vec3 = {base_color.r + r_step_size * f32(i), base_color.g + g_step_size * f32(i), base_color.b + b_step_size * f32(i) }
		color: glm.vec3 = {
			f32(rand.float64_uniform(0., 1.)),
			f32(rand.float64_uniform(0., 1.)),
			f32(rand.float64_uniform(0., 1.))
		}

		append(&colors, color)
	}

	return colors
}
