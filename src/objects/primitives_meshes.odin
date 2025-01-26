package objects

import glm "core:math/linalg/glsl"

import "../render"

// Colors.
axes_color: glm.vec4 = rgb_hex_to_color(0x67_BD_FF, 0.2)
point_color: glm.vec4 = rgb_hex_to_color(0xFF_FF_FF)
line_color: glm.vec4 = rgb_hex_to_color(0xFF_FF_FF, 1.)
cube_color: glm.vec4 = rgb_hex_to_color(0xD3_47_3D) // red

cube_vertices: []render.Vertex = {
	{{1.0, 1.0, 1.0}, cube_color}, // right    top  back
	{{-1.0, 1.0, 1.0}, cube_color}, //  left    top  back
	{{1.0, -1.0, 1.0}, cube_color}, // right bottom  back
	{{1.0, 1.0, -1.0}, cube_color}, // right    top front
	{{-1.0, -1.0, 1.0}, cube_color}, //  left bottom  back
	{{1.0, -1.0, -1.0}, cube_color}, // right bottom front
	{{-1.0, 1.0, -1.0}, cube_color}, //  left    top front
	{{-1.0, -1.0, -1.0}, cube_color}, //  left bottom front
} // creating each face with two triangles and using indexed drawing to do so
axes_vertices: []render.Vertex = {
	{{-1000., 0., 0.}, axes_color},
	{{1000., 0., 0.}, axes_color}, // x-axis
	{{0., -1000., 0.}, axes_color},
	{{0., 1000., 0.}, axes_color}, // y-axis
	{{0., 0., -1000.}, axes_color},
	{{0., 0., 1000.}, axes_color}, // z-axis
}

axes_indices: []u16 = {0, 1, 2, 3, 4, 5}
point_indices: []u16 = {0, 1, 2, 3, 4, 5, 6, 7}
line_indices: []u16 = {
	0,
	2,
	2,
	5,
	5,
	3,
	3,
	0, // first face.
	6,
	7,
	7,
	4,
	4,
	1,
	1,
	6, // Second face.
	6,
	3,
	5,
	7,
	1,
	0,
	4,
	2,
}
cube_indices: []u16 = {
	0,
	1,
	2,
	2,
	4,
	1, // back face
	3,
	6,
	5,
	5,
	7,
	6, // front face
	0,
	1,
	3,
	3,
	6,
	1, // top face
	2,
	4,
	5,
	5,
	7,
	4, // bottom face
	1,
	6,
	4,
	4,
	7,
	6, // left face
	0,
	3,
	2,
	2,
	5,
	3, // right face
}

