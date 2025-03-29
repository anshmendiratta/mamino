package objects

import "core:math"
import glm "core:math/linalg/glsl"
import "core:slice"
import "core:time"

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
// @(private)
Orientation :: distinct glm.quat

KeyFrame :: struct {
	scale:       Scale,
	orientation: Orientation,
	center:      glm.vec3,
	from_time:   time.Time,
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
next_object_creation_id: ObjectID = 0

object_set_current_key_frame :: proc(object: ^Object, frame_index: uint) {
	#partial switch &generic_object in object {
	case Cube:
		generic_object.current_keyframe = frame_index % len(generic_object.keyframes)
	case:
		return
	}
}

@(private)
object_add_keyframe :: proc(
	object: ^Object,
	scale: Maybe(Scale) = nil,
	orientation: Maybe(Orientation) = nil,
	translation: Maybe(glm.vec3) = glm.vec3{0., 0., 0.},
	from_time: time.Time,
) {
	#partial switch &generic_object in object {
	case Cube:
		last_index := len(generic_object.keyframes) - 1
		append(
			&generic_object.keyframes,
			KeyFrame {
				scale = scale.? or_else generic_object.keyframes[last_index].scale,
				orientation = orientation.? or_else generic_object.keyframes[last_index].orientation,
				center = translation.? or_else generic_object.keyframes[last_index].center,
				from_time = from_time,
			},
		)
	case:
		return
	}
}

create_orientation :: proc(axis: glm.vec3, angle: f32) -> (o: Orientation) {
	o = Orientation(glm.quatAxisAngle(axis, glm.radians(angle)))
	return
}

get_vertices :: proc {
	get_cube_vertices,
}

color_vertices :: proc(vertices: ^[]Vertex, color: glm.vec4 = {1., 1., 1., 1.}) {
	for &vertex in vertices {
		vertex.color = color
	}
}

object_get_id :: proc(object: Object) -> ObjectID {
	#partial switch generic_object in object {
	case Cube:
		return generic_object.id
	case:
		return 0
	}
}

object_get_type_string :: proc(object: Object) -> (object_type: string) {
	#partial switch generic_object in object {
	case Cube:
		object_type = "Cube"
	case:
	}

	return
}

object_get_center :: proc(object: Object) -> (center: glm.vec3) {
	#partial switch generic_object in object {
	case Cube:
		last_idx := len(generic_object.keyframes) - 1
		last_keyframe: KeyFrame = generic_object.keyframes[last_idx]
		center = last_keyframe.center
	}

	return
}

get_object_scale :: proc(object: Object) -> (scale: Scale) {
	#partial switch generic_object in object {
	case Cube:
		scale = generic_object.keyframes[generic_object.current_keyframe].scale
	case:
	}

	return
}

object_get_orientation :: proc(object: Object) -> (orientation: Orientation) {
	#partial switch generic_object in object {
	case Cube:
		orientation = generic_object.keyframes[generic_object.current_keyframe].orientation
	case:
	}

	return
}

object_get_info :: proc(object: ^Object) -> (object_info: ObjectInfo) {
	object_info.type = object_get_type_string(object^)
	object_info.id = ObjectID(object_get_id(object^))

	return
}

get_objects_info :: proc(objects: [dynamic]^Object) -> (objects_info: []ObjectInfo) {
	objects_info = slice.mapper(objects[:], object_get_info)

	return
}

