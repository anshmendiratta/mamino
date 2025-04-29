package test

import glm "core:math/linalg/glsl"
import "core:testing"

import "../src/objects"
import "../src/render"


@(test)
test_frame_interpolation :: proc(_: ^testing.T) {
	// Tests do not work if the `start_time`s on both keyframes are the same.
	keyframe_a := objects.ModelKeyFrame {
		scale       = objects.Scale{1., 1., 1.},
		orientation = objects.Orientation(glm.quat(0)),
		position    = glm.vec3{0., 0., 0.},
		start_time  = 0,
	}
	keyframe_b := objects.ModelKeyFrame {
		scale       = objects.Scale{1., 1., 1.},
		orientation = objects.Orientation(glm.quat(0)),
		position    = glm.vec3{0., 0., 0.},
		start_time  = 1,
	}
	interpolated_keyframe := render.scene_interpolate_model_keyframes(keyframe_a, keyframe_b, 0.)
	expected_keyframe := objects.ModelKeyFrame {
		scale       = objects.Scale{1., 1., 1.},
		orientation = objects.Orientation(glm.quat(0)),
		position    = glm.vec3{0., 0., 0.},
		start_time  = 0,
	}

	assert(expected_keyframe == interpolated_keyframe, "Did not interpolate frames correctly")
}

