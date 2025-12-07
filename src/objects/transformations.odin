package objects

import "core:fmt"

import glm "core:math/linalg/glsl"

pan_camera :: proc(
	camera: ^Camera,
	new_position: glm.vec3,
	new_look_at: glm.vec3 = {0., 0., 0.},
	duration_seconds: f32,
) {
	last_idx := len(camera.keyframes) - 1
	last_keyframe := camera.keyframes[last_idx]
	new_position_spherical := get_spherical_coordinates_from_cartesian(new_position)

	fmt.println(last_keyframe.start_time + duration_seconds)

	next_keyframe := CameraKeyFrame {
		r          = new_position_spherical.x,
		theta      = new_position_spherical.y,
		phi        = new_position_spherical.z,
		look_at    = new_look_at,
		start_time = last_keyframe.start_time + duration_seconds,
	}

	append(&camera.keyframes, next_keyframe)
}

rotate :: proc(
	object: ^Object,
	rotation: Orientation,
	duration_seconds: f32,
	easing: EasingFunction = EasingFunction.Linear,
) {
	#partial switch &generic_object in object {
	case Cube:
		last_idx := len(generic_object.keyframes) - 1
		last_keyframe: ModelKeyFrame = generic_object.keyframes[last_idx]
		// NOTE(Ansh): Modify the last keyframe to share the newest easing to shift all the easings one to the left. Covers the initial keyframe created at object instantiation.
		generic_object.keyframes[last_idx].easing = easing
		last_orientation: glm.quat = glm.quat(last_keyframe.orientation)
		last_start_time: f32 = last_keyframe.start_time
		rotation: glm.quat = glm.quat(rotation)
		// NOTE(Jaran): testing leads to equivalent quaternions being calculated
		// unsure if this will cause problems in the future, leaving as a left multiplication for now
		final_rotation: glm.quat = rotation * last_orientation
		final_start_time: f32 = last_start_time + duration_seconds

		object_add_keyframe(
			object,
			scale = last_keyframe.scale,
			orientation = Orientation(final_rotation),
			translation = last_keyframe.position,
			start_time = final_start_time,
			easing = easing,
		)
	case Sphere:
		last_idx := len(generic_object.keyframes) - 1
		last_keyframe: ModelKeyFrame = generic_object.keyframes[last_idx]
		// NOTE(Ansh): Modify the last keyframe to share the newest easing to shift all the easings one to the left. Covers the initial keyframe created at object instantiation.
		generic_object.keyframes[last_idx].easing = easing
		last_orientation: glm.quat = glm.quat(last_keyframe.orientation)
		last_start_time: f32 = last_keyframe.start_time
		rotation: glm.quat = glm.quat(rotation)
		// NOTE(Jaran): testing leads to equivalent quaternions being calculated
		// unsure if this will cause problems in the future, leaving as a left multiplication for now
		final_rotation: glm.quat = rotation * last_orientation
		final_start_time: f32 = last_start_time + duration_seconds

		object_add_keyframe(
			object,
			scale = last_keyframe.scale,
			orientation = Orientation(final_rotation),
			translation = last_keyframe.position,
			start_time = final_start_time,
			easing = easing,
		)
	}
}

translate :: proc(
	object: ^Object,
	translation: glm.vec3,
	duration_seconds: f32,
	easing: EasingFunction = EasingFunction.Linear,
) {
	#partial switch &generic_object in object {
	case Cube:
		last_idx := len(generic_object.keyframes) - 1
		last_keyframe: ModelKeyFrame = generic_object.keyframes[last_idx]
		last_start_time: f32 = last_keyframe.start_time
		final_start_time: f32 = last_start_time + duration_seconds
		last_position: glm.vec3 = last_keyframe.position
		final_position: glm.vec3 = last_position + translation

		object_add_keyframe(
			object,
			scale = last_keyframe.scale,
			orientation = last_keyframe.orientation,
			translation = final_position,
			start_time = final_start_time,
			easing = easing,
		)
	case Sphere:
		last_idx := len(generic_object.keyframes) - 1
		last_keyframe: ModelKeyFrame = generic_object.keyframes[last_idx]
		last_start_time: f32 = last_keyframe.start_time
		final_start_time: f32 = last_start_time + duration_seconds
		last_position: glm.vec3 = last_keyframe.position
		final_position: glm.vec3 = last_position + translation

		object_add_keyframe(
			object,
			scale = last_keyframe.scale,
			orientation = last_keyframe.orientation,
			translation = final_position,
			start_time = final_start_time,
			easing = easing,
		)
	}

}

// NOTE(Ansh): Duration implicitly uses seconds.
scale :: proc(
	object: ^Object,
	scale: Scale,
	duration_seconds: f32,
	easing: EasingFunction = EasingFunction.Linear,
) {
	#partial switch &generic_object in object {
	case Cube:
		last_idx := len(generic_object.keyframes) - 1
		last_keyframe: ModelKeyFrame = generic_object.keyframes[last_idx]
		last_start_time: f32 = last_keyframe.start_time
		final_start_time: f32 = last_start_time + duration_seconds
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
			translation = last_keyframe.position,
			start_time = final_start_time,
			easing = easing,
		)
	case Sphere:
		last_idx := len(generic_object.keyframes) - 1
		last_keyframe: ModelKeyFrame = generic_object.keyframes[last_idx]
		last_start_time: f32 = last_keyframe.start_time
		final_start_time: f32 = last_start_time + duration_seconds
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
			translation = last_keyframe.position,
			start_time = final_start_time,
			easing = easing,
		)
	}
}

// NOTE(Ansh): Duration implicitly uses seconds.
wait_for :: proc(object: ^Object, duration_seconds: f32) {
	#partial switch &generic_object in object {
	case Cube:
		last_idx := len(generic_object.keyframes) - 1
		last_keyframe: ModelKeyFrame = generic_object.keyframes[last_idx]
		last_start_time: f32 = last_keyframe.start_time
		final_start_time: f32 = last_start_time + duration_seconds

		object_add_keyframe(
			object,
			scale = last_keyframe.scale,
			orientation = last_keyframe.orientation,
			translation = last_keyframe.position,
			start_time = final_start_time,
			easing = last_keyframe.easing,
		)
	case Sphere:
		last_idx := len(generic_object.keyframes) - 1
		last_keyframe: ModelKeyFrame = generic_object.keyframes[last_idx]
		last_start_time: f32 = last_keyframe.start_time
		final_start_time: f32 = last_start_time + duration_seconds

		object_add_keyframe(
			object,
			scale = last_keyframe.scale,
			orientation = last_keyframe.orientation,
			translation = last_keyframe.position,
			start_time = final_start_time,
			easing = last_keyframe.easing,
		)
	}
}

