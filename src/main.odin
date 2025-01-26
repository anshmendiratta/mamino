#+feature dynamic-literals

package main

import "core:c"
import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:mem"
import "core:time"

import gl "vendor:OpenGL"
import "vendor:glfw"

import objects "objects"
import "render"

main :: proc() {
	render.mamino_init()
	defer glfw.Terminate()

	window := render.mamino_create_window()
	defer glfw.DestroyWindow(window)

	// Load shaders.
	program, ok := gl.load_shaders_source(render.vertex_shader, render.fragment_shader)
	if !ok {
		fmt.eprintln("Could not load shaders.")
		return
	}
	gl.UseProgram(program)
	defer gl.DeleteProgram(program)

	// Uniforms.
	uniforms := gl.get_uniforms_from_program(program)
	defer delete(uniforms)

	gl.Enable(gl.DEPTH_TEST)
	// Debug to see wireframe of cube.
	// gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

	render_objects: []union {
		objects.Cube,
	} =
		{objects.Cube{center = {1., 1., 1.}, scale = {3., 1., 1.}, orientation = {glm.vec3{0., 1., 0.}, glm.radians(f32(45.))}}, objects.Cube{center = {-1., 1., -1.}, scale = {1., 2., 1.}, orientation = {glm.vec3{1., 1., 1.}, glm.radians(f32(35.))}}, objects.Cube{center = {0., 3., 2.}, scale = {0.5, 0.5, 0.5}, orientation = {glm.vec3{1., 0., 0.}, glm.radians(f32(60.))}}}

	// Initialize axes. Done outside the loop because this will always be done and rendered.
	axes_vao, axes_vbo, axes_ebo := render.get_buffer_objects()
	defer gl.DeleteVertexArrays(1, &axes_vao)
	defer gl.DeleteBuffers(1, &axes_vbo)
	defer gl.DeleteBuffers(1, &axes_ebo)

	logger: Logger = {{}}
	defer delete(logger.times_per_frame)

	last_frame := glfw.GetTime()

	for (!glfw.WindowShouldClose(window) && render.running) {
		// Performance stdout logging.
		time_for_frame := glfw.GetTime() - last_frame
		// fmt.println(1 / time_for_frame)
		last_frame = glfw.GetTime()
		append(&logger.times_per_frame, time_for_frame)

		// Process inputs.
		glfw.PollEvents()
		// Update cameras if necessary.
		render.update_camera()

		gl.ClearColor(0.1, 0.1, 0.1, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		for generic_object in render_objects {
			#partial switch object in generic_object {
			case objects.Cube:
				// Do not need to worry about the constant coloring below, as the below call copies over from the base cube, whose color is unchanging.
				cube_vertices := objects.get_vertices(object)
				defer delete(cube_vertices)
				// Cube.
				cube_vao, cube_vbo, cube_ebo := render.get_buffer_objects()
				render.bind_data(cube_vbo, cube_ebo, cube_vertices, objects.cube_indices)
				render.draw_cube(cube_vertices, i32(len(objects.cube_indices)))
				// Points.
				point_vao, point_vbo, point_ebo := render.get_buffer_objects()
				objects.color_vertices(cube_vertices, objects.point_color)
				render.bind_data(point_vbo, point_ebo, cube_vertices, objects.point_indices)
				render.draw_points(cube_vertices, objects.point_indices)
				// Lines.
				line_vao, line_vbo, line_ebo := render.get_buffer_objects()
				objects.color_vertices(cube_vertices, objects.line_color)
				render.bind_data(line_vbo, line_ebo, cube_vertices, objects.line_indices)
				render.draw_lines(cube_vertices, objects.line_indices)

				gl.DeleteVertexArrays(1, &cube_vao)
				gl.DeleteVertexArrays(1, &point_vao)
				gl.DeleteVertexArrays(1, &line_vao)
				gl.DeleteBuffers(1, &cube_vbo)
				gl.DeleteBuffers(1, &cube_ebo)
				gl.DeleteBuffers(1, &point_vbo)
				gl.DeleteBuffers(1, &point_ebo)
				gl.DeleteBuffers(1, &line_vbo)
				gl.DeleteBuffers(1, &line_ebo)
			case:
			}
		}

		// Update (rotate) the vertices every frame.
		render.update_shader(uniforms)

		// Axes.
		render.bind_data(axes_vbo, axes_ebo, objects.axes_vertices, objects.axes_indices)
		render.draw_axes(objects.axes_indices)

		// NOTE: Defaults to double buffering I think? - Ansh
		// See https://en.wikipedia.org/wiki/Multiple_buffering to learn more about Multiple buffering
		// https://www.glfw.org/docs/3.0/group__context.html#ga15a5a1ee5b3c2ca6b15ca209a12efd14
		glfw.SwapBuffers(window)
	}

	// fmt.println("Average:", calculate_avg_fps(logger.times_per_frame), "FPS")
	render.mamino_exit()
}

