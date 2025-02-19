package render

import "core:c"
import "core:fmt"

import im "shared:dear_imgui"
import imgl "shared:dear_imgui/gl"
import imfw "shared:dear_imgui/glfw"

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

@(private)
PROGRAM_NAME :: "mamino"
@(private)
GL_MAJOR_VERSION: c.int : 4
@(private)
GL_MINOR_VERSION :: 1
@(private)
show_window: bool = true
logger_open: bool = true
last_frame: f64 = 0.

WINDOW_WIDTH := i32(1024)
WINDOW_HEIGHT := i32(1024)
running: b32 = true

StaticGLObjects :: struct {
	program_id: u32,
	uniforms:   map[string]gl.Uniform_Info,
}

@(cold)
@(init)
mamino_init :: proc() {
	if !glfw.Init() {
		fmt.eprintln("Failed to initialize GLFW")
		return
	}
}

@(deferred_none = mamino_init)
mamino_deinit :: proc() {
	defer glfw.Terminate()
}

mamino_init_imgui :: proc(window: glfw.WindowHandle) {
	// Dear ImGui
	im_context := im.CreateContext()
	im.SetCurrentContext(im_context)
	im_config_flags := im.GetIO()
	im_config_flags.ConfigFlags += {.NavEnableKeyboard}

	imfw.InitForOpenGL(window, true)
	imgl.Init("#version 150")

	im.StyleColorsDark()
	style := im.GetStyle()
	style.WindowRounding = 0
	style.Colors[im.Col.WindowBg].w = 1
}

@(deferred_in = mamino_init_imgui)
mamino_deinit_imgui :: proc(_: glfw.WindowHandle) {
	defer im.DestroyContext()
	defer imfw.Shutdown()
	defer imgl.Shutdown()
}

@(cold)
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

@(deferred_out = mamino_create_window)
mamino_destroy_window :: proc(window: glfw.WindowHandle) {
	// TODO: Find out why this segfaults. "Bad free of pointer" with tracking allocator.
	free(window)
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	switch key {
	case glfw.KEY_ESCAPE, glfw.KEY_Q:
		running = false
		show_window = false
		logger_open = false
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

