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

import "objects"
import "render"

Logger :: struct {
	frametimes:      [dynamic]f64,
	object_count:    uint,
	camera_position: glm.vec3,
}

@(cold)
@(deferred_in = mamino_deinit_logger)
mamino_init_logger :: proc(logger: ^Logger, objects: []union {
		objects.Cube,
	}) {
	render.last_frame = glfw.GetTime()
	logger.object_count = len(objects)
	logger.camera_position = render.camera_position_cartesian
}

mamino_deinit_logger :: proc(logger: ^Logger, _: []union {
		objects.Cube,
	}) {
	delete(logger.frametimes)
}

logger_calculate_avg_fps :: proc(times_per_frame: [dynamic]f64) -> (avg: f64) {
	total_fps: f64 = 0
	for time_per_frame in times_per_frame {
		total_fps += 1 / time_per_frame
	}
	avg = total_fps / f64(len(times_per_frame))
	return
}

logger_update :: proc(logger: ^Logger) {
	// Frametime.
	time_for_frame := glfw.GetTime() - render.last_frame
	render.last_frame = glfw.GetTime()
	append(&logger^.frametimes, time_for_frame)

	// FIX(Ansh): Find a way to avoid calculating this every frame. Not too expensivee, but would be nice to have gone.
	// Camera position.
	logger.camera_position = render.get_cartesian_coordinates(render.camera_position_spherical)
}

logger_get_most_recent_frametime :: proc(logger: ^Logger) -> f64 {
	return logger.frametimes[len(logger.frametimes) - 1]
}

logger_get_most_recent_framerate :: proc(logger: ^Logger) -> f64 {
	return 1. / logger.frametimes[len(logger.frametimes) - 1]
}

render_logger :: proc(logger: ^Logger) {
	imgl.NewFrame()
	imfw.NewFrame()
	im.NewFrame()

	viewport_size := im.GetMainViewport().Size
	im.SetNextWindowPos(im.GetMainViewport().Pos.x + viewport_size.x / 40)
	im.SetNextWindowSize(im.Vec2{viewport_size.x / 2.5, viewport_size.y / 7.})

	window_flags: im.WindowFlags
	window_flags += {.NoMove}
	im.Begin("Logger", &render.logger_open, window_flags)
	im.TextWrapped(
		strings.clone_to_cstring(
			(fmt.aprintf(
					"Average framerate: {:.1f}",
					logger_calculate_avg_fps(logger.frametimes),
				)),
			context.temp_allocator,
		),
		context.temp_allocator,
	)
	im.TextWrapped(
		strings.clone_to_cstring(
			(fmt.aprintf(
					"Most recent framerate: {:.1f}",
					logger_get_most_recent_framerate(logger),
				)),
			context.temp_allocator,
		),
		context.temp_allocator,
	)
	im.TextWrapped(
		strings.clone_to_cstring(
			(fmt.aprintf(
					"Most recent frametime: {:.1f}",
					logger_get_most_recent_frametime(logger),
				)),
			context.temp_allocator,
		),
		context.temp_allocator,
	)
	im.Separator()
	im.TextWrapped(
		strings.clone_to_cstring(
			fmt.aprintf("Object count: {}", logger.object_count),
			context.temp_allocator,
		),
		context.temp_allocator,
	)
	im.TextWrapped(
		strings.clone_to_cstring(
			fmt.aprintf(
				"Camera position (x, y, z): ({}, {}, {})",
				logger.camera_position.x,
				logger.camera_position.y,
				logger.camera_position.z,
			),
			context.temp_allocator,
		),
		context.temp_allocator,
	)
	im.Separator()
	im.End()
	im.Render()
	imgl.RenderDrawData(im.GetDrawData())
}

