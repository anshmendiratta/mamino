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
	mamino_configuration: MaminoConfiguration = {}
	// mamino_configuration += {.enable_debugger, .export_video}
	mamino_init(mamino_configuration)
	window := render.mamino_create_window()

	if .enable_debugger in mamino_configuration {
		// render.highlighted_debug_object_id = ~objects.ObjectID(0)
		mamino_init_imgui(window)
		// render.highlighted_debug_object_id = 0
	}

	program_id, uniforms := render.mamino_init_gl()
	if .export_video in mamino_configuration {
		sequencing.mamino_frame_capture_init()
	}

	scene := render.create_scene()

	cube := objects.create_cube()
	render.add_object(&scene, &cube)

	objects.rotate(
		object = &cube,
		rotation = objects.create_orientation(axis = {0., 1., 0.}, angle = 45),
		duration = 2 * time.Second,
	)
	objects.translate(&cube, glm.vec3{1., 0., 0.}, time.duration_seconds(2 * time.Second))
	objects.scale(&cube, objects.Scale{2., 1., 1.}, time.duration_seconds(2 * time.Second))
	objects.rotate(
		&cube,
		objects.create_orientation(axis = {0., 1., 0.}, angle = 45),
		time.duration_seconds(2 * time.Second),
	)
	objects.translate(&cube, glm.vec3{0., 1., 0.}, time.duration_seconds(2 * time.Second))
	objects.rotate(
		&cube,
		objects.create_orientation(axis = {0., 1., 0.}, angle = 45),
		time.duration_seconds(2 * time.Second),
	)
	fmt.println(cube.(objects.Cube).key_frames)

	render_objects_info: []objects.ObjectInfo = objects.get_objects_info(scene.objects)

	// Init debugger.
	if .enable_debugger in mamino_configuration {
		mamino_init_debugger(debugger, render.scene_get_num_objects(&scene))
	}

	for (!glfw.WindowShouldClose(window) && render.running) {
		// NOTE(Jaran): temporary "public" API to modify keyframes
		objects.set_current_key_frame(&cube, render.current_key_frame)

		if .enable_debugger in mamino_configuration {
			debugger_update(debugger)
		}

		// Set background.
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		gl.ClearColor(0., 0., 0., 1.0)

		// Input handling.
		glfw.PollEvents()
		render.update_camera()
		// Update (rotate) the vertices every frame.
		render.update_shader(uniforms)

		render.render_scene(&scene)
		if render.render_axes {
			render.render_coordinate_axes()
		}
		if render.render_grid {
			render.render_subgrid_axes()
		}

		if .enable_debugger in mamino_configuration {
			if render.debugger_open {
				render_debugger(debugger, &scene, &render_objects_info)
			}
		}

		if .export_video in mamino_configuration {
			sequencing.mamino_capture_frame()
		}

		render.WINDOW_WIDTH, render.WINDOW_HEIGHT = glfw.GetWindowSize(window)

		glfw.SwapBuffers(window)
		free_all(context.temp_allocator) // Frees most of the frames initializations.
	}
	glfw.DestroyWindow(window)

	if .enable_debugger in mamino_configuration {
		avg_framerate := debugger_calculate_avg_fps(debugger.frametimes)
		fmt.println("Average:", avg_framerate, "FPS")
		low_framerate := debugger_calculate_percent_low_fps(debugger.frametimes)
		fmt.println("Percent low:", low_framerate, "FPS")
	}

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

