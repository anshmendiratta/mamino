package objects

import "core:fmt"

import glm "core:math/linalg/glsl"
import rand "core:math/rand"


generate_n_colors :: proc(n: u32) -> [dynamic]glm.vec3 {
	colors: [dynamic]glm.vec3
	lower_bound: f32 = 0.4
	upper_bound: f32 = 1.0
	for i in 0 ..< n {
		color: glm.vec3 = {
			glm.pow_f32(rand.float32_range(lower_bound, upper_bound), 0.52),
			glm.pow_f32(rand.float32_range(lower_bound, upper_bound), 0.5),
			glm.pow_f32(rand.float32_range(lower_bound, upper_bound), 0.2),
		}
		append(&colors, color)
	}

	return colors
}

rgb_hex_to_color :: proc(hex_color: int, alpha: f32 = 1.) -> (ret: glm.vec4) {
	ret =
		{
			f32((hex_color & 0x00_FF_00_00) >> 16),
			f32((hex_color & 0x00_00_FF_00) >> 8),
			f32((hex_color & 0x00_00_00_FF) >> 0),
			0.,
		} *
		1.0 /
		255.0

	ret.a = alpha

	return
}

