#+feature dynamic-literals

package main

import "core:c"
import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:mem"
import "core:os/os2"
import "core:slice"
import "core:strings"
import "core:time"

import im "shared:dear_imgui"
import imgl "shared:dear_imgui/gl"
import imfw "shared:dear_imgui/glfw"

import "base:runtime"

import gl "vendor:OpenGL"
import "vendor:glfw"

import "objects"
import "render"
import "sequencing"

main :: proc() {
	// Init.
	render.mamino_init()
	window := render.mamino_create_window()
	render.mamino_init_imgui(window)
	// TODO: Find out why this segfaults. "Bad free of pointer" with tracking allocator.
	static_gl_data := render.mamino_init_gl()
	sequencing.mamino_frame_capture_init()

	// Init logger.
	logger: ^Logger = &{{}}
	mamino_init_logger(logger)

	// Setup scene objects.
	render_objects: []union {
		objects.Cube,
	} =
		{objects.Cube{center = {1., 1., 1.}, scale = {3., 1., 1.}, orientation = {glm.vec3{0., 1., 0.}, glm.radians(f32(45.))}}, objects.Cube{center = {-1., 1., -1.}, scale = {1., 2., 1.}, orientation = {glm.vec3{1., 1., 1.}, glm.radians(f32(35.))}}, objects.Cube{center = {0., 3., 2.}, scale = {0.5, 0.5, 0.5}, orientation = {glm.vec3{1., 0., 0.}, glm.radians(f32(60.))}}}

	for (!glfw.WindowShouldClose(window) && render.running) {
		logger_record_frametime(logger)

		// Set background.
		gl.ClearColor(0., 0., 0., 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		// Input handling.
		glfw.PollEvents()
		render.update_camera()
		// Update (rotate) the vertices every frame.
		render.update_shader(static_gl_data.uniforms)

		render.render_objects(render_objects)
		render.render_coordinate_axes()
		render.render_subgrid_axes()

		render_logger(logger)

		// sequencing.mamino_capture_frame()

		render.WINDOW_WIDTH, render.WINDOW_HEIGHT = glfw.GetWindowSize(window)

		glfw.SwapBuffers(window)
		free_all(context.temp_allocator) // Frees most of the frames initializations.
	}
	glfw.DestroyWindow(window)

	avg_framerate := logger_calculate_avg_fps(logger.times_per_frame)
	fmt.println("Average:", avg_framerate, "FPS")

	video_options: sequencing.VideoOptions = {
			resolution = {1920, 1080},
			framerate  = 180,
			encoding   = "libx264",
			out_name   = "vid.h264",
		}
	if valid_vo := sequencing.validate_video_options(video_options); !valid_vo {
		fmt.eprintln("Incorrect export video options.")
		return
	}

	// NOTE(Ansh): vo = nil does NOT composite a video.
	sequencing.mamino_exit(nil)
}

