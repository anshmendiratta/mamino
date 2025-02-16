#+feature dynamic-literals

package main

import "core:c"
import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:os/os2"
import "core:slice"
import "core:strings"
import "core:time"

import "base:runtime"

import gl "vendor:OpenGL"
import "vendor:glfw"

import "objects"
import "render"
import "sequencing"

main :: proc() {
	// Init.
	render.mamino_init()
	defer glfw.Terminate()
	window := render.mamino_create_window()
	defer free(window)
	static_gl_data := render.mamino_gl_init()
	defer gl.DeleteProgram(static_gl_data.program_id)
	defer delete(static_gl_data.uniforms)

	// Setup scene.
	render_objects: []union {
		objects.Cube,
	} =
		{objects.Cube{center = {1., 1., 1.}, scale = {3., 1., 1.}, orientation = {glm.vec3{0., 1., 0.}, glm.radians(f32(45.))}}, objects.Cube{center = {-1., 1., -1.}, scale = {1., 2., 1.}, orientation = {glm.vec3{1., 1., 1.}, glm.radians(f32(35.))}}, objects.Cube{center = {0., 3., 2.}, scale = {0.5, 0.5, 0.5}, orientation = {glm.vec3{1., 0., 0.}, glm.radians(f32(60.))}}}

	// Init logger.
	logger: Logger = {{}}
	mamino_init_logger()
	defer delete(logger.times_per_frame)

	for (!glfw.WindowShouldClose(window) && render.running) {
		logger_record_frametime(&logger)

		// Input handling.
		glfw.PollEvents()
		render.update_camera()
		// Update (rotate) the vertices every frame.
		render.update_shader(static_gl_data.uniforms)

		gl.ClearColor(0., 0., 0., 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		render.render_objects(render_objects)
		// Axes rendered after objects to minimize overdraw.
		render.render_coordinate_axes()
		render.render_subgrid_axes()

		sequencing.mamino_capture_frame()

		render.WINDOW_WIDTH, render.WINDOW_HEIGHT = glfw.GetWindowSize(window)

		glfw.SwapBuffers(window)
		free_all(context.temp_allocator) // Frees most of the frames initializations.
	}
	glfw.DestroyWindow(window)

	avg_framerate := calculate_avg_fps(logger.times_per_frame)
	fmt.println("Average:", avg_framerate, "FPS")

	video_options: sequencing.VideoOptions = {
			resolution = {1920, 1080},
			framerate  = 180,
			encoding   = "libx264",
			out_name   = "vid.mp4",
		}
	if valid_vo := sequencing.validate_video_options(video_options); !valid_vo {
		fmt.eprintln("Incorrect export video options.")
		return
	}

	sequencing.mamino_exit(nil)
}

