package objects

import glm "core:math/linalg/glsl"
import "core:slice"

// Vertex used for drawing. Mapped directly from vertices of objects.
Vertex :: struct {
	position: glm.vec3,
	color:    glm.vec4,
}

// `x`, `y`, `z` are scalars (1.0 = "standard" size).
Scale :: struct {
	x: f32,
	y: f32,
	z: f32,
}

// See: https://en.wikipedia.org/wiki/Euler%27s_rotation_theorem
// Stores the orientation of an object as some rotation around the `norm`(al vector) by some `angle` radians.
Orientation :: struct {
	norm:  glm.vec3,
	angle: f32,
}

Frame :: struct {
	scale: Scale,
	orientation: Orientation,
}

Object :: union {
	Cube,
}

ObjectID :: distinct uint
ObjectInfo :: struct {
	type: string,
	id:   ObjectID,
}

@(private)
current_object_id: ObjectID = 0

create_cube :: proc(center: glm.vec3 = {0., 0., 0.}, starting_scale: Scale = {1., 1., 1.}, starting_orientation: Orientation = {norm = {1., 0., 0.,}, angle = 0.}) -> Object {
	key_frames := make([dynamic]Frame)
	append(&key_frames, Frame { scale = starting_scale, orientation = starting_orientation })
	cube := Cube {
		id = current_object_id,
		center = center,
		key_frames = key_frames,
		current_key_frame = 0,
	}

	current_object_id += 1

	return cube
}

get_vertices :: proc {
	get_cube_vertices,
}

color_vertices :: proc(vertices: ^[]Vertex, color: glm.vec4 = {1., 1., 1., 1.}) {
	for &vertex in vertices {
		vertex.color = color
	}
}

get_object_id :: proc(object: Object) -> ObjectID {
	#partial switch generic_object in object {
	case Cube:
		return generic_object.id
	case:
		return 0
	}
}

get_object_type_string :: proc(object: Object) -> (object_type: string) {
	#partial switch generic_object in object {
	case Cube:
		object_type = "Cube"
	case:
	}

	return
}

get_object_center :: proc(object: Object) -> (center: glm.vec3) {
	#partial switch generic_object in object {
	case Cube:
		center = generic_object.center
	}

	return
}

get_object_scale :: proc(object: Object) -> (scale: Scale) {
	#partial switch generic_object in object {
	case Cube:
		scale = generic_object.key_frames[generic_object.current_key_frame].scale
	case:
	}

	return
}

get_object_orientation :: proc(object: Object) -> (orientation: Orientation) {
	#partial switch generic_object in object {
	case Cube:
		orientation = generic_object.key_frames[generic_object.current_key_frame].orientation
	case:
	}

	return
}

get_object_info :: proc(object: ^Object) -> (object_info: ObjectInfo) {
	object_info.type = get_object_type_string(object^)
	object_info.id = ObjectID(get_object_id(object^))

	return
}

get_objects_info :: proc(objects: [dynamic]^Object) -> (objects_info: []ObjectInfo) {
	objects_info = slice.mapper(objects[:], get_object_info)

	return
}

