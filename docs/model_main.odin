#+feature dynamic-literals

package main

import "interface"

main :: proc() {
	video_configuration :: VideoConfiguration {
		60, // Fps.
		{1920, 1080}, // Resolution.
		// Other config options.
	}
	configuration :: Configuration {
		video_configuration, // Save video? Store as `Maybe(T)`.
	}

	render_objects: [dynamic]union {
		Object,
		AnimationSequence,
	} = {
		{
			{Cube, center = {0., 0., 0.}, scale = {1., 1., 1.}}, // Object
			{{rotate({{1., 1., 1.}, 45}), t = 1.}, {translate({2., 3., 4.}), t = 2.}}, // Animation sequence: {animation, time_to_start_animation}
		},
		// ...
	}

	animate_time_synchronized(render_objects)
}

