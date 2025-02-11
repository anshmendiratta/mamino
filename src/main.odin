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

import "animation"
import "objects"
import "render"

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
	allocator: runtime.Allocator
	animation.delete_previous_frames()
	animation.make_frames_directory()

	stored_frames: [dynamic][]u32

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

		// pixels := make([]u32, render.WINDOW_WIDTH * render.WINDOW_HEIGHT)
		// defer delete(pixels)
		// text_texture_id := render.get_texture_id(pixels)
		// gl.BindTexture(gl.TEXTURE_2D, text_texture_id)

		// Get data throuugh a PBO from the framebuffer and write it to an image. `frame_count` needed for file naming.
		// current_pbo_idx := 0
		// image_data := animation.capture_frame(current_pbo_idx)
		// defer delete(image_data)
		// append(&stored_frames, image_data)
		// current_pbo_idx = 1 - current_pbo_idx

		// Update window sizes.
		render.WINDOW_WIDTH, render.WINDOW_HEIGHT = glfw.GetWindowSize(window)

		// NOTE(Ansh): Defaults to double buffering. 
		// See https://en.wikipedia.org/wiki/Multiple_buffering to learn more about Multiple buffering
		// https://www.glfw.org/docs/3.0/group__context.html#ga15a5a1ee5b3c2ca6b15ca209a12efd14
		glfw.SwapBuffers(window)
	}
	glfw.DestroyWindow(window)

	avg_framerate := calculate_avg_fps(logger.times_per_frame)
	fmt.println("Average:", avg_framerate, "FPS")

	// Write images.
	// animation.write_frames(stored_frames)
	// Composite video using ffmpeg.
	// animation.ffmpeg_composite_video(avg_framerate)

	render.mamino_exit()
}

