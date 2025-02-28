package objects

import glm "core:math/linalg/glsl"

@(private)
GRID_EXTENT_HALF :: 20.
@(private)
NUM_SUBGRIDS :: GRID_EXTENT_HALF
@(private)
SUBGRID_LENGTH_HALF :: NUM_SUBGRIDS

NULL_TEX_COORD :: glm.vec2{-1., -1.}

// Colors.
transparent: glm.vec4 = glm.vec4{0., 0., 0., 0.}

x_axis_color: glm.vec4 = rgb_hex_to_color(0xeb_3a_34, 0.7)
y_axis_color: glm.vec4 = rgb_hex_to_color(0x46_eb_34, 0.7)
z_axis_color: glm.vec4 = rgb_hex_to_color(0x34_65_eb, 0.7)
point_color: glm.vec4 = rgb_hex_to_color(0xFF_FF_FF)
line_color: glm.vec4 = rgb_hex_to_color(0xFF_FF_FF)
cube_color: glm.vec4 = rgb_hex_to_color(0xD3_47_3D)

// Uses indexed drawing.
cube_vertices: []Vertex = {
	{{1.0, 1.0, 1.0}, cube_color, NULL_TEX_COORD}, // right    top  back
	{{-1.0, 1.0, 1.0}, cube_color, NULL_TEX_COORD}, //  left    top  back
	{{1.0, -1.0, 1.0}, cube_color, NULL_TEX_COORD}, // right bottom  back
	{{1.0, 1.0, -1.0}, cube_color, NULL_TEX_COORD}, // right    top front
	{{-1.0, -1.0, 1.0}, cube_color, NULL_TEX_COORD}, //  left bottom  back
	{{1.0, -1.0, -1.0}, cube_color, NULL_TEX_COORD}, // right bottom front
	{{-1.0, 1.0, -1.0}, cube_color, NULL_TEX_COORD}, //  left    top front
	{{-1.0, -1.0, -1.0}, cube_color, NULL_TEX_COORD}, //  left bottom front
}
coordinate_axes_vertices: []Vertex = {
	{{-GRID_EXTENT_HALF, 0., 0.}, transparent, NULL_TEX_COORD},
	{{0., 0., 0.}, x_axis_color, NULL_TEX_COORD},
	{{GRID_EXTENT_HALF, 0., 0.}, transparent, NULL_TEX_COORD}, // x-axis
	{{0., -GRID_EXTENT_HALF, 0.}, transparent, NULL_TEX_COORD},
	{{0., 0., 0.}, y_axis_color, NULL_TEX_COORD},
	{{0., GRID_EXTENT_HALF, 0.}, transparent, NULL_TEX_COORD}, // y-axis
	{{0., 0., -GRID_EXTENT_HALF}, transparent, NULL_TEX_COORD},
	{{0., 0., 0.}, z_axis_color, NULL_TEX_COORD},
	{{0., 0., GRID_EXTENT_HALF}, transparent, NULL_TEX_COORD}, // z-axis
}
subgrid_axes_vertices: []Vertex = get_subgrid_axes_vertices()[:]

// coordinate_axes_indices: []u16 = {0, 1, 1, 2}
coordinate_axes_indices: []u16 = {0, 1, 1, 2, 3, 4, 4, 5, 6, 7, 7, 8}
subgrid_axes_indices: []u16 = get_subgrid_axes_indices()[:]
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

get_subgrid_axes_vertices :: proc() -> (subgrid_axes_vertices: [dynamic]Vertex) {
	for x_idx in 1 ..= NUM_SUBGRIDS {
		subgrid_axis_middle_color: glm.vec4 = rgb_hex_to_color(
			0xFF_FF_FF,
			0.2 / glm.exp_f32(f32(2 * x_idx / NUM_SUBGRIDS)),
		)
		pos_x_line: [3]Vertex = {
			{{f32(x_idx), 0., -SUBGRID_LENGTH_HALF}, transparent, NULL_TEX_COORD},
			{{f32(x_idx), 0., 0.}, subgrid_axis_middle_color, NULL_TEX_COORD},
			{{f32(x_idx), 0., +SUBGRID_LENGTH_HALF}, transparent, NULL_TEX_COORD},
		}
		neg_x_line: [3]Vertex = {
			{{-f32(x_idx), 0., -SUBGRID_LENGTH_HALF}, transparent, NULL_TEX_COORD},
			{{-f32(x_idx), 0., 0.}, subgrid_axis_middle_color, NULL_TEX_COORD},
			{{-f32(x_idx), 0., +SUBGRID_LENGTH_HALF}, transparent, NULL_TEX_COORD},
		}
		append(&subgrid_axes_vertices, pos_x_line[0])
		append(&subgrid_axes_vertices, pos_x_line[1])
		append(&subgrid_axes_vertices, pos_x_line[2])
		append(&subgrid_axes_vertices, neg_x_line[0])
		append(&subgrid_axes_vertices, neg_x_line[1])
		append(&subgrid_axes_vertices, neg_x_line[2])
	}
	for z_idx in 1 ..= NUM_SUBGRIDS {
		subgrid_axis_middle_color: glm.vec4 = rgb_hex_to_color(
			0xFF_FF_FF,
			0.2 / glm.exp_f32(f32(2 * z_idx / NUM_SUBGRIDS)),
		)
		pos_z_line: [3]Vertex = {
			{{+SUBGRID_LENGTH_HALF, 0., f32(z_idx)}, transparent, NULL_TEX_COORD},
			{{0., 0., f32(z_idx)}, subgrid_axis_middle_color, NULL_TEX_COORD},
			{{-SUBGRID_LENGTH_HALF, 0., f32(z_idx)}, transparent, NULL_TEX_COORD},
		}
		neg_z_line: [3]Vertex = {
			{{+SUBGRID_LENGTH_HALF, 0., -f32(z_idx)}, transparent, NULL_TEX_COORD},
			{{0., 0., -f32(z_idx)}, subgrid_axis_middle_color, NULL_TEX_COORD},
			{{-SUBGRID_LENGTH_HALF, 0., -f32(z_idx)}, transparent, NULL_TEX_COORD},
		}
		append(&subgrid_axes_vertices, pos_z_line[0])
		append(&subgrid_axes_vertices, pos_z_line[1])
		append(&subgrid_axes_vertices, pos_z_line[2])
		append(&subgrid_axes_vertices, neg_z_line[0])
		append(&subgrid_axes_vertices, neg_z_line[1])
		append(&subgrid_axes_vertices, neg_z_line[2])
	}
	return
}

get_subgrid_axes_indices :: proc() -> (subgrid_axes_indices: [dynamic]u16) {
	for idx in 0 ..< (NUM_SUBGRIDS * 2 * 3 * 2) - 2 {
		append(&subgrid_axes_indices, u16(idx))
		append(&subgrid_axes_indices, u16(idx + 1))
		append(&subgrid_axes_indices, u16(idx + 1))
		append(&subgrid_axes_indices, u16(idx + 2))
	}
	return
}

