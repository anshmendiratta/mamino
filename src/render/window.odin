package render

import "core:c"
import "core:fmt"

// OpenGL/Math.
import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

PROGRAM_NAME :: "mamino"
GL_MAJOR_VERSION: c.int : 4
GL_MINOR_VERSION :: 1

WINDOW_WIDTH := i32(1024)
WINDOW_HEIGHT := i32(1024)

running: b32 = true

@(cold)
mamino_init :: proc() {
	// https://www.glfw.org/docs/3.3/window_guide.html#window_hints
	// https://www.glfw.org/docs/3.3/group__window.html#ga7d9c8c62384b1e2821c4dc48952d2033

	// https://www.glfw.org/docs/latest/group__init.html#ga317aac130a235ab08c6db0834907d85e
	if !glfw.Init() {
		fmt.println("Failed to initialize GLFW")
		return
	}
}

mamino_create_window :: proc() -> (window: glfw.WindowHandle) {
	when ODIN_OS == .Darwin {
		glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
		glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, gl.TRUE)
	}
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.RESIZABLE, 1)

	window = glfw.CreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, PROGRAM_NAME, nil, nil)
	if window == nil {
		fmt.println("Unable to create window")
		return nil
	}

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(0)
	glfw.SetKeyCallback(window, key_callback)
	glfw.SetFramebufferSizeCallback(window, size_callback)
	when ODIN_OS == .Darwin {
		gl.load_up_to(int(4), 1, glfw.gl_set_proc_address)
	} else {
		gl.load_up_to(int(GL_MAJOR_VERSION), GL_MINOR_VERSION, glfw.gl_set_proc_address)
	}
	return
}

// TODO: Termination code here (if necessary).
mamino_exit :: proc() {}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	switch key {
	case glfw.KEY_ESCAPE, glfw.KEY_Q:
		running = false
	case glfw.KEY_W, glfw.KEY_UP:
		camera_position_spherical.z = glm.clamp(
			camera_position_spherical.z + rotation_rate,
			-theta_bound,
			theta_bound,
		)
	case glfw.KEY_A, glfw.KEY_LEFT:
		camera_position_spherical.y += rotation_rate
	case glfw.KEY_S, glfw.KEY_DOWN:
		camera_position_spherical.z = glm.clamp(
			camera_position_spherical.z - rotation_rate,
			-theta_bound,
			theta_bound,
		)
	case glfw.KEY_D, glfw.KEY_RIGHT:
		camera_position_spherical.y -= rotation_rate
	case glfw.KEY_EQUAL:
		camera_position_spherical.x -= zoom_rate
	case glfw.KEY_MINUS:
		camera_position_spherical.x += zoom_rate
	}
}

size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

