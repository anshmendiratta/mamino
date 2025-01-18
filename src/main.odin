package main

import "core:fmt"
import "core:c"

import gl "vendor:OpenGL"
import "vendor:glfw"

PROGRAMNAME :: "mamino"

GL_MAJOR_VERSION : c.int : 4
GL_MINOR_VERSION :: 6

running : b32 = true

// NOTE: `defer`s are executed in reverse, like popping from a stack.
main :: proc() {
	mamino_init()
	// They can also just be called manually later instead without defer. This way of doing it ensures are terminated.
	// https://odin-lang.org/docs/overview/#defer-statement
	// https://www.glfw.org/docs/3.1/group__init.html#gaaae48c0a18607ea4a4ba951d939f0901
	defer glfw.Terminate()

	// Return WindowHandle rawPtr
	// https://www.glfw.org/docs/3.3/group__window.html#ga3555a418df92ad53f917597fe2f64aeb
	window := glfw.CreateWindow(512, 512, PROGRAMNAME, nil, nil)
	// https://www.glfw.org/docs/latest/group__window.html#gacdf43e51376051d2c091662e9fe3d7b2
	defer glfw.DestroyWindow(window)

	// If the window pointer is invalid
	if window == nil {
		fmt.println("Unable to create window")
		return
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
	
	// There is only one kind of loop in Odin called for
	// https://odin-lang.org/docs/overview/#for-statement
	for (!glfw.WindowShouldClose(window) && running) {
		// Process waiting events in queue
		// https://www.glfw.org/docs/3.3/group__window.html#ga37bd57223967b4211d60ca1a0bf3c832
		glfw.PollEvents()
		
		update()
		draw()

		// Double buffering I think? - Ansh
		// This function swaps the front and back buffers of the specified window.
		// See https://en.wikipedia.org/wiki/Multiple_buffering to learn more about Multiple buffering
		// https://www.glfw.org/docs/3.0/group__context.html#ga15a5a1ee5b3c2ca6b15ca209a12efd14
		glfw.SwapBuffers((window))
	}

	exit()
	
}


mamino_init :: proc(){
	// Set Window Hints
	// https://www.glfw.org/docs/3.3/window_guide.html#window_hints
	// https://www.glfw.org/docs/3.3/group__window.html#ga7d9c8c62384b1e2821c4dc48952d2033
	glfw.WindowHint(glfw.RESIZABLE, 1)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR,GL_MAJOR_VERSION) 
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR,GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE,glfw.OPENGL_CORE_PROFILE)

	// Initialize glfw
	// GLFW_TRUE if successful, or GLFW_FALSE if an error occurred.
	// https://www.glfw.org/docs/latest/group__init.html#ga317aac130a235ab08c6db0834907d85e
	if !glfw.Init() {
		fmt.println("Failed to initialize GLFW")
		return
	}
}

update :: proc(){
	// Own update code here
}

draw :: proc(){
	// Clear the screen with some color. RGBA values are normalized to be within [0.0, 1.0].
	gl.ClearColor(0.1, 0.1, 0.1, 1.0)
	// Clear the screen with the set clearcolor
	gl.Clear(gl.COLOR_BUFFER_BIT)
}

exit :: proc(){
	// Own termination code here
}

// Called when glfw keystate changes
key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	// Exit program on escape pressed
	if key == glfw.KEY_ESCAPE {
		running = false
	}
}

// Called when glfw window changes size
size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	// Set the OpenGL viewport size
	gl.Viewport(0, 0, width, height)
}
