package objects

import glm "core:math/linalg/glsl"
import "core:time"

// Transformation :: enum {
// 	Rotate    = rotate(),
// 	Translate = translate(),
// }

// NOTE(Ansh): Duration implicitly uses seconds.
rotate :: proc(object: ^Object, rotation: Orientation, duration: f64) {
	#partial switch &generic_object in object {
	case Cube:
		last_keyframe: KeyFrame = generic_object.key_frames[generic_object.current_key_frame]
		last_orientation_mat4: glm.quat = quaternion128(last_keyframe.orientation)
		rotation: glm.quat = quaternion128(rotation)
		final_rotation: glm.quat = last_orientation_mat4 * rotation
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

