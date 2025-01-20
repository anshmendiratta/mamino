#+feature dynamic-literals

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

	// Uniforms.
	uniforms := gl.get_uniforms_from_program(program)
	defer delete(uniforms)

	// Initialize cube.
	cube_vao, cube_vbo, cube_ebo := render.get_cube_objects()
	defer gl.DeleteVertexArrays(1, &cube_vao)
	defer gl.DeleteBuffers(1, &cube_vbo)
	defer gl.DeleteBuffers(1, &cube_ebo)
	cube_colors: [dynamic]glm.vec3 = generate_n_colors(36)
	vertex_color: glm.vec3
	cube_indices: [dynamic]u16
	cube_vertices: [dynamic]render.Vertex = {
		{{-0.5, -0.5, -0.5}, vertex_color},
		{{-0.5, -0.5, 0.5}, vertex_color},
		{{-0.5, 0.5, 0.5}, vertex_color},
		{{0.5, 0.5, -0.5}, vertex_color},
		{{-0.5, -0.5, -0.5}, vertex_color},
		{{-0.5, 0.5, -0.5}, vertex_color},
		{{0.5, -0.5, 0.5}, vertex_color},
		{{-0.5, -0.5, -0.5}, vertex_color},
		{{0.5, -0.5, -0.5}, vertex_color},
		{{0.5, 0.5, -0.5}, vertex_color},
		{{0.5, -0.5, -0.5}, vertex_color},
		{{-0.5, -0.5, -0.5}, vertex_color},
		{{-0.5, -0.5, -0.5}, vertex_color},
		{{-0.5, 0.5, 0.5}, vertex_color},
		{{-0.5, 0.5, -0.5}, vertex_color},
		{{0.5, -0.5, 0.5}, vertex_color},
		{{-0.5, -0.5, 0.5}, vertex_color},
		{{-0.5, -0.5, -0.5}, vertex_color},
		{{-0.5, 0.5, 0.5}, vertex_color},
		{{-0.5, -0.5, 0.5}, vertex_color},
		{{0.5, -0.5, 0.5}, vertex_color},
		{{0.5, 0.5, 0.5}, vertex_color},
		{{0.5, -0.5, -0.5}, vertex_color},
		{{0.5, 0.5, -0.5}, vertex_color},
		{{0.5, -0.5, -0.5}, vertex_color},
		{{0.5, 0.5, 0.5}, vertex_color},
		{{0.5, -0.5, 0.5}, vertex_color},
		{{0.5, 0.5, 0.5}, vertex_color},
		{{0.5, 0.5, -0.5}, vertex_color},
		{{-0.5, 0.5, -0.5}, vertex_color},
		{{0.5, 0.5, 0.5}, vertex_color},
		{{-0.5, 0.5, -0.5}, vertex_color},
		{{-0.5, 0.5, 0.5}, vertex_color},
		{{0.5, 0.5, 0.5}, vertex_color},
		{{-0.5, 0.5, 0.5}, vertex_color},
		{{0.5, -0.5, 0.5}, vertex_color},
	}
	{
		for color, idx in cube_colors {
			cube_vertices[idx].color = color
		}
		for index in 0 ..< 36 {
			append(&cube_indices, u16(index))
		}
	}

	// Initialize points.
	point_vao, point_vbo, point_ebo := render.get_point_objects()
	defer gl.DeleteVertexArrays(1, &point_vao)
	defer gl.DeleteBuffers(1, &point_vbo)
	defer gl.DeleteBuffers(1, &point_ebo)
	point_color: glm.vec3 = {1., 1., 1.}
	point_vertices: [dynamic]render.Vertex = {
		{{0.5, 0.5, 0.5}, point_color},
		{{-0.5, 0.5, 0.5}, point_color},
		{{0.5, -0.5, 0.5}, point_color},
		{{0.5, 0.5, -0.5}, point_color},
		{{-0.5, -0.5, 0.5}, point_color},
		{{0.5, -0.5, -0.5}, point_color},
		{{-0.5, 0.5, -0.5}, point_color},
		{{-0.5, -0.5, -0.5}, point_color},
	}
	point_indices: [dynamic]u16 = {0, 1, 2, 3, 4, 5, 6, 7}

	// Check for window events.
	for (!glfw.WindowShouldClose(window) && render.running) {
		// https://www.glfw.org/docs/3.3/group__window.html#ga37bd57223967b4211d60ca1a0bf3c832
		glfw.PollEvents()

		// Clear the screen with some color. RGBA values are normalized to be within [0.0, 1.0].
		gl.ClearColor(0.1, 0.1, 0.1, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		// Update (rotate) the vertices every frame.
		cube_vertices = render.update(cube_vertices)
		point_vertices = render.update(point_vertices)

		// TODO: Find a way to use `BufferSubData` instead. Using `BufferData` works but reallocates memory.
		// Rebind the updated vertices to the vertex buffer.
		gl.BufferData(
			gl.ARRAY_BUFFER,
			len(cube_vertices) * size_of(render.Vertex),
			raw_data(cube_vertices),
			gl.STATIC_DRAW,
		)

		render.bind_data(cube_vao, cube_vbo, cube_ebo, cube_vertices, cube_indices)
		render.draw_cube(cube_vertices[:])

		gl.DisableVertexAttribArray(0)
		gl.DisableVertexAttribArray(1)

		gl.BufferData(
			gl.ARRAY_BUFFER,
			len(point_vertices) * size_of(render.Vertex),
			raw_data(point_vertices),
			gl.STATIC_DRAW,
		)

		render.bind_data(point_vao, point_vbo, point_ebo, point_vertices, cube_indices)
		render.draw_points(point_vertices[:])

		gl.DisableVertexAttribArray(0)
		gl.DisableVertexAttribArray(1)

		// NOTE: Defaults to double buffering I think? - Ansh
		// See https://en.wikipedia.org/wiki/Multiple_buffering to learn more about Multiple buffering
		// https://www.glfw.org/docs/3.0/group__context.html#ga15a5a1ee5b3c2ca6b15ca209a12efd14
		glfw.SwapBuffers(window)
	}

	render.mamino_exit()
}

