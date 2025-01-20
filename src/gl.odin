#+feature dynamic-literals

package main

import "core:c"
import "core:fmt"

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

mamino_init :: proc() {
	// https://www.glfw.org/docs/3.3/window_guide.html#window_hints
	// https://www.glfw.org/docs/3.3/group__window.html#ga7d9c8c62384b1e2821c4dc48952d2033
	glfw.WindowHint(glfw.RESIZABLE, 1)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	// MacOS.
	if ODIN_OS_STRING == "darwin" {
		glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, gl.TRUE)
		glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
		glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 1)
	} else {
		glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
		glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	}

	// https://www.glfw.org/docs/latest/group__init.html#ga317aac130a235ab08c6db0834907d85e
	if !glfw.Init() {
		fmt.println("Failed to initialize GLFW")
		return
	}
}

mamino_create_window :: proc() -> glfw.WindowHandle {
	window := glfw.CreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, PROGRAM_NAME, nil, nil)
	if window == nil {
		fmt.println("Unable to create window")
		return nil
	}

	// https://www.glfw.org/docs/3.3/group__context.html#ga1c04dc242268f827290fe40aa1c91157
	glfw.MakeContextCurrent(window)
	// https://www.glfw.org/docs/3.3/group__context.html#ga6d4e0cdf151b5e579bd67f13202994ed
	glfw.SwapInterval(1)
	// https://www.glfw.org/docs/3.3/group__input.html#ga1caf18159767e761185e49a3be019f8d
	glfw.SetKeyCallback(window, key_callback)
	// https://www.glfw.org/docs/3.3/group__window.html#gab3fb7c3366577daef18c0023e2a8591f
	glfw.SetFramebufferSizeCallback(window, size_callback)
	// Set OpenGL Context bindings using the helper function
	// See Odin Vendor source for specifc implementation details
	// https://github.com/odin-lang/Odin/tree/master/vendor/OpenGL
	// https://www.glfw.org/docs/3.3/group__context.html#ga35f1837e6f666781842483937612f163
	gl.load_up_to(int(GL_MAJOR_VERSION), GL_MINOR_VERSION, glfw.gl_set_proc_address)

	return window
}

draw_cube :: proc(vertices: []Vertex) {
	gl.Enable(gl.DEPTH_TEST)
	gl.DepthFunc(gl.LESS)
	gl.DrawArrays(gl.TRIANGLES, 0, i32(len(vertices)))
}

draw_points :: proc(vertices: []Vertex) {
	// gl.Enable(gl.DEPTH_TEST)
	// gl.DepthFunc(gl.LESS)
	gl.Enable(gl.PROGRAM_POINT_SIZE)
	gl.Enable(gl.POINT_SMOOTH)
	gl.DrawArrays(gl.POINTS, 0, i32(len(vertices)))
}

// TODO: Termination code here
exit :: proc() {
}

get_cube_objects :: proc() -> (u32, u32, u32) {
	// Get Vertex arrays.
	triangle_vao: u32
	gl.GenVertexArrays(1, &triangle_vao)
	// Get Vertex buffer objects, and Element Buffer Objects (?)
	triangle_vbo, triangle_ebo: u32
	gl.GenBuffers(1, &triangle_vbo)
	gl.GenBuffers(1, &triangle_ebo)

	return triangle_vao, triangle_vbo, triangle_ebo
}

get_point_objects :: proc() -> (u32, u32, u32) {
	// Get Vertex arrays.
	point_vao: u32
	gl.GenVertexArrays(1, &point_vao)
	// Get Vertex buffer objects, and Element Buffer Objects (?)
	point_vbo, point_ebo: u32
	gl.GenBuffers(1, &point_vbo)
	gl.GenBuffers(1, &point_ebo)

	return point_vao, point_vbo, point_ebo
}

bind_data :: proc(
	cube_vao: u32,
	cube_vbo: u32,
	cube_ebo: u32,
	data: [dynamic]Vertex,
	indices: [dynamic]u16,
) {
	// Bind vertices to vertex buffer.
	gl.BindBuffer(gl.ARRAY_BUFFER, cube_vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(data) * size_of(Vertex), raw_data(data), gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))

	// Bind vertex array indices to index buffer.
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, cube_ebo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(indices) * size_of(u16),
		raw_data(indices),
		gl.STATIC_DRAW,
	)
}

// bind_point_data :: proc(
// 	point_vao: u32,
// 	point_vbo: u32,
// 	point_ebo: u32,
// 	data: [dynamic]glm.vec3,
// 	indices: [dynamic]u16,
// ) {
// 	// Bind vertices to vertex buffer.
// 	gl.BindBuffer(gl.ARRAY_BUFFER, point_vao)
// 	gl.BufferData(gl.ARRAY_BUFFER, len(data) * size_of(glm.vec3), raw_data(data), gl.STATIC_DRAW)
// 	gl.EnableVertexAttribArray(0)
// 	gl.EnableVertexAttribArray(1)
// 	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(glm.vec3), size_of(glm.vec3))
// 	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(glm.vec3), size_of(glm.vec3))

// 	// Bind vertex array indices to index buffer.
// 	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, point_vbo)
// 	gl.BufferData(
// 		gl.ELEMENT_ARRAY_BUFFER,
// 		len(indices) * size_of(u16),
// 		raw_data(indices),
// 		gl.STATIC_DRAW,
// 	)
// }

