#+feature dynamic-literals

package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:time"

import gl "vendor:OpenGL"
import "vendor:glfw"

import "render"

last_frame: f64 = 0.

Logger :: struct {
	times_per_frame: [dynamic]f64,
}

@(cold)
mamino_init_logger :: proc() {
	last_frame = glfw.GetTime()
}

calculate_avg_fps :: proc(times_per_frame: [dynamic]f64) -> (avg: f64) {
	total_fps: f64 = 0
	for time_per_frame in times_per_frame {
		total_fps += 1 / time_per_frame
	}
	avg = total_fps / f64(len(times_per_frame))
	return
}

logger_record_frametime :: proc(logger: ^Logger) {
	time_for_frame := glfw.GetTime() - last_frame
	last_frame = glfw.GetTime()
	append(&logger^.times_per_frame, time_for_frame)
}

