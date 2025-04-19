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


Debugger :: struct {
	frametimes:      [dynamic]f64,
	object_count:    uint,
	camera_position: glm.vec3,
}

@(cold)
@(deferred_in = mamino_deinit_debugger)
mamino_init_debugger :: proc(debugger: ^Debugger, num_objects: uint) {
	render.last_frame = glfw.GetTime()
	debugger.object_count = num_objects
	debugger.camera_position = objects.camera_get_cartesian_coordinates(&objects.camera)
}

mamino_deinit_debugger :: proc(debugger: ^Debugger, _: uint) {
	delete(debugger.frametimes)
}

// Only using the newest 80% of frames.
debugger_calculate_avg_fps :: proc(times_per_frame: [dynamic]f64) -> (avg: uint) {
	total_fps: f64 = 0
	LOWER_BOUND_TO_IGNORE: f64 : 0.2
	cutoff := uint(f64(len(times_per_frame)) * LOWER_BOUND_TO_IGNORE)
	for time_per_frame in times_per_frame[cutoff:] {
		total_fps += 1 / time_per_frame
	}
	avg = uint(total_fps / f64(len(times_per_frame)) * 1. / (1. - LOWER_BOUND_TO_IGNORE))
	return
}

debugger_calculate_percent_low_fps :: proc(
	times_per_frame: [dynamic]f64,
) -> (
	percent_low_fps: uint,
) {
	slice.reverse_sort(times_per_frame[:])
	percent_low_frametimes := times_per_frame[0:max(len(times_per_frame) / 100, 1)]
	useful_frame_fps: [dynamic]f64
	defer delete(useful_frame_fps)
	for frametime in percent_low_frametimes {
		append(&useful_frame_fps, 1 / frametime)
	}
	total_low_fps: f64 = 0
	for percent_low_fps in useful_frame_fps {
		total_low_fps += percent_low_fps
	}
	percent_low_fps = uint(total_low_fps / f64(len(useful_frame_fps)))

	return
}

debugger_update :: proc(debugger: ^Debugger) {
	time_for_frame := glfw.GetTime() - render.last_frame
	render.last_frame = glfw.GetTime()
	append(&debugger^.frametimes, time_for_frame)

	// FIX(Ansh): Find a way to avoid calculating this every frame. Not too expensive, but would be nice to have gone.
	// Camera position.
	debugger.camera_position = objects.camera_get_cartesian_coordinates(&objects.camera)
}

debugger_get_most_recent_frametime :: proc(debugger: ^Debugger) -> f64 {
	return debugger.frametimes[len(debugger.frametimes) - 1]
}

debugger_get_most_recent_framerate :: proc(debugger: ^Debugger) -> f64 {
	return 1. / debugger.frametimes[len(debugger.frametimes) - 1]
}

render_debugger :: proc(
	debugger: ^Debugger,
	scene: ^render.Scene,
	render_objects_info: ^[]objects.ObjectInfo,
) {
	context.allocator = context.temp_allocator

	imgl.NewFrame()
	imfw.NewFrame()
	im.NewFrame()

	viewport_size := im.GetMainViewport().Size
	im.SetNextWindowPos(im.GetMainViewport().Pos.x + viewport_size.x / 40)

	window_flags: im.WindowFlags
	im.Begin("Debugger", &render.debugger_open, window_flags)

	// Display basic debug info.
	im.SeparatorText(strings.clone_to_cstring("FRAME INFO"))
	debugger_render_frame_info(debugger)
	im.SeparatorText(strings.clone_to_cstring("SCENE INFO"))
	debugger_render_scene_info(debugger)
	im.SeparatorText(strings.clone_to_cstring("TOGGLE RENDERING"))
	// Toggle rendering of faces/normals.
	debugger_render_toggle_render_buttons(debugger)
	im.SeparatorText(strings.clone_to_cstring("DEBUG OBJECT INFO"))
	// List debug objects and their properties. Selected debug object info.
	debug_objects_display: [dynamic][2]union {
		cstring,
		objects.ObjectID,
	}
	defer delete(debug_objects_display)
	for object_info in render_objects_info {
		debug_list_item := strings.clone_to_cstring(
			fmt.tprintf("{} {}", object_info.type, object_info.id),
		)
		debug_object_display_with_id: [2]union {
			cstring,
			objects.ObjectID,
		}
		debug_object_display_with_id = {debug_list_item, object_info.id}
		append(&debug_objects_display, debug_object_display_with_id)
	}
	highlighted_debug_object: objects.Object
	for &obj in scene.objects {
		if objects.object_get_info(obj).id == render.highlighted_debug_object_id {
			highlighted_debug_object = obj^
			break
		}
	}
	debugger_render_debug_objects_list(debugger, &debug_objects_display, highlighted_debug_object)

	im.End()
	im.Render()
	imgl.RenderDrawData(im.GetDrawData())
}

@(private = "file")
debugger_render_frame_info :: proc(debugger: ^Debugger) {
	im.TextWrapped(
		strings.clone_to_cstring(
			(fmt.tprintf(
					"Most recent framerate: {} FPS",
					uint(debugger_get_most_recent_framerate(debugger)),
				)),
			context.temp_allocator,
		),
		context.temp_allocator,
	)
	im.TextWrapped(
		strings.clone_to_cstring(
			(fmt.tprintf(
					"Average framerate: {} FPS",
					uint(debugger_calculate_avg_fps(debugger.frametimes)),
				)),
			context.temp_allocator,
		),
		context.temp_allocator,
	)
	im.TextWrapped(
		strings.clone_to_cstring(
			(fmt.tprintf(
					`Percent low framerate: {} FPS`,
					uint(debugger_calculate_percent_low_fps(debugger.frametimes)),
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
					// "Most recent frametime: {:.9f} ms",
					debugger_get_most_recent_frametime(debugger) * SECOND_TO_MILLISECOND,
				)),
			context.temp_allocator,
		),
		context.temp_allocator,
	)
}

@(private = "file")
debugger_render_scene_info :: proc(debugger: ^Debugger) {
	context.allocator = context.temp_allocator
	im.TextWrapped(
		strings.clone_to_cstring(fmt.tprintf("Object count: {}", debugger.object_count)),
	)
	im.TextWrapped(strings.clone_to_cstring("Camera position (x, y, z):"))
	im.BulletText(strings.clone_to_cstring(fmt.tprintf("x: {}", debugger.camera_position.x)))
	im.BulletText(strings.clone_to_cstring(fmt.tprintf("y: {}", debugger.camera_position.y)))
	im.BulletText(strings.clone_to_cstring(fmt.tprintf("z: {}", debugger.camera_position.z)))
}

@(private = "file")
debugger_render_toggle_render_buttons :: proc(debugger: ^Debugger) {
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
	im.SameLine()
	if im.Button(strings.clone_to_cstring("Render axes", context.temp_allocator)) {
		if .render_axes in render.mamino_configuration {
			render.mamino_configuration -= {.render_axes}
		} else {
			render.mamino_configuration += {.render_axes}
		}
	}
	im.SameLine()
	if im.Button(strings.clone_to_cstring("Render grid", context.temp_allocator)) {
		if .render_axes_subgrid in render.mamino_configuration {
			render.mamino_configuration -= {.render_axes_subgrid}
		} else {
			render.mamino_configuration += {.render_axes_subgrid}
		}
	}
}

@(private = "file")
debugger_render_debug_objects_list :: proc(
	debugger: ^Debugger,
	debug_objects_display: ^[dynamic][2]union {
		cstring,
		objects.ObjectID,
	},
	highlighted_debug_object: objects.Object,
) {
	context.allocator = context.temp_allocator

	item_selected := false
	highlighted_item_idx := -1
	selected_item_idx := -1
	// Full width.
	listbox_size := im.Vec2{im.GetWindowSize().x, 5 * im.GetTextLineHeightWithSpacing()}
	if im.BeginListBox(strings.clone_to_cstring("Debug Text"), listbox_size) {
		for debug_object, item_idx in debug_objects_display {
			is_selected := highlighted_item_idx == item_idx

			if im.Selectable(debug_object.x.(cstring), is_selected) {
				selected_item_idx = item_idx
			}
			if im.IsItemHovered() {
				highlighted_item_idx = item_idx
				render.highlighted_debug_object_id = debug_object.y.(objects.ObjectID)
			}
			if is_selected {
				im.SetItemDefaultFocus()
			}
		}

		im.EndListBox()
	}
	im.TextWrapped(strings.clone_to_cstring("Object: "))
	im.BulletText(
		strings.clone_to_cstring(
			fmt.tprintf("ID: {}", objects.object_get_id(highlighted_debug_object)),
		),
	)
	im.BulletText(
		strings.clone_to_cstring(
			fmt.tprintf("Center: {}", objects.get_object_scale(highlighted_debug_object)),
		),
	)
	im.BulletText(
		strings.clone_to_cstring(
			fmt.tprintf("Scale: {}", objects.get_object_scale(highlighted_debug_object)),
		),
	)
	im.BulletText(
		strings.clone_to_cstring(
			fmt.tprintf(
				"Orientation: {}",
				objects.object_get_orientation(highlighted_debug_object),
			),
		),
	)
}

