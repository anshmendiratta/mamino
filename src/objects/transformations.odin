package objects

import "core:fmt"
import "core:time"

import glm "core:math/linalg/glsl"

// NOTE(Ansh): Duration implicitly uses seconds.
rotate :: proc(object: ^Object, rotation: Orientation, duration: time.Duration) {
	#partial switch &generic_object in object {
	case Cube:
		last_idx := len(generic_object.key_frames) - 1
		last_keyframe: KeyFrame = generic_object.key_frames[last_idx]
		last_orientation: glm.quat = glm.quat(last_keyframe.orientation)
		last_from_time: time.Time = last_keyframe.from_time
		rotation: glm.quat = glm.quat(rotation)
		// NOTE(Jaran): testing leads to equivalent quaternions being calculated
		// unsure if this will cause problems in the future, leaving as a left multiplication for now
		final_rotation: glm.quat = rotation * last_orientation

		add_key_frame(
			object,
			scale = last_keyframe.scale,
			orientation = Orientation(final_rotation),
			translation = last_keyframe.center,
			from_time = last_from_time + time.Time(time.duration_nanoseconds(duration)),
			duration = duration,
		)
	}
}

// NOTE(Ansh): Duration implicitly uses seconds.
translate :: proc(object: ^Object, translation: glm.vec3, duration: time.Duration) {
	#partial switch &generic_object in object {
	case Cube:
		last_idx := len(generic_object.key_frames) - 1
		last_keyframe: KeyFrame = generic_object.key_frames[last_idx]
		last_center: glm.vec3 = last_keyframe.center
		final_center: glm.vec3 = last_center + translation

		add_key_frame(
			object,
			scale = last_keyframe.scale,
			orientation = last_keyframe.orientation,
			translation = final_center,
		)
	}

}

// NOTE(Ansh): Duration implicitly uses seconds.
scale :: proc(object: ^Object, scale: Scale, duration: time.Duration) {
	#partial switch &generic_object in object {
	case Cube:
		last_idx := len(generic_object.key_frames) - 1
		last_keyframe: KeyFrame = generic_object.key_frames[last_idx]
		last_scale: Scale = last_keyframe.scale
		final_scale: Scale = {
			x = last_scale.x * scale.x,
			y = last_scale.y * scale.y,
			z = last_scale.z * scale.z,
		}

		add_key_frame(
			object,
			scale = final_scale,
			orientation = last_keyframe.orientation,
			translation = last_keyframe.center,
		)
	}
}

// NOTE(Ansh): Duration implicitly uses seconds.
wait_for :: proc(object: ^Object, duration: time.Duration) {
	#partial switch &generic_object in object {
	case Cube:
		last_idx := len(generic_object.key_frames) - 1
		last_keyframe: KeyFrame = generic_object.key_frames[last_idx]

		add_key_frame(
			object,
			scale = last_keyframe.scale,
			orientation = last_keyframe.orientation,
			translation = last_keyframe.center,
		)
	}
}

