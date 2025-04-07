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

get_sphere_vertices :: proc(
	sphere: ^Sphere,
	keyframe: KeyFrame,
) -> (
	vertices: []Vertex,
	indices: []u16,
) {
	vertices_dyn: [dynamic]Vertex
	indices_dyn: [dynamic]u16

	// Vertices.
	for theta in 0 ..< (2 * glm.PI / f32(sphere.sectors)) {
		for phi in 0 ..< (glm.PI / f32(sphere.stacks)) {
			x := sphere.radius * glm.sin_f32(phi) * glm.cos_f32(theta)
			y := sphere.radius * glm.sin_f32(phi) * glm.sin_f32(theta)
			z := sphere.radius * glm.cos_f32(phi)

			append(&vertices_dyn, Vertex{position = glm.vec3{x, y, z}})
		}
	}

	// Indices.
	for _, idx in vertices {
		append(&indices_dyn, u16(idx))
	}

	vertices = vertices_dyn[:]
	indices = indices_dyn[:]

	return
}

get_sphere_indices :: proc(sectors, stacks: uint, vertices: []Vertex) -> (indices: []u16) {


	return
}

