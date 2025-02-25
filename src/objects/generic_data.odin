package objects

import glm "core:math/linalg/glsl"
import "core:slice"

import gl "vendor:opengl"

textures: [dynamic]Texture = {}
texture_ids: [dynamic]u32 = {}

// Vertex used for drawing. Mapped directly from vertices of objects.
Vertex :: struct {
	position:      glm.vec3,
	color:         glm.vec4,
	texture_coord: glm.vec2,
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

Texture :: struct {
	texture:       rawptr,
	// i32 instead of u32 for compat with OpenGL requirements.
	width, height: i32,
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

assign_texture_coords :: proc(vertices: ^[]Vertex, texture_id: u32) {
	// for &vertex, idx in vertices {
	// 	vertex.texture_coord = textures[texture_id].
	// }
}

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

get_object_center :: proc(object: union {
		Cube,
	}) -> (center: glm.vec3) {
	#partial switch generic_object in object {
	case Cube:
		center = generic_object.center
	}

	return
}

get_object_scale :: proc(object: union {
		Cube,
	}) -> (scale: Scale) {
	#partial switch generic_object in object {
	case Cube:
		scale = generic_object.scale
	case:
	}

	return
}

get_object_orientation :: proc(object: union {
		Cube,
	}) -> (orientation: Orientation) {
	#partial switch generic_object in object {
	case Cube:
		orientation = generic_object.orientation
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

