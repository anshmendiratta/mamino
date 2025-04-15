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
	start_time:  f64,
	scale:       Scale,
	center:      glm.vec3,
	orientation: Orientation,
	easing:      EasingFunction,
}

// EaseIn.
EasingFunction :: enum {
	Linear,
	Quad,
	Cubic,
	Sine,
}

Object :: union {
	Cube,
	Sphere,
}

ObjectID :: distinct int
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
	case Sphere:
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
	start_time: f64,
	easing: EasingFunction = EasingFunction.Linear,
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
				start_time = start_time,
				easing = easing,
			},
		)
	case Sphere:
		last_index := len(generic_object.keyframes) - 1
		append(
			&generic_object.keyframes,
			KeyFrame {
				scale = scale.? or_else generic_object.keyframes[last_index].scale,
				orientation = orientation.? or_else generic_object.keyframes[last_index].orientation,
				center = translation.? or_else generic_object.keyframes[last_index].center,
				start_time = start_time,
				easing = easing,
			},
		)
	case:
		return
	}
}

object_catch_up_keyframe :: proc(object: ^Object, current_time: f64) {
	#partial switch &generic_object in object {
	case Cube:
		// Check if we're done with all animation sequences.
		if generic_object.current_keyframe == len(generic_object.keyframes) - 1 {
			return
		}
		current_keyframe := generic_object.keyframes[generic_object.current_keyframe]
		time_diff_between_now_and_curr_frame := current_time - current_keyframe.start_time
		next_keyframe_index := glm.clamp(
			u32(generic_object.current_keyframe + 1),
			u32(0),
			u32(len(generic_object.keyframes) - 1),
		)
		current_keyframe_duration :=
			generic_object.keyframes[next_keyframe_index].start_time - current_keyframe.start_time

		if current_keyframe_duration < time_diff_between_now_and_curr_frame {
			generic_object.current_keyframe = uint(next_keyframe_index)
			object_catch_up_keyframe(object, current_time)
		}
	case Sphere:
		// Check if we're done with all animation sequences.
		if generic_object.current_keyframe == len(generic_object.keyframes) - 1 {
			return
		}
		current_keyframe := generic_object.keyframes[generic_object.current_keyframe]
		time_diff_between_now_and_curr_frame := current_time - current_keyframe.start_time
		next_keyframe_index := glm.clamp(
			u32(generic_object.current_keyframe + 1),
			u32(0),
			u32(len(generic_object.keyframes) - 1),
		)
		current_keyframe_duration :=
			generic_object.keyframes[next_keyframe_index].start_time - current_keyframe.start_time

		if current_keyframe_duration < time_diff_between_now_and_curr_frame {
			generic_object.current_keyframe = uint(next_keyframe_index)
			object_catch_up_keyframe(object, current_time)
		}
	}
}

create_orientation :: proc(axis: glm.vec3, angle: f64) -> (o: Orientation) {
	o = Orientation(glm.quatAxisAngle(axis, glm.radians(f32(angle))))
	return
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
	case Sphere:
		return generic_object.id
	case:
		return 0
	}
}

object_get_type_string :: proc(object: Object) -> (object_type: string) {
	#partial switch generic_object in object {
	case Cube:
		object_type = "Cube"
	case Sphere:
		object_type = ""
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
	case Sphere:
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
	case Sphere:
		scale = generic_object.keyframes[generic_object.current_keyframe].scale
	case:
	}

	return
}

object_get_orientation :: proc(object: Object) -> (orientation: Orientation) {
	#partial switch generic_object in object {
	case Cube:
		orientation = generic_object.keyframes[generic_object.current_keyframe].orientation
	case Sphere:
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

