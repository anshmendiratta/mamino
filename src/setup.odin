package main

import "core:fmt"

import im "shared:dear_imgui"
import imgl "shared:dear_imgui/gl"
import imfw "shared:dear_imgui/glfw"

import "vendor:glfw"

debugger: ^Debugger = &{}
mamino_configuration: ^MaminoConfiguration = &{}

@(cold)
@(deferred_none = mamino_deinit)
mamino_init :: proc(mamino_configuration: MaminoConfiguration) {
	if !glfw.Init() {
		fmt.eprintln("Failed to initialize GLFW")
		return
	}
}

mamino_deinit :: proc() {
	glfw.Terminate()
}

@(deferred_out = mamino_deinit_imgui)
mamino_init_imgui :: proc(window: glfw.WindowHandle) -> (im_context: ^im.Context) {
	// Dear ImGui
	im_context = im.CreateContext()
	im_context.FontSize = 20.
	im_config_flags := im.GetIO()
	im_config_flags.ConfigFlags += {.NavEnableKeyboard, .DockingEnable}

	imfw.InitForOpenGL(window, true)
	imgl.Init("#version 410")

	im.StyleColorsDark()
	style := im.GetStyle()
	style.WindowRounding = 0
	style.Colors[im.Col.WindowBg].w = 1

	im.SetCurrentContext(im_context)

	return
}

mamino_deinit_imgui :: proc(im_context: ^im.Context) {
	imgl.Shutdown()
	imfw.Shutdown()
	im.DestroyContext(im_context)
}

