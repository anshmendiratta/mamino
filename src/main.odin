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

	// Setup scene objects and textures.
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.MIRRORED_REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT)
	tex_border_color: []f32 = {1., 1., 0., 1.}
	gl.TexParameterfv(gl.TEXTURE_2D, gl.TEXTURE_BORDER_COLOR, raw_data(tex_border_color))
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)

	texture_id: u32
	gl.GenTextures(1, &texture_id)
	gl.BindTexture(gl.TEXTURE_2D, texture_id)

	width, height, channel_num: i32
	texture_data := stbi.load("assets/wall.jpg", &width, &height, &channel_num, 0)
	defer stbi.image_free(texture_data)
	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		gl.RGB,
		width,
		height,
		0,
		gl.RGB,
		gl.UNSIGNED_BYTE,
		texture_data,
	)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	append(
		&objects.textures,
		objects.Texture{texture = texture_data, width = width, height = height},
	)
	append(&objects.texture_ids, texture_id)
	render_objects: []union {
		objects.Cube,
	} =
		{objects.Cube{id = 0, center = {1., 1., 1.}, scale = {3., 1., 1.}, orientation = {glm.vec3{0., 1., 0.}, glm.radians(f32(45.))}, texture_id = objects.texture_ids[0]}, objects.Cube{id = 1, center = {-1., 1., -1.}, scale = {1., 2., 1.}, orientation = {glm.vec3{1., 1., 1.}, glm.radians(f32(35.))}, texture_id = objects.texture_ids[0]}, objects.Cube{id = 2, center = {0., 3., 2.}, scale = {0.5, 0.5, 0.5}, orientation = {glm.vec3{1., 0., 0.}, glm.radians(f32(60.))}, texture_id = objects.texture_ids[0]}}
	render_objects_info: []objects.ObjectInfo = objects.get_objects_info(render_objects)

	// Init debugger.
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

