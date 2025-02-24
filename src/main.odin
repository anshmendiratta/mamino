#+feature dynamic-literals

package main

import "core:c"
import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:mem"
import "core:os/os2"
import "core:slice"
import "core:strings"
import "core:time"

import im "shared:dear_imgui"
import imgl "shared:dear_imgui/gl"
import imfw "shared:dear_imgui/glfw"

import "base:runtime"

import gl "vendor:OpenGL"
import "vendor:glfw"

import "objects"
import "render"
import "sequencing"

MAMINO_EXPORT_VIDEO :: #config(MAMINO_EXPORT_VIDEO, false)

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}
	// Init.
	// 
	render.mamino_init()
	window := render.mamino_create_window()
	render.mamino_init_imgui(window)
	program_id, uniforms := render.mamino_init_gl()
	when MAMINO_EXPORT_VIDEO {
		sequencing.mamino_frame_capture_init()
	}

	// Setup scene objects.
	render_objects: []union {
		objects.Cube,
	} =
		{objects.Cube{id = 0, center = {1., 1., 1.}, scale = {3., 1., 1.}, orientation = {glm.vec3{0., 1., 0.}, glm.radians(f32(45.))}}, objects.Cube{id = 1, center = {-1., 1., -1.}, scale = {1., 2., 1.}, orientation = {glm.vec3{1., 1., 1.}, glm.radians(f32(35.))}}, objects.Cube{id = 2, center = {0., 3., 2.}, scale = {0.5, 0.5, 0.5}, orientation = {glm.vec3{1., 0., 0.}, glm.radians(f32(60.))}}}
	render_objects_info: []objects.ObjectInfo = objects.get_objects_info(render_objects)

	// Init Debugger.
	debugger: ^Debugger = &{}
	mamino_init_debugger(debugger, render_objects)

	for (!glfw.WindowShouldClose(window) && render.running) {
		debugger_update(debugger)

		// Set background.
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		gl.ClearColor(0., 0., 0., 1.0)

		// Input handling.
		glfw.PollEvents()
		render.update_camera()
		// Update (rotate) the vertices every frame.
		render.update_shader(uniforms)

		render.render_objects(&render_objects)
		if render.render_axes {
			render.render_coordinate_axes()
		}
		if render.render_grid {
			render.render_subgrid_axes()
		}

		if ODIN_DEBUG && render.debugger_open {
			render_debugger(debugger, &render_objects, &render_objects_info)
		}
		when MAMINO_EXPORT_VIDEO {
			sequencing.mamino_capture_frame()
		}

		render.WINDOW_WIDTH, render.WINDOW_HEIGHT = glfw.GetWindowSize(window)

		glfw.SwapBuffers(window)
		free_all(context.temp_allocator) // Frees most of the frames initializations.
	}
	glfw.DestroyWindow(window)

	avg_framerate := debugger_calculate_avg_fps(debugger.frametimes)
	fmt.println("Average:", avg_framerate, "FPS")
	low_framerate := debugger_calculate_percent_low_fps(debugger.frametimes)
	fmt.println("Percent low:", low_framerate, "FPS")

	video_options: sequencing.VideoOptions = {
			resolution = {1920, 1080},
			framerate  = 180,
			encoding   = "libx264",
			out_name   = "vid.h264",
		}
	if valid_vo := sequencing.validate_video_options(video_options); !valid_vo {
		fmt.eprintln("Incorrect export video options.")
		return
	}

	// NOTE(Ansh): vo = nil does NOT composite a video.
	sequencing.mamino_exit(nil)
}

