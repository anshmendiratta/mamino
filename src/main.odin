#+feature dynamic-literals

package main

import "core:c"
import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:strings"
import "core:time"

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
	defer glfw.DestroyWindow(window)
	program, ok := gl.load_shaders_source(render.vertex_shader, render.fragment_shader)
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

	frame_count := 0
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
		gl.ClearColor(0.1, 0.1, 0.1, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		// Render all scene objects and axes. Axes rendered after objects to minimize its overdraw.
		render.render_objects(render_objects)
		render.render_axes()

		// Get framebuffers and draw image.
		pixels: []u32 = animation.get_framebuffer()
		defer delete(pixels)
		image_name := fmt.aprintf("frames/img_{}.png", frame_count)
		animation.write_png(
			strings.clone_to_cstring(image_name),
			render.WINDOW_WIDTH,
			render.WINDOW_HEIGHT,
			4,
			pixels,
			render.WINDOW_WIDTH * 4,
		)
		frame_count += 1

		// Update window sizes.
		render.WINDOW_WIDTH, render.WINDOW_HEIGHT = glfw.GetWindowSize(window)

		// NOTE: Defaults to double buffering I think? - Ansh
		// See https://en.wikipedia.org/wiki/Multiple_buffering to learn more about Multiple buffering
		// https://www.glfw.org/docs/3.0/group__context.html#ga15a5a1ee5b3c2ca6b15ca209a12efd14
		glfw.SwapBuffers(window)
	}

	// Composite video using ffmpeg.
	animation.ffmpeg_composite_video()

	fmt.println("Average:", calculate_avg_fps(logger.times_per_frame), "FPS")
	render.mamino_exit()
}

