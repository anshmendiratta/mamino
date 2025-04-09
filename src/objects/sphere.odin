package objects

import "core:fmt"
import glm "core:math/linalg/glsl"


// Stored in spherical coordinates.
Sphere :: struct {
	// Generic object data.
	id:               ObjectID,
	keyframes:        [dynamic]KeyFrame,
	current_keyframe: uint,
	// Sphere specific fields.
	radius:           f32,
	sectors:          uint, // Number of subidivions for \theta.
	stacks:           uint, // Number of subidivions for \phi.
}

create_sphere :: proc(
	radius: f32 = 1.,
	starting_center: glm.vec3 = {0., 0., 0.},
	starting_scale: Scale = {1., 1., 1.},
	starting_orientation: Orientation = Orientation(glm.quat(1)),
	sectors: uint = 16,
	stacks: uint = 16,
) -> Object {
	keyframes: [dynamic]KeyFrame
	append(
		&keyframes,
		KeyFrame {
			scale = starting_scale,
			orientation = starting_orientation,
			center = starting_center,
			start_time = 0,
		},
	)
	sphere := Sphere {
		id               = next_object_creation_id,
		keyframes        = keyframes,
		current_keyframe = 0,
		radius           = radius,
		sectors          = sectors,
		stacks           = stacks,
	}
	next_object_creation_id += 1

	return sphere
}

sphere_color: glm.vec4 = rgb_hex_to_color(0xd3_3d_a4)

get_sphere_vertices :: proc(
	sphere: ^Sphere,
	keyframe: KeyFrame,
) -> (
	vertices: []Vertex,
	indices: []u16,
	line_indices: []u16,
) {
	vertices_dyn: [dynamic]Vertex
	indices_dyn: [dynamic]u16
	line_indices_dyn: [dynamic]u16

	phi_step := glm.PI / f32(sphere.stacks)
	theta_step := 2 * glm.PI / f32(sphere.sectors)
	// Vertices.
	for i in 0 ..= sphere.stacks {
		phi := phi_step * f32(i)
		for j in 0 ..= sphere.sectors {
			theta := theta_step * f32(j)
			x := sphere.radius * glm.sin_f32(phi) * glm.cos_f32(theta)
			// Calculation for `y` stored as `z` since OpenGL is right-handed.
			z := sphere.radius * glm.sin_f32(phi) * glm.sin_f32(theta)
			y := sphere.radius * glm.cos_f32(phi)

			append(&vertices_dyn, Vertex{position = glm.vec3{x, y, z}, color = sphere_color})
		}
	}

	// Indices taken from https://www.songho.ca/opengl/gl_sphere.html#sphere.
	k_1, k_2: u16
	for i in 0 ..< sphere.stacks {
		k_1 = u16(i * (sphere.sectors + 1))
		k_2 = k_1 + u16(sphere.sectors + 1)

		for j in 0 ..< sphere.sectors {
			// Point indices.
			if i != 0 {
				append(&indices_dyn, k_1)
				append(&indices_dyn, k_2)
				append(&indices_dyn, k_1 + 1)
			}
			if i != sphere.sectors - 1 {
				append(&indices_dyn, k_1 + 1)
				append(&indices_dyn, k_2)
				append(&indices_dyn, k_2 + 1)
			}
			// Line indices.
			append(&line_indices_dyn, k_1)
			append(&line_indices_dyn, k_2)
			if i != 0 {
				append(&line_indices_dyn, k_1)
				append(&line_indices_dyn, k_1 + 1)
			}

			k_1 += 1
			k_2 += 1
		}
	}

	vertices = vertices_dyn[:]
	indices = indices_dyn[:]
	line_indices = line_indices_dyn[:]

	return
}

