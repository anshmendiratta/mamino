package objects

import "core:fmt"
import "core:time"

import glm "core:math/linalg/glsl"


// NOTE(Ansh): Duration implicitly uses seconds.
rotate :: proc(object: ^Object, rotation: Orientation, duration: f64) {
	#partial switch &generic_object in object {
	case Cube:
		last_idx := len(generic_object.key_frames) - 1
		last_keyframe: KeyFrame = generic_object.key_frames[last_idx]
		last_orientation: glm.quat = glm.quat(last_keyframe.orientation)
		rotation: glm.quat = glm.quat(rotation)
		// NOTE(Jaran): testing leads to equivalent quaternions being calculated
		// unsure if this will cause problems in the future, leaving as a left multiplication for now
		final_rotation: glm.quat = rotation * last_orientation

		add_key_frame(
			object,
			scale = last_keyframe.scale,
			orientation = Orientation(final_rotation),
			translation = last_keyframe.center,
		)
	}
}

translate :: proc(object: ^Object, translation: glm.vec3, duration: f64) {
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

scale :: proc(object: ^Object, scale: Scale, duration: f64) {
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

wait_for :: proc() {

}

