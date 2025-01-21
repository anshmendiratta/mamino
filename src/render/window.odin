package render

import "core:c"
import "core:fmt"

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

PROGRAM_NAME :: "mamino"
// Default values for not-MacOS.
GL_MAJOR_VERSION: c.int : 4
GL_MINOR_VERSION :: 6

WINDOW_WIDTH :: 512
WINDOW_HEIGHT :: 512

delta_angle: f32
running: b32 = true

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

// TODO: Termination code here
mamino_exit :: proc() {
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if key == glfw.KEY_ESCAPE || key == glfw.KEY_Q {
		running = false
	}

	if key == glfw.KEY_W || key == glfw.KEY_UP {
		camera_position_spherical.z = glm.clamp(camera_position_spherical.z + rotation_rate, -theta_bound, theta_bound)
	}
	if key == glfw.KEY_S || key == glfw.KEY_DOWN {
		camera_position_spherical.z = glm.clamp(camera_position_spherical.z - rotation_rate, -theta_bound, theta_bound)
	}
	if key == glfw.KEY_A || key == glfw.KEY_LEFT {
		camera_position_spherical.y += rotation_rate
	}
	if key == glfw.KEY_D || key == glfw.KEY_RIGHT {
		camera_position_spherical.y -= rotation_rate
	}
	if key == glfw.KEY_EQUAL {
		camera_position_spherical.x -= zoom_rate
	}
	if key == glfw.KEY_MINUS {
		camera_position_spherical.x += zoom_rate
	}
}

size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

