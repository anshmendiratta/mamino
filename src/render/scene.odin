package render

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:time"

import gl "vendor:OpenGL"

import "../objects"

highlighted_debug_object_id: objects.ObjectID
render_normals: bool = false
render_faces: bool = false
render_axes: bool = true
render_grid: bool = true

HIGHLIGHTED_OBJECT_COLOR :: glm.vec4{0.15, 0.83, 1.0, 0.5}

Scene :: struct {
	objects:      [dynamic]^objects.Object,
	_global_time: time.Time,
}

create_scene :: proc() -> Scene {
	return Scene{}
}

scene_add_object :: proc(scene: ^Scene, object: ^objects.Object) {
	append(&scene.objects, object)
}

scene_get_num_objects :: proc(scene: ^Scene) -> uint {
	return len(scene.objects)
}

scene_render :: proc(scene: ^Scene) {
	render_objects := scene.objects
	for generic_object in render_objects {
		#partial switch &object in generic_object {
		// Do not need to worry about the constant coloring below, as the below call copies over from the base cube, whose color is unchanging.
		case objects.Cube:
			// Interpolate between the last and the almost-next frame.
			if time.diff(object.keyframes[object.current_keyframe].from_time, time.now()) > 0 {
				object.current_keyframe += 1
			}
			last_keyframe: objects.KeyFrame = object.keyframes[object.current_keyframe]
			next_keyframe: objects.KeyFrame =
				object.keyframes[(object.current_keyframe + 1) % len(object.keyframes)]
			interpolated_keyframe := render_interpolate_keyframes(
				last_keyframe,
				next_keyframe,
				time.now(),
			)
			vertices := objects.get_vertices(object, interpolated_keyframe)

			// Cube.
			if object.id == highlighted_debug_object_id {
				objects.color_vertices(&vertices, HIGHLIGHTED_OBJECT_COLOR)
			}
			cube_vao, cube_vbo, cube_ebo := get_buffer_objects()
			bind_data(cube_vao, cube_vbo, cube_ebo, vertices, objects.cube_indices)
			draw_cube(vertices, i32(len(objects.cube_indices)))
			// Points.
			point_vao, point_vbo, point_ebo := get_buffer_objects()
			objects.color_vertices(&vertices, objects.point_color)
			bind_data(point_vao, point_vbo, point_ebo, vertices, objects.point_indices)
			draw_points(vertices, objects.point_indices)
			// Lines.
			line_vao, line_vbo, line_ebo := get_buffer_objects()
			objects.color_vertices(&vertices, objects.line_color)
			bind_data(line_vao, line_vbo, line_ebo, vertices, objects.line_indices)
			draw_lines(vertices, objects.line_indices)
			// FIX(Ansh): Normal rendering doesn't want to happen on debug mode. Probably to do with setting the PolygonMode.
			if ODIN_DEBUG && render_normals {
				normal_vao, normal_vbo, normal_ebo := get_buffer_objects()
				face_normals := objects.get_cube_normals_coordinates(object)
				bind_data(normal_vao, normal_vbo, normal_ebo, face_normals, {0, 1, 2, 3, 4, 5})
				draw_lines(face_normals, {0, 1, 2, 3, 4, 5})

				gl.DeleteVertexArrays(1, &normal_vao)
				gl.DeleteBuffers(1, &normal_vbo)
				gl.DeleteBuffers(1, &normal_ebo)
			}

			gl.DeleteVertexArrays(1, &cube_vao)
			gl.DeleteBuffers(1, &cube_vbo)
			gl.DeleteBuffers(1, &cube_ebo)
			gl.DeleteVertexArrays(1, &point_vao)
			gl.DeleteBuffers(1, &point_vbo)
			gl.DeleteBuffers(1, &point_ebo)
			gl.DeleteVertexArrays(1, &line_vao)
			gl.DeleteBuffers(1, &line_vbo)
			gl.DeleteBuffers(1, &line_ebo)
		}
	}

	scene._global_time = time.now()
}

render_coordinate_axes :: proc() {
	axes_vao, axes_vbo, axes_ebo := get_buffer_objects()
	bind_data(
		axes_vao,
		axes_vbo,
		axes_ebo,
		objects.coordinate_axes_vertices,
		objects.coordinate_axes_indices,
	)
	draw_axes(objects.coordinate_axes_indices)
	gl.DeleteVertexArrays(1, &axes_vao)
	gl.DeleteBuffers(1, &axes_vbo)
	gl.DeleteBuffers(1, &axes_ebo)
}

render_subgrid_axes :: proc() {
	subgrid_axes_vao, subgrid_axes_vbo, subgrid_axes_ebo := get_buffer_objects()
	bind_data(
		subgrid_axes_vao,
		subgrid_axes_vbo,
		subgrid_axes_ebo,
		objects.subgrid_axes_vertices,
		objects.subgrid_axes_indices,
	)
	draw_axes(objects.subgrid_axes_indices)
	gl.DeleteVertexArrays(1, &subgrid_axes_vao)
	gl.DeleteBuffers(1, &subgrid_axes_vbo)
	gl.DeleteBuffers(1, &subgrid_axes_ebo)
}

render_interpolate_keyframes :: proc(
	keyframe_a: objects.KeyFrame,
	keyframe_b: objects.KeyFrame,
	current_time: time.Time,
) -> (
	interpolated: objects.KeyFrame,
) {
	start_time: time.Time = keyframe_a.from_time
	end_time: time.Time = keyframe_b.from_time
	duration: time.Duration = time.diff(start_time, end_time)
	// Get parameter `t \in [t_a, t_b]`.
	t: f32 =
		f32(time.duration_nanoseconds(time.diff(start_time, current_time))) /
		f32(time.duration_nanoseconds(duration))

	interpolated_scale: objects.Scale = {
		x = keyframe_a.scale.x * t + (1. - t) * keyframe_b.scale.x,
		y = keyframe_a.scale.y * t + (1. - t) * keyframe_b.scale.y,
		z = keyframe_a.scale.z * t + (1. - t) * keyframe_b.scale.z,
	}
	interpolated_orientation: objects.Orientation = objects.Orientation(
		glm.quatSlerp(glm.quat(keyframe_a.orientation), glm.quat(keyframe_b.orientation), t),
	)
	interpolated_center: glm.vec3 = {
		keyframe_a.center.x * t + (1 - t) * keyframe_b.center.x,
		keyframe_a.center.y * t + (1 - t) * keyframe_b.center.y,
		keyframe_a.center.z * t + (1 - t) * keyframe_b.center.z,
	}

	interpolated = {
		scale       = interpolated_scale,
		orientation = interpolated_orientation,
		center      = interpolated_center,
		from_time   = current_time,
	}

	return
}

