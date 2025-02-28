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
import stbi "vendor:stb/image"

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
	render.mamino_init()
	window := render.mamino_create_window()
	render.mamino_init_imgui(window)
	program_id, uniforms := render.mamino_init_gl()
	when MAMINO_EXPORT_VIDEO {
		sequencing.mamino_frame_capture_init()
	}

	// Load image to use as texture.
	width, height, channel_num: i32
	texture_data := stbi.load("assets/abstract.jpg", &width, &height, &channel_num, 0)
	defer stbi.image_free(texture_data)
	// Init texture.
	texture_id: u32 = render.get_texture_id(texture_data, width, height)
	// Add image as a OpenGL texture.
	objects.textures[objects.TextureID(texture_id)] = objects.Texture {
		data   = texture_data,
		width  = width,
		height = height,
	}
	defer delete(objects.textures)
	defer gl.DeleteTextures(1, &texture_id)

	render_objects: []union {
		objects.Cube,
	} = {
		objects.Cube {
			id = 0,
			center = {1., 1., 1.},
			scale = {3., 1., 1.},
			orientation = {glm.vec3{0., 1., 0.}, glm.radians(f32(45.))},
			texture_id = objects.TextureID(texture_id),
		},
		// 
		objects.Cube {
			id = 1,
			center = {-1., 1., -1.},
			scale = {1., 2., 1.},
			orientation = {glm.vec3{1., 1., 1.}, glm.radians(f32(35.))},
			texture_id = nil,
		},
		// 
		objects.Cube {
			id = 2,
			center = {0., 3., 2.},
			scale = {0.5, 0.5, 0.5},
			orientation = {glm.vec3{1., 0., 0.}, glm.radians(f32(60.))},
			texture_id = nil,
		},
	}
	render_objects_info: []objects.DebugObjectInfo = objects.get_objects_info(render_objects)

	// Init debugger.
	debugger: ^Debugger = &{}
	when ODIN_DEBUG {
		mamino_init_debugger(debugger, render_objects)
	}

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

