package objects

import glm "core:math/linalg/glsl"

import "../render"

// `x`, `y`, `z` are scalars (1.0 = "standard" size).
Scale :: struct {
	x: f32,
	y: f32,
	z: f32,
}

// `x`, `y`, `z` are angles (radians). Each corresponds to the angle the object's #-axis is rotated relative to the standard axis.
Orientation :: struct {
	norm:  glm.vec3,
	angle: f32,
}

get_vertices :: proc {
	get_cube_vertices,
}

color_vertices :: proc(vertices: []render.Vertex, color: glm.vec4 = {1., 1., 1., 1.}) {
	for &vertex in vertices {
		vertex.color = color
	}
}

