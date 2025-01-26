package objects

import glm "core:math/linalg/glsl"

import "../render"

Cube :: struct {
	// Geometric center.
	center:      glm.vec3,
	scale:       Scale,
	orientation: Orientation,
}

get_cube_vertices :: proc(cube: Cube) -> (vertices: []render.Vertex) {
	vertices = make([]render.Vertex, len(cube_vertices))
	copy(vertices, cube_vertices)
	for &vertex in vertices {
		vertex.position.x *= cube.scale.x
		vertex.position.y *= cube.scale.y
		vertex.position.z *= cube.scale.z

		rotation_matrix := glm.mat4Rotate(cube.orientation.norm, cube.orientation.angle)
		vertex_pos_as_vec4 := glm.vec4 {
			vertex.position.x,
			vertex.position.y,
			vertex.position.z,
			1.0,
		}
		vertex.position = (rotation_matrix * vertex_pos_as_vec4).xyz
		vertex.position += cube.center
	}
	return
}

