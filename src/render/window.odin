package render

import "core:c"
import "core:fmt"

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

import "../objects"


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
	glfw.SetCursorPosCallback(window, cursor_position_callback)
	glfw.SetMouseButtonCallback(window, cursor_button_callback)
	glfw.SetFramebufferSizeCallback(window, size_callback)
	gl.load_up_to(int(GL_MAJOR_VERSION), GL_MINOR_VERSION, glfw.gl_set_proc_address)

	return
}

// TODO: Find out why doesn't need to free the window.
mamino_destroy_window :: proc(window: glfw.WindowHandle) {
	// free(window)
}

cursor_button_callback :: proc "c" (window: glfw.WindowHandle, button, action, modifiers: i32) {
	previous_cursor_x_pos, previous_cursor_y_pos = glfw.GetCursorPos(window)
}

previous_cursor_x_pos, previous_cursor_y_pos: c.double = 0, 0
cursor_position_callback :: proc "c" (window: glfw.WindowHandle, x_pos, y_pos: c.double) {
	if glfw.GetMouseButton(window, glfw.MOUSE_BUTTON_LEFT) == glfw.PRESS {
	}

	if glfw.GetMouseButton(window, glfw.MOUSE_BUTTON_LEFT) == glfw.RELEASE {
		return
	}

	// Calculate cursor offsets and cache positions.
	delta_x := f32(previous_cursor_x_pos - x_pos)
	delta_y := f32(previous_cursor_y_pos - y_pos)
	// Cache positions.
	previous_cursor_x_pos = x_pos
	previous_cursor_y_pos = y_pos

	// Cursor is dragging (holding down button).
	objects.camera.theta = objects.camera.theta - objects.cursor_sensitivity * delta_x
	objects.camera.phi = glm.clamp(
		objects.camera.phi + objects.cursor_sensitivity * delta_y,
		-objects.phi_bound,
		objects.phi_bound,
	)
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	switch key {
	case glfw.KEY_ESCAPE, glfw.KEY_Q:
		running = false
	case glfw.KEY_W, glfw.KEY_UP:
		objects.camera.phi = glm.clamp(
			objects.camera.phi - objects.keyboard_rotation_rate,
			0,
			objects.phi_bound,
		)
	case glfw.KEY_A, glfw.KEY_LEFT:
		objects.camera.theta += objects.keyboard_rotation_rate
	case glfw.KEY_S, glfw.KEY_DOWN:
		objects.camera.phi = glm.clamp(
			objects.camera.phi + objects.keyboard_rotation_rate,
			0,
			objects.phi_bound,
		)
	case glfw.KEY_D, glfw.KEY_RIGHT:
		objects.camera.theta -= objects.keyboard_rotation_rate
	case glfw.KEY_EQUAL:
		objects.camera.r -= objects.zoom_rate
	case glfw.KEY_MINUS:
		objects.camera.r += objects.zoom_rate
	}
}

size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

