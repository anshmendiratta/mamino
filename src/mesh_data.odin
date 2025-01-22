package main

import glm "core:math/linalg/glsl"

import "render"

cube_colors: []glm.vec3 = {
	rgb_hex_to_color(0xD3_47_3D), // red
	rgb_hex_to_color(0xF5_EF_EB), // white
	rgb_hex_to_color(0xF6_AD_0F), // orange
	rgb_hex_to_color(0x31_6A_96), // blue
	rgb_hex_to_color(0x2E_24_3F), // purple
	rgb_hex_to_color(0x86_BC_D1), // light blue
	rgb_hex_to_color(0xFC_D7_03), // yellow
	rgb_hex_to_color(0x03_FC_13), // green
}
cube_vertices: []render.Vertex = {
	{{1.0, 1.0, 1.0}, cube_colors[0]}, // right    top  back
	{{-1.0, 1.0, 1.0}, cube_colors[0]}, //  left    top  back
	{{1.0, -1.0, 1.0}, cube_colors[0]}, // right bottom  back
	{{1.0, 1.0, -1.0}, cube_colors[0]}, // right    top front
	{{-1.0, -1.0, 1.0}, cube_colors[0]}, //  left bottom  back
	{{1.0, -1.0, -1.0}, cube_colors[0]}, // right bottom front
	{{-1.0, 1.0, -1.0}, cube_colors[0]}, //  left    top front
	{{-1.0, -1.0, -1.0}, cube_colors[0]}, //  left bottom front
}
// creating each face with two triangles and using indexed drawing to do so
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

point_color: glm.vec3 = rgb_hex_to_color(0xFF_FF_FF)
point_colors := generate_n_colors(8)
// assuming LHS (openGL is usually in a RHS but due to device normalization it is in a LHS (?))
point_vertices: []render.Vertex = {
	{
		{1.0, 1.0, 1.0},
		point_color, /* colors[0] */
	}, // right    top  back
	{
		{-1.0, 1.0, 1.0},
		point_color, /* colors[1] */
	}, //  left    top  back
	{
		{1.0, -1.0, 1.0},
		point_color, /* colors[2] */
	}, // right bottom  back
	{
		{1.0, 1.0, -1.0},
		point_color, /* colors[3] */
	}, // right    top front
	{
		{-1.0, -1.0, 1.0},
		point_color, /* colors[4] */
	}, //  left bottom  back
	{
		{1.0, -1.0, -1.0},
		point_color, /* colors[5] */
	}, // right bottom front
	{
		{-1.0, 1.0, -1.0},
		point_color, /* colors[6] */
	}, //  left    top front
	{
		{-1.0, -1.0, -1.0},
		point_color, /* colors[7] */
	}, //  left bottom front
}
point_indices: []u16 = {0, 1, 2, 3, 4, 5, 6, 7}

line_color: glm.vec3 = rgb_hex_to_color(0xFF_FF_FF)
line_vertices: []render.Vertex = {
	{
		{1.0, 1.0, 1.0},
		line_color, /* colors[0] */
	}, // right    top  back
	{
		{-1.0, 1.0, 1.0},
		line_color, /* colors[1] */
	}, //  left    top  back
	{
		{1.0, -1.0, 1.0},
		line_color, /* colors[2] */
	}, // right bottom  back
	{
		{1.0, 1.0, -1.0},
		line_color, /* colors[3] */
	}, // right    top front
	{
		{-1.0, -1.0, 1.0},
		line_color, /* colors[4] */
	}, //  left bottom  back
	{
		{1.0, -1.0, -1.0},
		line_color, /* colors[5] */
	}, // right bottom front
	{
		{-1.0, 1.0, -1.0},
		line_color, /* colors[6] */
	}, //  left    top front
	{
		{-1.0, -1.0, -1.0},
		line_color, /* colors[7] */
	}, //  left bottom front
}

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

axes_color: glm.vec3 = rgb_hex_to_color(0x67_BD_FF)
axes_vertices: []render.Vertex = {
	{{-100., 0., 0.}, axes_color}, 
	{{100., 0., 0.}, axes_color}, // x-axis
	{{0., -100., 0.}, axes_color}, 
	{{0., 100., 0.}, axes_color}, // y-axis
	{{0., 0., -100.}, axes_color}, 
	{{0., 0., 100.}, axes_color}, // z-axis
}
axes_indices: []u16 = {
	0, 1, 2, 3, 4, 5
}
