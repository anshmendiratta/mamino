package objects

import "core:fmt"

import glm "core:math/linalg/glsl"

rotate :: proc(
	object: ^Object,
	rotation: Orientation,
	duration_seconds: f64,
	easing: EasingFunction = EasingFunction.Linear,
) {
	#partial switch &generic_object in object {
	case Cube:
		last_idx := len(generic_object.keyframes) - 1
		last_keyframe: KeyFrame = generic_object.keyframes[last_idx]
		last_orientation: glm.quat = glm.quat(last_keyframe.orientation)
		last_start_time: f64 = last_keyframe.start_time
		rotation: glm.quat = glm.quat(rotation)
		// NOTE(Jaran): testing leads to equivalent quaternions being calculated
		// unsure if this will cause problems in the future, leaving as a left multiplication for now
		final_rotation: glm.quat = rotation * last_orientation
		final_start_time: f64 = last_start_time + duration_seconds

		object_add_keyframe(
			object,
			scale = last_keyframe.scale,
			orientation = Orientation(final_rotation),
			translation = last_keyframe.center,
			start_time = final_start_time,
		)
	case Sphere:
		last_idx := len(generic_object.keyframes) - 1
		last_keyframe: KeyFrame = generic_object.keyframes[last_idx]
		last_orientation: glm.quat = glm.quat(last_keyframe.orientation)
		last_start_time: f64 = last_keyframe.start_time
		rotation: glm.quat = glm.quat(rotation)
		// NOTE(Jaran): testing leads to equivalent quaternions being calculated
		// unsure if this will cause problems in the future, leaving as a left multiplication for now
		final_rotation: glm.quat = rotation * last_orientation
		final_start_time: f64 = last_start_time + duration_seconds

		object_add_keyframe(
			object,
			scale = last_keyframe.scale,
			orientation = Orientation(final_rotation),
			translation = last_keyframe.center,
			start_time = final_start_time,
		)
	}
}

translate :: proc(
	object: ^Object,
	translation: glm.vec3,
	duration_seconds: f64,
	easing: EasingFunction = EasingFunction.Linear,
) {
	#partial switch &generic_object in object {
	case Cube:
		last_idx := len(generic_object.keyframes) - 1
		last_keyframe: KeyFrame = generic_object.keyframes[last_idx]
		last_start_time: f64 = last_keyframe.start_time
		final_start_time: f64 = last_start_time + duration_seconds
		last_center: glm.vec3 = last_keyframe.center
		final_center: glm.vec3 = last_center + translation

		object_add_keyframe(
			object,
			scale = last_keyframe.scale,
			orientation = last_keyframe.orientation,
			translation = final_center,
			start_time = final_start_time,
		)
	case Sphere:
		last_idx := len(generic_object.keyframes) - 1
		last_keyframe: KeyFrame = generic_object.keyframes[last_idx]
		last_start_time: f64 = last_keyframe.start_time
		final_start_time: f64 = last_start_time + duration_seconds
		last_center: glm.vec3 = last_keyframe.center
		final_center: glm.vec3 = last_center + translation

		object_add_keyframe(
			object,
			scale = last_keyframe.scale,
			orientation = last_keyframe.orientation,
			translation = final_center,
			start_time = final_start_time,
		)
	}

}

// NOTE(Ansh): Duration implicitly uses seconds.
scale :: proc(
	object: ^Object,
	scale: Scale,
	duration_seconds: f64,
	easing: EasingFunction = EasingFunction.Linear,
) {
	#partial switch &generic_object in object {
	case Cube:
		last_idx := len(generic_object.keyframes) - 1
		last_keyframe: KeyFrame = generic_object.keyframes[last_idx]
		last_start_time: f64 = last_keyframe.start_time
		final_start_time: f64 = last_start_time + duration_seconds
		last_scale: Scale = last_keyframe.scale
		final_scale: Scale = {
			x = last_scale.x * scale.x,
			y = last_scale.y * scale.y,
			z = last_scale.z * scale.z,
		}

		object_add_keyframe(
			object,
			scale = final_scale,
			orientation = last_keyframe.orientation,
			translation = last_keyframe.center,
			start_time = final_start_time,
		)
	case Sphere:
		last_idx := len(generic_object.keyframes) - 1
		last_keyframe: KeyFrame = generic_object.keyframes[last_idx]
		last_start_time: f64 = last_keyframe.start_time
		final_start_time: f64 = last_start_time + duration_seconds
		last_scale: Scale = last_keyframe.scale
		final_scale: Scale = {
			x = last_scale.x * scale.x,
			y = last_scale.y * scale.y,
			z = last_scale.z * scale.z,
		}

		object_add_keyframe(
			object,
			scale = final_scale,
			orientation = last_keyframe.orientation,
			translation = last_keyframe.center,
			start_time = final_start_time,
		)
	}
}

// NOTE(Ansh): Duration implicitly uses seconds.
wait_for :: proc(
	object: ^Object,
	duration_seconds: f64,
	easing: EasingFunction = EasingFunction.Linear,
) {
	#partial switch &generic_object in object {
	case Cube:
		last_idx := len(generic_object.keyframes) - 1
		last_keyframe: KeyFrame = generic_object.keyframes[last_idx]
		last_start_time: f64 = last_keyframe.start_time
		final_start_time: f64 = last_start_time + duration_seconds

		object_add_keyframe(
			object,
			scale = last_keyframe.scale,
			orientation = last_keyframe.orientation,
			translation = last_keyframe.center,
			start_time = final_start_time,
		)
	case Sphere:
		last_idx := len(generic_object.keyframes) - 1
		last_keyframe: KeyFrame = generic_object.keyframes[last_idx]
		last_start_time: f64 = last_keyframe.start_time
		final_start_time: f64 = last_start_time + duration_seconds

		object_add_keyframe(
			object,
			scale = last_keyframe.scale,
			orientation = last_keyframe.orientation,
			translation = last_keyframe.center,
			start_time = final_start_time,
			easing = easing,
		)
	}
}

