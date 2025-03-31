package render

import "core:c"
import "core:fmt"
import "core:time"

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

@(private)
PROGRAM_NAME :: "mamino"
@(private)
GL_MAJOR_VERSION: c.int : 4
@(private)
GL_MINOR_VERSION :: 1

WINDOW_WIDTH: i32 = 1024
WINDOW_HEIGHT: i32 = 1024

running: b32 = true
vsync: b32 = false
debugger_open: bool = true
last_frame: f64 = 0.
paused: b32 = false


@(cold)
@(deferred_out = mamino_destroy_window)
mamino_create_window :: proc() -> (window: glfw.WindowHandle) {
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, gl.TRUE)
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
	gl.load_up_to(int(GL_MAJOR_VERSION), GL_MINOR_VERSION, glfw.gl_set_proc_address)

	return
}

// TODO: Find out why doesn't need to free the window.
mamino_destroy_window :: proc(window: glfw.WindowHandle) {
	// free(window)
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	switch key {
	case glfw.KEY_ESCAPE, glfw.KEY_Q:
		running = false
	case glfw.KEY_P:
		if action == glfw.PRESS {
			paused ~= true
			if paused {
				time_of_last_pause = time.now()
			} else {
				time_since_pause := time.diff(time_of_last_pause, time.now())
				global_time = time.time_add(global_time, -time_since_pause)
			}
		}
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

