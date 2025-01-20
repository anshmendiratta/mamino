package main

import "core:c"
import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:time"

import gl "vendor:OpenGL"
import "vendor:glfw"

import "render"

main :: proc() {
	render.mamino_init()
	// NOTE: `defer`s are executed in reverse, like popping from a stack.
	// https://odin-lang.org/docs/overview/#defer-statement
	// https://www.glfw.org/docs/3.1/group__init.html#gaaae48c0a18607ea4a4ba951d939f0901
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

	gl.Enable(gl.DEPTH_TEST)
	// debug to see wireframe of cube
	// gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

	// Uniforms.
	uniforms := gl.get_uniforms_from_program(program)
	defer delete(uniforms)

	// Initialize cube.
	cube_vao, cube_vbo, cube_ebo := render.get_cube_objects()
	defer gl.DeleteVertexArrays(1, &cube_vao)
	defer gl.DeleteBuffers(1, &cube_vbo)
	defer gl.DeleteBuffers(1, &cube_ebo)

	// Initialize points.
	point_vao, point_vbo, point_ebo := render.get_point_objects()
	defer gl.DeleteVertexArrays(1, &point_vao)
	defer gl.DeleteBuffers(1, &point_vbo)
	defer gl.DeleteBuffers(1, &point_ebo)
	// todo: figure out why points rely on indexed drawing if
	// draw_points does not rely on EBO
	point_indices: []u16 = {0, 1, 2, 3, 4, 5, 6, 7}

	// assuming LHS (openGL is usually in a RHS but due to device normalization it is in a LHS (?))

	// Initialize lines.
	line_vao, line_vbo, line_ebo := render.get_line_objects()
	defer gl.DeleteVertexArrays(1, &line_vao)
	defer gl.DeleteBuffers(1, &line_vbo)
	defer gl.DeleteBuffers(1, &line_ebo)

	time_init := time.tick_now()
	// Check for window events.
	for (!glfw.WindowShouldClose(window) && render.running) {
		// https://www.glfw.org/docs/3.3/group__window.html#ga37bd57223967b4211d60ca1a0bf3c832
		glfw.PollEvents()

		time_ticks := time.tick_since(time_init)
		time_s := time.duration_seconds(time.Duration(time_ticks))

		// Clear the screen with some color. RGBA values are normalized to be within [0.0, 1.0].
		gl.ClearColor(0.1, 0.1, 0.1, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		// Update (rotate) the vertices every frame.
		render.update(cube_vertices, uniforms, time_s)
		render.update(point_vertices, uniforms, time_s)
		render.update(line_vertices, uniforms, time_s)

		// CUBE
		render.bind_data(cube_vbo, cube_ebo, cube_vertices, cube_indices)
		render.draw_cube(cube_indices[:])

		// POINTS
		render.bind_data(point_vbo, point_ebo, point_vertices, point_indices)
		render.draw_points(point_vertices[:])

		// LINES
		render.bind_data(line_vbo, line_ebo, line_vertices, line_indices)
		render.draw_lines(line_indices[:])

		// NOTE: Defaults to double buffering I think? - Ansh
		// See https://en.wikipedia.org/wiki/Multiple_buffering to learn more about Multiple buffering
		// https://www.glfw.org/docs/3.0/group__context.html#ga15a5a1ee5b3c2ca6b15ca209a12efd14
		glfw.SwapBuffers(window)
	}

	render.mamino_exit()
}

