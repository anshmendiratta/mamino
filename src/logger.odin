#+feature dynamic-literals

package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:strings"
import "core:time"

import im "shared:dear_imgui"
import imgl "shared:dear_imgui/gl"
import imfw "shared:dear_imgui/glfw"

import gl "vendor:OpenGL"
import "vendor:glfw"

import "render"

Logger :: struct {
	times_per_frame: [dynamic]f64,
}

@(cold)
@(deferred_in = mamino_deinit_logger)
mamino_init_logger :: proc(logger: ^Logger) {
	render.last_frame = glfw.GetTime()
}

mamino_deinit_logger :: proc(logger: ^Logger) {
	delete(logger.times_per_frame)
}

logger_calculate_avg_fps :: proc(times_per_frame: [dynamic]f64) -> (avg: f64) {
	total_fps: f64 = 0
	for time_per_frame in times_per_frame {
		total_fps += 1 / time_per_frame
	}
	avg = total_fps / f64(len(times_per_frame))
	return
}

logger_record_frametime :: proc(logger: ^Logger) {
	time_for_frame := glfw.GetTime() - render.last_frame
	render.last_frame = glfw.GetTime()
	append(&logger^.times_per_frame, time_for_frame)
}

logger_get_most_recent_frametime :: proc(logger: ^Logger) -> f64 {
	return logger.times_per_frame[len(logger.times_per_frame) - 1]
}

logger_get_most_recent_framerate :: proc(logger: ^Logger) -> f64 {
	return 1. / logger.times_per_frame[len(logger.times_per_frame) - 1]
}

render_logger :: proc(logger: ^Logger) {
	// DearImgui window frame.
	imgl.NewFrame()
	imfw.NewFrame()
	im.NewFrame()

	viewport_size := im.GetMainViewport().Size
	im.SetNextWindowPos(im.GetMainViewport().Pos.x + viewport_size.x / 40)
	im.SetNextWindowSize(im.Vec2{viewport_size.x / 2.5, viewport_size.y / 7.})

	window_flags: im.WindowFlags
	window_flags += {.NoMove, .NoResize}
	im.Begin("Logger", &render.logger_open, window_flags)
	im.Text(
		strings.clone_to_cstring(
			(fmt.aprintf(
					"Average framerate: {:.1f}",
					logger_calculate_avg_fps(logger.times_per_frame),
				)),
			context.temp_allocator,
		),
	)
	im.Text(
		strings.clone_to_cstring(
			(fmt.aprintf(
					"Most recent framerate: {:.1f}",
					logger_get_most_recent_framerate(logger),
				)),
			context.temp_allocator,
		),
	)
	im.End()
	im.Render()
	imgl.RenderDrawData(im.GetDrawData())
}

