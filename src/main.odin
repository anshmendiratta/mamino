#+feature dynamic-literals

package main

import "core:c"
import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:time"

import gl "vendor:OpenGL"
import "vendor:glfw"


// Called when glfw keystate changes
key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if key == glfw.KEY_ESCAPE || key == glfw.KEY_Q {
		running = false
	}
}

// Called when glfw window changes size
size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

PROGRAM_NAME :: "mamino"

// Default values for not-MacOS.
GL_MAJOR_VERSION: c.int : 4
GL_MINOR_VERSION :: 6

WINDOW_WIDTH :: 512
WINDOW_HEIGHT :: 512

running: b32 = true

Vertex :: struct {
	position: glm.vec4,
	color:    glm.vec4,
}

main :: proc() {
	mamino_init()
	// NOTE: `defer`s are executed in reverse, like popping from a stack.
	// https://odin-lang.org/docs/overview/#defer-statement
	// https://www.glfw.org/docs/3.1/group__init.html#gaaae48c0a18607ea4a4ba951d939f0901
	defer glfw.Terminate()

	window := mamino_create_window()
	defer glfw.DestroyWindow(window)

	// Load shaders.
	program, ok := gl.load_shaders_source(vertex_shader, fragment_shader)
	if !ok {
		fmt.eprintln("Could not load shaders.")
		return
	}
	gl.UseProgram(program)
	defer gl.DeleteProgram(program)

	// Uniforms.
	uniforms := gl.get_uniforms_from_program(program)
	defer delete(uniforms)

	// Get Vertex arrays.
	triangle_vao: u32
	gl.GenVertexArrays(1, &triangle_vao)
	defer gl.DeleteVertexArrays(1, &triangle_vao)

	// Get Vertex buffer objects, and eto (?).
	triangle_vbo, triangle_ebo: u32
	gl.GenBuffers(1, &triangle_vbo)
	gl.GenBuffers(1, &triangle_ebo)
	defer gl.DeleteBuffers(1, &triangle_vbo)
	defer gl.DeleteBuffers(1, &triangle_ebo)

	// Initialize polygon.
	polygon_color: [dynamic]glm.vec4 = generate_n_colors(36)
	vertex_color: glm.vec4 = {0.8, 0.8, 0.8, 1.}
	vertices: [dynamic]Vertex = {
		{{-0.5, -0.5, -0.5, 1.0}, vertex_color},
		{{-0.5, -0.5, 0.5, 1.0}, vertex_color},
		{{-0.5, 0.5, 0.5, 1.0}, vertex_color},
		{{0.5, 0.5, -0.5, 1.0}, vertex_color},
		{{-0.5, -0.5, -0.5, 1.0}, vertex_color},
		{{0.5, 0.5, -0.5, 1.0}, vertex_color},
		{{0.5, -0.5, 0.5, 1.0}, vertex_color},
		{{-0.5, -0.5, -0.5, 1.0}, vertex_color},
		{{0.5, -0.5, -0.5, 1.0}, vertex_color},
		{{0.5, 0.5, -0.5, 1.0}, vertex_color},
		{{0.5, -0.5, -0.5, 1.0}, vertex_color},
		{{-0.5, -0.5, -0.5, 1.0}, vertex_color},
		{{-0.5, -0.5, -0.5, 1.0}, vertex_color},
		{{0.5, 0.5, 0.5, 1.0}, vertex_color},
		{{-0.5, 0.5, -0.5, 1.0}, vertex_color},
		{{0.5, -0.5, 0.5, 1.0}, vertex_color},
		{{-0.5, -0.5, 0.5, 1.0}, vertex_color},
		{{-0.5, -0.5, -0.5, 1.0}, vertex_color},
		{{-0.5, 0.5, 0.5, 1.0}, vertex_color},
		{{-0.5, -0.5, 0.5, 1.0}, vertex_color},
		{{0.5, -0.5, 0.5, 1.0}, vertex_color},
		{{0.5, 0.5, 0.5, 1.0}, vertex_color},
		{{0.5, -0.5, -0.5, 1.0}, vertex_color},
		{{0.5, 0.5, -0.5, 1.0}, vertex_color},
		{{0.5, -0.5, -0.5, 1.0}, vertex_color},
		{{0.5, 0.5, 0.5, 1.0}, vertex_color},
		{{0.5, -0.5, 0.5, 1.0}, vertex_color},
		{{0.5, 0.5, 0.5, 1.0}, vertex_color},
		{{0.5, 0.5, -0.5, 1.0}, vertex_color},
		{{-0.5, 0.5, -0.5, 1.0}, vertex_color},
		{{0.5, 0.5, 0.5, 1.0}, vertex_color},
		{{-0.5, 0.5, -0.5, 1.0}, vertex_color},
		{{-0.5, 0.5, 0.5, 1.0}, vertex_color},
		{{0.5, 0.5, 0.5, 1.0}, vertex_color},
		{{-0.5, 0.5, 0.5, 1.0}, vertex_color},
		{{0.5, -0.5, 0.5, 1.0}, vertex_color},
	}

	for color, idx in polygon_color {
		vertices[idx].color = color
	}
	// Initialize vertex array indices (used to select which vertices are drawn in which order).
	vertex_indices: [dynamic]u16
	for index in 0 ..< 36 {
		append(&vertex_indices, u16(index))
	}

	// Bind vertices to vertex buffer.
	gl.BindBuffer(gl.ARRAY_BUFFER, triangle_vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertices) * size_of(Vertex),
		raw_data(vertices),
		gl.STATIC_DRAW,
	)
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(0, 4, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
	gl.VertexAttribPointer(1, 4, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))

	// Bind vertex array indices to index buffer.
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, triangle_ebo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(vertex_indices) * size_of(u16),
		raw_data(vertex_indices),
		gl.STATIC_DRAW,
	)

	// Check for window events.
	for (!glfw.WindowShouldClose(window) && running) {
		// https://www.glfw.org/docs/3.3/group__window.html#ga37bd57223967b4211d60ca1a0bf3c832
		glfw.PollEvents()

		// Clear the screen with some color. RGBA values are normalized to be within [0.0, 1.0].
		gl.ClearColor(0.1, 0.1, 0.1, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// Update (rotate) the vertices every frame.
		vertices = update(vertices)

		// TODO: Find a way to use `BufferSubData` instead. Using `BufferData` works but reallocates memory.
		// Rebind the updated vertices to the vertex buffer.
		gl.BufferData(
			gl.ARRAY_BUFFER,
			len(vertices) * size_of(Vertex),
			raw_data(vertices),
			gl.STATIC_DRAW,
		)

		// Draw vertices.
		draw(vertex_indices[:])

		// NOTE: Defaults to double buffering I think? - Ansh
		// See https://en.wikipedia.org/wiki/Multiple_buffering to learn more about Multiple buffering
		// https://www.glfw.org/docs/3.0/group__context.html#ga15a5a1ee5b3c2ca6b15ca209a12efd14
		glfw.SwapBuffers(window)
	}

	exit()
}

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

// Return WindowHandle rawPtr
// https://www.glfw.org/docs/3.3/group__window.html#ga3555a418df92ad53f917597fe2f64aeb
mamino_create_window :: proc() -> glfw.WindowHandle {
	window := glfw.CreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, PROGRAM_NAME, nil, nil)
	// https://www.glfw.org/docs/latest/group__window.html#gacdf43e51376051d2c091662e9fe3d7b2
	if window == nil {
		fmt.println("Unable to create window")
		return nil
	}

	// https://www.glfw.org/docs/3.3/group__context.html#ga1c04dc242268f827290fe40aa1c91157
	glfw.MakeContextCurrent(window)
	// Enable vsync
	// https://www.glfw.org/docs/3.3/group__context.html#ga6d4e0cdf151b5e579bd67f13202994ed
	glfw.SwapInterval(1)
	// This function sets the key callback of the specified window, which is called when a key is pressed, repeated or released.
	// https://www.glfw.org/docs/3.3/group__input.html#ga1caf18159767e761185e49a3be019f8d
	glfw.SetKeyCallback(window, key_callback)
	// This function sets the framebuffer resize callback of the specified window, which is called when the framebuffer of the specified window is resized.
	// https://www.glfw.org/docs/3.3/group__window.html#gab3fb7c3366577daef18c0023e2a8591f
	glfw.SetFramebufferSizeCallback(window, size_callback)
	// Set OpenGL Context bindings using the helper function
	// See Odin Vendor source for specifc implementation details
	// https://github.com/odin-lang/Odin/tree/master/vendor/OpenGL
	// https://www.glfw.org/docs/3.3/group__context.html#ga35f1837e6f666781842483937612f163

	// casting the c.int to int
	// This is needed because the GL_MAJOR_VERSION has an explicit type of c.int
	gl.load_up_to(int(GL_MAJOR_VERSION), GL_MINOR_VERSION, glfw.gl_set_proc_address)

	return window
}

update :: proc(vertices: [dynamic]Vertex) -> [dynamic]Vertex {
	angle: f32 = 0.01
	view := glm.mat4LookAt({0, -1, +1}, {0, 1, 0}, {0, 0, 1})
	proj := glm.mat4Perspective(45, 1.3, 0.1, 100.0)
	// Mutable reference to `vertex`.
	for &vertex, idx in vertices {
		vertex.position *= glm.mat4Rotate({0.5, 0.5, 1.}, angle)
	}

	return vertices
}

draw :: proc(indices: []u16) {
	// gl.Enable(gl.DEPTH_TEST);
	// gl.DepthFunc(gl.LESS);
	gl.DrawElements(gl.TRIANGLES, i32(len(indices)), gl.UNSIGNED_SHORT, nil)
	// gl.Enable(gl.VERTEX_PROGRAM_POINT_SIZE)
	// gl.DrawElements(gl.POINTS, i32(len(indices)), gl.UNSIGNED_SHORT, nil)
}

// Termination code here
exit :: proc() {
}
