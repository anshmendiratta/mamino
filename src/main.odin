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

	// TODO: unsure why we are getting uniforms if not using uniforms in shaders currently
	// Uniforms.
	// uniforms := gl.get_uniforms_from_program(program)
	// defer delete(uniforms)

	// Initialize cube.
	cube_vao, cube_vbo, cube_ebo := render.get_objects()
	defer gl.DeleteVertexArrays(1, &cube_vao)
	defer gl.DeleteBuffers(1, &cube_vbo)
	defer gl.DeleteBuffers(1, &cube_ebo)

	colors: []glm.vec3 = {
		rgb_hex_to_color(0xD3_47_3D), // red
		rgb_hex_to_color(0xF5_EF_EB), // white
		rgb_hex_to_color(0xF6_AD_0F), // orange
		rgb_hex_to_color(0x31_6A_96), // blue
		rgb_hex_to_color(0x2E_24_3F), // purple
		rgb_hex_to_color(0x86_BC_D1), // light blue
		rgb_hex_to_color(0xFC_D7_03), // yellow
		rgb_hex_to_color(0x03_FC_13), // green
	}

	// Initialize points.
	point_vao, point_vbo, point_ebo := render.get_objects()
	defer gl.DeleteVertexArrays(1, &point_vao)
	defer gl.DeleteBuffers(1, &point_vbo)
	defer gl.DeleteBuffers(1, &point_ebo)

	point_color: glm.vec3 = rgb_hex_to_color(0xF8_03_FC)
	
	// assuming LHS (openGL is usually in a RHS but due to device normalization it is in a LHS (?))
	point_vertices: []render.Vertex = {
		{{ 0.5,  0.5,  0.5}, point_color /* colors[0] */}, // right    top  back
		{{-0.5,  0.5,  0.5}, point_color /* colors[1] */}, //  left    top  back
		{{ 0.5, -0.5,  0.5}, point_color /* colors[2] */}, // right bottom  back
		{{ 0.5,  0.5, -0.5}, point_color /* colors[3] */}, // right    top front
		{{-0.5, -0.5,  0.5}, point_color /* colors[4] */}, //  left bottom  back
		{{ 0.5, -0.5, -0.5}, point_color /* colors[5] */}, // right bottom front
		{{-0.5,  0.5, -0.5}, point_color /* colors[6] */}, //  left    top front
		{{-0.5, -0.5, -0.5}, point_color /* colors[7] */}, //  left bottom front
	}
	// todo: figure out why points rely on indexed drawing if
	// draw_points does not rely on EBO
	point_indices: []u16 = {0, 1, 2, 3, 4, 5, 6, 7}

	// assuming LHS (openGL is usually in a RHS but due to device normalization it is in a LHS (?))
	cube_vertices: []render.Vertex = {
		{{ 0.5,  0.5,  0.5}, colors[0]}, // right    top  back
		{{-0.5,  0.5,  0.5}, colors[1]}, //  left    top  back
		{{ 0.5, -0.5,  0.5}, colors[2]}, // right bottom  back
		{{ 0.5,  0.5, -0.5}, colors[3]}, // right    top front
		{{-0.5, -0.5,  0.5}, colors[4]}, //  left bottom  back
		{{ 0.5, -0.5, -0.5}, colors[5]}, // right bottom front
		{{-0.5,  0.5, -0.5}, colors[6]}, //  left    top front
		{{-0.5, -0.5, -0.5}, colors[7]}, //  left bottom front
	}
	// creating each face with two triangles and using indexed drawing to do so
	cube_indices: []u16 = {
		0, 1, 2, 2, 4, 1, // back face
		3, 6, 5, 5, 7, 6, // front face
		0, 1, 3, 3, 6, 1, // top face
		2, 4, 5, 5, 7, 4, // bottom face
		1, 6, 4, 4, 7, 6, // left face
		0, 3, 2, 2, 5, 3, // right face
	}

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

		// TODO: unsure why this is still here as they shouldn't be needed
		
		// TODO: Find a way to use `BufferSubData` instead. Using `BufferData` works but reallocates memory.
		// Rebind the updated vertices to the vertex buffer.
		// gl.BufferData(
		// 	gl.ARRAY_BUFFER,
		// 	len(cube_vertices) * size_of(render.Vertex),
		// 	raw_data(cube_vertices),
		// 	gl.STATIC_DRAW,
		// )

		render.bind_data(cube_vao, cube_vbo, cube_ebo, cube_vertices, cube_indices)
		render.draw_cube(cube_indices[:])

		gl.DisableVertexAttribArray(0)
		gl.DisableVertexAttribArray(1)

		// TODO: unsure why this is still here as they shouldn't be needed

		// gl.BufferData(
		// 	gl.ARRAY_BUFFER,
		// 	len(point_vertices) * size_of(render.Vertex),
		// 	raw_data(point_vertices),
		// 	gl.STATIC_DRAW,
		// )

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

