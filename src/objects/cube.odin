package objects

import glm "core:math/linalg/glsl"
import "core:mem"

Cube :: struct {
	// Geometric center.
	id:          ObjectID,
	center:      glm.vec3,
	key_frames: [dynamic]KeyFrame,
	current_key_frame: uint,
}

create_cube :: proc(center: glm.vec3 = {0., 0., 0.}, starting_scale: Scale = {1., 1., 1.}, starting_orientation: Orientation = {norm = {1., 0., 0.,}, angle = 0.}) -> Object {
	key_frames := make([dynamic]KeyFrame)
	append(&key_frames, KeyFrame { scale = starting_scale, orientation = starting_orientation })
	cube := Cube {
		id = current_object_id,
		center = center,
		key_frames = key_frames,
		current_key_frame = 0,
	}

	current_object_id += 1

	return cube
}

get_cube_vertices :: proc(cube: Cube) -> (vertices: []Vertex) {
	vertices = make([]Vertex, len(cube_vertices), context.temp_allocator)
	copy(vertices, cube_vertices)
	
	scale := cube.key_frames[cube.current_key_frame].scale
	orientation := cube.key_frames[cube.current_key_frame].orientation
	
	for &vertex in vertices {
		vertex.position.x *= scale.x
		vertex.position.y *= scale.y
		vertex.position.z *= scale.z

		rotation_matrix := glm.mat4Rotate(orientation.norm, orientation.angle)
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

// `normals` returns a flattened list of line endpoints. They are to be rendered two at a time using `gl.LINES`.
get_cube_normals_coordinates :: proc(cube: Cube) -> (normals: []Vertex) {
	standard_x_axis: glm.vec4 = {1., 0., 0., 0.}
	standard_y_axis: glm.vec4 = {0., 1., 0., 0.}
	standard_z_axis: glm.vec4 = {0., 0., 1., 0.}

	scale := cube.key_frames[cube.current_key_frame].scale
	orientation := cube.key_frames[cube.current_key_frame].orientation

	rotation_matrix := glm.mat4Rotate(orientation.norm, orientation.angle)
	rotated_x_axis: glm.vec3 = (rotation_matrix * standard_x_axis).xyz
	rotated_y_axis: glm.vec3 = (rotation_matrix * standard_y_axis).xyz
	rotated_z_axis: glm.vec3 = (rotation_matrix * standard_z_axis).xyz

	// Addition of a glm.vec3 so the endpoints stick above the faces by a defined amount.
	rotated_x_normal: glm.vec3 =
		(rotation_matrix * standard_x_axis).xyz * scale.x + rotated_x_axis
	rotated_y_normal: glm.vec3 =
		(rotation_matrix * standard_y_axis).xyz * scale.y + rotated_y_axis
	rotated_z_normal: glm.vec3 =
		(rotation_matrix * standard_z_axis).xyz * scale.z + rotated_z_axis

	x_normal_color := x_axis_color
	y_normal_color := y_axis_color
	z_normal_color := z_axis_color
	x_normal_color.a = 0.6
	y_normal_color.a = 0.6
	z_normal_color.a = 0.6

	normals = {
		{cube.center, x_normal_color},
		{rotated_x_normal + cube.center, x_normal_color},
		{cube.center, y_normal_color},
		{rotated_y_normal + cube.center, y_normal_color},
		{cube.center, z_normal_color},
		{rotated_z_normal + cube.center, z_normal_color},
	}

	return
}

