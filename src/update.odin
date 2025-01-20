#+feature dynamic-literals

package main

import glm "core:math/linalg/glsl"

update :: proc(vertices: [dynamic]Vertex) -> [dynamic]Vertex {
	angle: f32 = 0.01
	view := glm.mat4LookAt({0, -1, +1}, {0, 1, 0}, {0, 0, 1})
	proj := glm.mat4Perspective(90, 2.0, 0.1, 100.0)
	scale := glm.mat3{0.5, 0., 0., 0., 0.5, 0., 0., 0., 0.5}
	// Mutable reference to `vertex`.
	for &vertex, idx in vertices {
		vertex.position =
			(glm.vec4{vertex.position.x, vertex.position.y, vertex.position.z, 1.0} * glm.mat4Rotate({0.5, 0.5, 1.}, angle)).xyz
	}

	return vertices
}

