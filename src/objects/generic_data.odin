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

ObjectID :: distinct uint
ObjectInfo :: struct {
	type: string,
	id:   ObjectID,
}

get_vertices :: proc {
	get_cube_vertices,
}

color_vertices :: proc(vertices: ^[]Vertex, color: glm.vec4 = {1., 1., 1., 1.}) {
	for &vertex in vertices {
		vertex.color = color
	}
}

@(private)
get_object_id :: proc(object: union {
		Cube,
	}) -> ObjectID {
	#partial switch generic_object in object {
	case Cube:
		return generic_object.id
	case:
		return 0
	}
}

@(private)
get_object_type_string :: proc(object: union {
		Cube,
	}) -> (object_type: string) {
	#partial switch generic_object in object {
	case Cube:
		object_type = "Cube"
	case:
	}

	return
}

get_object_info :: proc(object: union {
		Cube,
	}) -> (object_info: ObjectInfo) {
	object_info.type = get_object_type_string(object)
	object_info.id = ObjectID(get_object_id(object))

	return
}

get_objects_info :: proc(objects: []union {
		Cube,
	}) -> (objects_info: []ObjectInfo) {
	objects_info = slice.mapper(objects, get_object_info)

	return
}

