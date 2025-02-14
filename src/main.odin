#+feature dynamic-literals

package main

import "core:c"
import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:os/os2"
import "core:strings"
import "core:time"

import "base:runtime"

import gl "vendor:OpenGL"
import "vendor:glfw"

import "objects"
import "render"
import "sequencing"

main :: proc() {
	// Setup.
	render.mamino_init()
	defer glfw.Terminate()
	window := render.mamino_create_window()
	// Window destruction happens a bit before the ending of main so that the window closes before the video is being encoded.
	program, ok := gl.load_shaders_source(
		render.mamino_vertex_shader,
		render.mamino_fragment_shader,
	)
	if !ok {
		fmt.eprintln("Could not load shaders.")
		return
	}
	gl.UseProgram(program)
	defer gl.DeleteProgram(program)
	uniforms := gl.get_uniforms_from_program(program)
	defer delete(uniforms)
	gl.Enable(gl.DEPTH_TEST)
	// Debug to see wireframe of cube.
	// gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

	render_objects: []union {
		objects.Cube,
	} =
		{objects.Cube{center = {1., 1., 1.}, scale = {3., 1., 1.}, orientation = {glm.vec3{0., 1., 0.}, glm.radians(f32(45.))}}, objects.Cube{center = {-1., 1., -1.}, scale = {1., 2., 1.}, orientation = {glm.vec3{1., 1., 1.}, glm.radians(f32(35.))}}, objects.Cube{center = {0., 3., 2.}, scale = {0.5, 0.5, 0.5}, orientation = {glm.vec3{1., 0., 0.}, glm.radians(f32(60.))}}}

	logger: Logger = {{}}
	defer delete(logger.times_per_frame)

	last_frame := glfw.GetTime()

	// Reset the `frames/` directory. Create it if it doesn't exist.
	sequencing.delete_previous_frames()
	sequencing.make_frames_directory()
	video_options: sequencing.VideoOptions = {
			resolution = {1920, 1080},
			framerate  = 60,
			encoding   = "libx264",
			out_name   = "vid.mp4",
		}

	// Prepare for frame data.
	pixels_pbos: [2]u32
	gl.GenBuffers(1, &pixels_pbos[0])
	gl.GenBuffers(1, &pixels_pbos[1])
	defer gl.DeleteBuffers(1, &pixels_pbos[0])
	defer gl.DeleteBuffers(1, &pixels_pbos[1])
	current_pbo_idx := 0
	stored_frames: [dynamic][]u32 = {}
	frame_copy: []u32 = make([]u32, render.WINDOW_WIDTH * render.WINDOW_HEIGHT)

	for (!glfw.WindowShouldClose(window) && render.running) {
		// Performance stdout logging.
		time_for_frame := glfw.GetTime() - last_frame
		last_frame = glfw.GetTime()
		append(&logger.times_per_frame, time_for_frame)

		// Process inputs and update the camera if necessary.
		glfw.PollEvents()
		render.update_camera()
		// Update (rotate) the vertices every frame.
		render.update_shader(uniforms)

		// Set background color.
		gl.ClearColor(0., 0., 0., 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		// Render all scene objects and axes. Axes rendered after objects to minimize its overdraw.
		render.render_objects(render_objects)
		render.render_coordinate_axes()
		render.render_subgrid_axes()

		// Get data throuugh a PBO from the framebuffer and write it to an image. `frame_count` needed for file naming.
		image_data := sequencing.capture_frame(pixels_pbos[current_pbo_idx])
		copy(frame_copy, image_data)
		append(&stored_frames, image_data)
		current_pbo_idx = current_pbo_idx ~ 1

		// Update window sizes.
		render.WINDOW_WIDTH, render.WINDOW_HEIGHT = glfw.GetWindowSize(window)

		// NOTE(Ansh): Defaults to double buffering. 
		glfw.SwapBuffers(window)

		free_all(context.temp_allocator)
	}
	glfw.DestroyWindow(window)

	avg_framerate := calculate_avg_fps(logger.times_per_frame)
	fmt.println("Average:", avg_framerate, "FPS")

	// Write images.
	// sequencing.write_frames(stored_frames)
	// Composite video using ffmpeg.
	// sequencing.ffmpeg_composite_video(video_options)

	render.mamino_exit()
}

