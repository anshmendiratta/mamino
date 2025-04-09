#+feature dynamic-literals

package objects

import "core:fmt"
import glm "core:math/linalg/glsl"


Cube :: struct {
	// Generic object data.
	id:               ObjectID,
	keyframes:        [dynamic]KeyFrame,
	current_keyframe: uint,
}

create_cube :: proc(
	center: glm.vec3 = {0., 0., 0.},
	starting_scale: Scale = {1., 1., 1.},
	starting_orientation: Orientation = Orientation(glm.quat(1)),
) -> Object {
	keyframes: [dynamic]KeyFrame
	append(
		&keyframes,
		KeyFrame {
			scale = starting_scale,
			orientation = starting_orientation,
			center = glm.vec3{0., 0., 0.},
			start_time = 0,
		},
	)
	cube := Cube {
		id               = next_object_creation_id,
		keyframes        = keyframes,
		current_keyframe = 0,
	}
	next_object_creation_id += 1

	return cube
}

get_cube_data :: proc(
	cube: ^Cube,
	keyframe: KeyFrame,
) -> (
	vertices: []Vertex,
	indices: []u16,
	line_indices: []u16,
) {
	vertices = make([]Vertex, len(cube_vertices), context.temp_allocator)
	copy(vertices, cube_vertices)

	scale := keyframe.scale
	orientation := keyframe.orientation
	center := keyframe.center

	// Vertices.
	for &vertex in vertices {
		vertex.position.x *= scale.x
		vertex.position.y *= scale.y
		vertex.position.z *= scale.z

		rotation_matrix := glm.mat4FromQuat(quaternion128(orientation))
		vertex_pos_as_vec4 := glm.vec4 {
			vertex.position.x,
			vertex.position.y,
			vertex.position.z,
			1.0,
		}
		vertex.position = (rotation_matrix * vertex_pos_as_vec4).xyz
		vertex.position += center
	}

	// Indices.
	indices = cube_indices[:]
	line_indices = cube_line_indices

	return
}

// `normals` returns a flattened list of line endpoints. They are to be rendered two at a time using `gl.LINES`.
get_cube_normals_coordinates :: proc(cube: Cube) -> (normals: []Vertex) {
	standard_x_axis: glm.vec4 = {1., 0., 0., 0.}
	standard_y_axis: glm.vec4 = {0., 1., 0., 0.}
	standard_z_axis: glm.vec4 = {0., 0., 1., 0.}

	scale := cube.keyframes[cube.current_keyframe].scale
	orientation := cube.keyframes[cube.current_keyframe].orientation
	translation := cube.keyframes[cube.current_keyframe].center

	rotation_matrix := glm.mat4FromQuat(quaternion128(orientation))
	rotated_x_axis: glm.vec3 = (rotation_matrix * standard_x_axis).xyz
	rotated_y_axis: glm.vec3 = (rotation_matrix * standard_y_axis).xyz
	rotated_z_axis: glm.vec3 = (rotation_matrix * standard_z_axis).xyz

	// Addition of a glm.vec3 so the endpoints stick above the faces by a defined amount.
	rotated_x_normal: glm.vec3 = (rotation_matrix * standard_x_axis).xyz * scale.x + rotated_x_axis
	rotated_y_normal: glm.vec3 = (rotation_matrix * standard_y_axis).xyz * scale.y + rotated_y_axis
	rotated_z_normal: glm.vec3 = (rotation_matrix * standard_z_axis).xyz * scale.z + rotated_z_axis

	x_normal_color := x_axis_color
	y_normal_color := y_axis_color
	z_normal_color := z_axis_color
	x_normal_color.a = 0.6
	y_normal_color.a = 0.6
	z_normal_color.a = 0.6

	normals = {
		{translation, x_normal_color},
		{rotated_x_normal + translation, x_normal_color},
		{translation, y_normal_color},
		{rotated_y_normal + translation, y_normal_color},
		{translation, z_normal_color},
		{rotated_z_normal + translation, z_normal_color},
	}

	return
}

// Uses indexed drawing.
cube_vertices: []Vertex = {
	{{1.0, 1.0, 1.0}, cube_color}, // right    top  back
	{{-1.0, 1.0, 1.0}, cube_color}, //  left    top  back
	{{1.0, -1.0, 1.0}, cube_color}, // right bottom  back
	{{1.0, 1.0, -1.0}, cube_color}, // right    top front
	{{-1.0, -1.0, 1.0}, cube_color}, //  left bottom  back
	{{1.0, -1.0, -1.0}, cube_color}, // right bottom front
	{{-1.0, 1.0, -1.0}, cube_color}, //  left    top front
	{{-1.0, -1.0, -1.0}, cube_color}, //  left bottom front
}
cube_color: glm.vec4 = rgb_hex_to_color(0xD3_47_3D)
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

cube_point_indices: []u16 = {0, 1, 2, 3, 4, 5, 6, 7}
cube_line_indices: []u16 = {
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

