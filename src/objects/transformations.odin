package objects

import "core:fmt"
import "core:time"

import glm "core:math/linalg/glsl"


// NOTE(Ansh): Duration implicitly uses seconds.
rotate :: proc(object: ^Object, rotation: Orientation, duration: f64) {
	#partial switch &generic_object in object {
	case Cube:
		last_keyframe: KeyFrame = generic_object.key_frames[generic_object.current_key_frame]
		last_orientation: glm.quat = glm.quat(last_keyframe.orientation)
		rotation: glm.quat = glm.quat(rotation)
		// TODO(Ansh): Figure out why this is addition and not multiplication.
		final_rotation: glm.quat = rotation + last_orientation

		add_key_frame(
			object,
			scale = last_keyframe.scale,
			orientation = Orientation(final_rotation),
		)
	}
}

translate :: proc(object: ^Object, translation: glm.vec3) {
	#partial switch &generic_object in object {
	case Cube:
	// generic_object.k
	}

}

scale :: proc(object: ^Object, scale: Scale) {
	#partial switch &generic_object in object {
	case Cube:
	// generic_object.keyframe = 
	}
}

wait_for :: proc() {

}

