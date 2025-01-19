#+feature dynamic-literals

package main

import glm "core:math/linalg/glsl"

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
