package objects

import glm "core:math/linalg/glsl"

@(private)
GRID_EXTENT_HALF :: 20.
NUM_SUBGRIDS :: GRID_EXTENT_HALF
SUBGRID_LENGTH_HALF :: NUM_SUBGRIDS

// Colors.
transparent: glm.vec4 = glm.vec4{0., 0., 0., 0.}
point_color: glm.vec4 = rgb_hex_to_color(0xFF_FF_FF)
line_color: glm.vec4 = rgb_hex_to_color(0xFF_FF_FF)

// Axis colors.
x_axis_color: glm.vec4 = rgb_hex_to_color(0xeb_3a_34, 0.7)
y_axis_color: glm.vec4 = rgb_hex_to_color(0x46_eb_34, 0.7)
z_axis_color: glm.vec4 = rgb_hex_to_color(0x34_65_eb, 0.7)

// Vertices.
coordinate_axes_vertices: []Vertex = {
	{{-GRID_EXTENT_HALF, 0., 0.}, transparent},
	{{0., 0., 0.}, x_axis_color},
	{{GRID_EXTENT_HALF, 0., 0.}, transparent}, // x-axis
	{{0., -GRID_EXTENT_HALF, 0.}, transparent},
	{{0., 0., 0.}, y_axis_color},
	{{0., GRID_EXTENT_HALF, 0.}, transparent}, // y-axis
	{{0., 0., -GRID_EXTENT_HALF}, transparent},
	{{0., 0., 0.}, z_axis_color},
	{{0., 0., GRID_EXTENT_HALF}, transparent}, // z-axis
}
coordinate_axes_indices: []u16 = {0, 1, 1, 2, 3, 4, 4, 5, 6, 7, 7, 8}
subgrid_axes_vertices: []Vertex = get_subgrid_axes_vertices()[:]
subgrid_axes_indices: []u16 = get_subgrid_axes_indices()[:]

// Generator functions.

get_subgrid_axes_vertices :: proc() -> (subgrid_axes_vertices: [dynamic]Vertex) {
	for x_idx in 1 ..= NUM_SUBGRIDS {
		subgrid_axis_middle_color: glm.vec4 = rgb_hex_to_color(
			0xFF_FF_FF,
			0.2 / glm.exp_f32(f32(2 * x_idx / NUM_SUBGRIDS)),
		)
		pos_x_line: [3]Vertex = {
			{{f32(x_idx), 0., -SUBGRID_LENGTH_HALF}, transparent},
			{{f32(x_idx), 0., 0.}, subgrid_axis_middle_color},
			{{f32(x_idx), 0., +SUBGRID_LENGTH_HALF}, transparent},
		}
		neg_x_line: [3]Vertex = {
			{{-f32(x_idx), 0., -SUBGRID_LENGTH_HALF}, transparent},
			{{-f32(x_idx), 0., 0.}, subgrid_axis_middle_color},
			{{-f32(x_idx), 0., +SUBGRID_LENGTH_HALF}, transparent},
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
			{{+SUBGRID_LENGTH_HALF, 0., f32(z_idx)}, transparent},
			{{0., 0., f32(z_idx)}, subgrid_axis_middle_color},
			{{-SUBGRID_LENGTH_HALF, 0., f32(z_idx)}, transparent},
		}
		neg_z_line: [3]Vertex = {
			{{+SUBGRID_LENGTH_HALF, 0., -f32(z_idx)}, transparent},
			{{0., 0., -f32(z_idx)}, subgrid_axis_middle_color},
			{{-SUBGRID_LENGTH_HALF, 0., -f32(z_idx)}, transparent},
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

