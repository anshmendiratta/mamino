#+feature dynamic-literals

package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:slice"
import "core:strings"
import "core:time"

import im "shared:dear_imgui"
import imgl "shared:dear_imgui/gl"
import imfw "shared:dear_imgui/glfw"

import gl "vendor:OpenGL"
import "vendor:glfw"

import "objects"
import "render"

Logger :: struct {
	frametimes:      [dynamic]f64,
	object_count:    uint,
	camera_position: glm.vec3,
}

@(cold)
@(deferred_in = mamino_deinit_logger)
mamino_init_logger :: proc(logger: ^Logger, objects: []union {
		objects.Cube,
	}) {
	render.last_frame = glfw.GetTime()
	logger.object_count = len(objects)
	logger.camera_position = render.camera_position_cartesian
}

mamino_deinit_logger :: proc(logger: ^Logger, _: []union {
		objects.Cube,
	}) {
	delete(logger.frametimes)
}

// Only using the newest 80% of frames.
logger_calculate_avg_fps :: proc(times_per_frame: [dynamic]f64) -> (avg: uint) {
	total_fps: f64 = 0
	LOWER_BOUND_TO_IGNORE: f64 : 0.2
	cutoff := uint(f64(len(times_per_frame)) * LOWER_BOUND_TO_IGNORE)
	for time_per_frame in times_per_frame[cutoff:] {
		total_fps += 1 / time_per_frame
	}
	avg = uint(total_fps / f64(len(times_per_frame)) * 1. / (1. - LOWER_BOUND_TO_IGNORE))
	return
}

logger_calculate_percent_low_fps :: proc(
	times_per_frame: [dynamic]f64,
) -> (
	percent_low_fps: uint,
) {
	slice.reverse_sort(times_per_frame[:])
	reciprocal :: #force_inline proc(x: f64) -> f64 {
		return 1 / x
	}
	percent_low_frametimes := times_per_frame[0:max(len(times_per_frame) / 100, 1)]
	percent_low_fps_frames, _ := slice.mapper(
		percent_low_frametimes[:],
		reciprocal,
		context.temp_allocator,
	)
	sum_reduction :: #force_inline proc(accumulator: f64, next: f64) -> f64 {return(
			accumulator +
			next \
		)}
	percent_low_fps = uint(slice.reduce(percent_low_fps_frames, 0., sum_reduction))

	return
}

logger_update :: proc(logger: ^Logger) {
	time_for_frame := glfw.GetTime() - render.last_frame
	render.last_frame = glfw.GetTime()
	append(&logger^.frametimes, time_for_frame)

	// FIX(Ansh): Find a way to avoid calculating this every frame. Not too expensive, but would be nice to have gone.
	// Camera position.
	logger.camera_position = render.get_cartesian_coordinates(render.camera_position_spherical)
}

logger_get_most_recent_frametime :: proc(logger: ^Logger) -> f64 {
	return slice.last(logger.frametimes[:])
}

logger_get_most_recent_framerate :: proc(logger: ^Logger) -> f64 {
	return 1. / slice.last(logger.frametimes[:])
}

render_logger :: proc(logger: ^Logger, render_objects: ^[]union {
		objects.Cube,
	}, render_objects_info: ^[]objects.ObjectInfo) {
	imgl.NewFrame()
	imfw.NewFrame()
	im.NewFrame()

	viewport_size := im.GetMainViewport().Size
	im.SetNextWindowPos(im.GetMainViewport().Pos.x + viewport_size.x / 40)

	window_flags: im.WindowFlags
	im.Begin("Logger", &render.logger_open, window_flags)

	// Display basic debug info.
	logger_render_frame_info(logger)
	im.Separator()
	logger_render_scene_info(logger)
	im.Separator()
	// Toggle rendering of faces/normals.
	logger_render_toggle_render_buttons(logger)
	im.Separator()
	// List debug objects and their properties.
	object_info_formatter :: #force_inline proc(
		object_info: objects.ObjectInfo,
	) -> (
		debug_list_item: cstring,
	) {
		debug_list_item = strings.clone_to_cstring(
			fmt.tprintf("{} {}", object_info.type, object_info.id),
			allocator = context.temp_allocator,
		)
		return
	}
	debug_objects_display, _ := slice.mapper(
		render_objects_info^,
		object_info_formatter,
		context.temp_allocator,
	)
	logger_render_debug_objects_list(logger, &debug_objects_display)

	im.End()
	im.Render()
	imgl.RenderDrawData(im.GetDrawData())
}

@(private = "file")
logger_render_frame_info :: proc(logger: ^Logger) {
	im.TextWrapped(
		strings.clone_to_cstring(
			(fmt.tprintf(
					"Most recent framerate: {} FPS",
					uint(logger_get_most_recent_framerate(logger)),
				)),
			context.temp_allocator,
		),
		context.temp_allocator,
	)
	im.TextWrapped(
		strings.clone_to_cstring(
			(fmt.tprintf(
					`Percent low framerate: {} FPS`,
					uint(logger_calculate_percent_low_fps(logger.frametimes)),
				)),
			context.temp_allocator,
		),
		context.temp_allocator,
	)
	SECOND_TO_MILLISECOND :: 1000
	im.TextWrapped(
		strings.clone_to_cstring(
			(fmt.tprintf(
					"Most recent frametime: {:.9f} ms",
					logger_get_most_recent_frametime(logger) * SECOND_TO_MILLISECOND,
				)),
			context.temp_allocator,
		),
		context.temp_allocator,
	)
}

@(private = "file")
logger_render_scene_info :: proc(logger: ^Logger) {
	im.TextWrapped(
		strings.clone_to_cstring(
			fmt.tprintf("Object count: {}", logger.object_count),
			context.temp_allocator,
		),
		context.temp_allocator,
	)
	im.TextWrapped(
		strings.clone_to_cstring(
			fmt.tprintf(
				"Camera position (x, y, z): ({}, {}, {})",
				logger.camera_position.x,
				logger.camera_position.y,
				logger.camera_position.z,
			),
			context.temp_allocator,
		),
		context.temp_allocator,
	)
}

@(private = "file")
logger_render_toggle_render_buttons :: proc(logger: ^Logger) {
	if im.Button(strings.clone_to_cstring("Render faces", context.temp_allocator)) {
		if render.render_faces ~= true; render.render_faces {
			gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
		} else {
			gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
		}
	}
	im.SameLine()
	if im.Button(strings.clone_to_cstring("Render normals", context.temp_allocator)) {
		render.render_normals ~= true
	}
}

@(private = "file")
logger_render_debug_objects_list :: proc(logger: ^Logger, debug_objects_display: ^[]cstring) {
	highlight_item := true
	item_selected := false
	highlighted_item_idx := -1

	if im.BeginListBox("Debug object") {
		for debug_object, item_idx in debug_objects_display {
			is_selected := highlighted_item_idx == item_idx

			if im.Selectable(debug_object, is_selected) {
				highlighted_item_idx = item_idx
			}
			if highlight_item && im.IsItemHovered() {
				highlighted_item_idx = item_idx
			}
			if is_selected {
				im.SetItemDefaultFocus()
			}
		}

		im.EndListBox()
	}
}

