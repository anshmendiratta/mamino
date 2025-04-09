package render

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:testing"

import "base:builtin"

import gl "vendor:OpenGL"
import "vendor:glfw"

import "../objects"

highlighted_debug_object_id: objects.ObjectID = -1
render_normals: bool = false
render_faces: bool = false

@(private)
global_time: f64

HIGHLIGHTED_OBJECT_COLOR :: glm.vec4{0.15, 0.83, 1.0, 0.5}


Scene :: struct {
	objects: [dynamic]^objects.Object,
}

create_scene :: proc() -> Scene {
	return Scene{}
}

scene_add_object :: proc(scene: ^Scene, object: ^objects.Object) {
	append(&scene.objects, object)
}

scene_get_objects_count :: proc(scene: ^Scene) -> uint {
	return len(scene.objects)
}

scene_render :: proc(scene: ^Scene, configuration: MaminoConfiguration) {

	render_objects := scene.objects
	for generic_object in render_objects {
		#partial switch &object in generic_object {
		// Do not need to worry about the constant coloring below, as the below call copies over from the base cube, whose color is unchanging.
		case objects.Cube:
			scene_render_cube(generic_object, &generic_object.(objects.Cube))

			// FIX(Ansh): Normal rendering doesn't want to happen on debug mode. Probably to do with setting the PolygonMode.
			if ODIN_DEBUG && render_normals {
				normal_vao, normal_vbo, normal_ebo := get_buffer_objects()
				face_normals := objects.get_cube_normals_coordinates(object)
				bind_data(normal_vao, normal_vbo, normal_ebo, face_normals, {0, 1, 2, 3, 4, 5})
				draw_lines(face_normals, 6)

				gl.DeleteVertexArrays(1, &normal_vao)
				gl.DeleteBuffers(1, &normal_vbo)
				gl.DeleteBuffers(1, &normal_ebo)
			}
		case objects.Sphere:
			scene_render_sphere(generic_object, &generic_object.(objects.Sphere))
		}
	}

	if .render_axes in configuration {
		scene_render_coordinate_axes()
	}
	if .render_axes_subgrid in configuration {
		scene_render_subgrid_axes()
	}

	global_time = glfw.GetTime()
}

scene_render_cube :: proc(object: ^objects.Object, cube: ^objects.Cube) {
	objects.object_catch_up_keyframe(object, global_time) // Set appropriate keyframe.
	// Interpolate between the last and the almost-next frame.
	last_keyframe: objects.KeyFrame = cube.keyframes[cube.current_keyframe]
	// Only pass through the keyframes once.
	next_keyframe_idx: u32 = glm.clamp(
		u32(cube.current_keyframe + 1),
		u32(0),
		u32(len(cube.keyframes) - 1),
	)
	next_keyframe: objects.KeyFrame = cube.keyframes[next_keyframe_idx]
	interpolated_keyframe :=
		scene_interpolate_keyframes(last_keyframe, next_keyframe, global_time) if last_keyframe != next_keyframe else last_keyframe
	vertices, indices, line_indices := objects.get_cube_data(cube, interpolated_keyframe)

	// Cube.
	if cube.id == highlighted_debug_object_id {
		objects.color_vertices(&vertices, HIGHLIGHTED_OBJECT_COLOR)
	}
	cube_vao, cube_vbo, cube_ebo := get_buffer_objects()
	bind_data(cube_vao, cube_vbo, cube_ebo, vertices, indices)
	draw_object(vertices, i32(len(indices)))
	// Points.
	point_vao, point_vbo, point_ebo := get_buffer_objects()
	objects.color_vertices(&vertices, objects.point_color)
	bind_data(point_vao, point_vbo, point_ebo, vertices, indices)
	draw_points(vertices, indices)
	// Lines.
	line_vao, line_vbo, line_ebo := get_buffer_objects()
	objects.color_vertices(&vertices, objects.line_color)
	bind_data(line_vao, line_vbo, line_ebo, vertices, line_indices)
	draw_lines(vertices, i32(len(line_indices)))

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

scene_render_sphere :: proc(object: ^objects.Object, sphere: ^objects.Sphere) {
	objects.object_catch_up_keyframe(object, global_time) // Set appropriate keyframe.
	// Interpolate between the last and the almost-next frame.
	last_keyframe: objects.KeyFrame = sphere.keyframes[sphere.current_keyframe]
	// Only pass through the keyframes once.
	next_keyframe_idx: u32 = glm.clamp(
		u32(sphere.current_keyframe + 1),
		u32(0),
		u32(len(sphere.keyframes) - 1),
	)
	next_keyframe: objects.KeyFrame = sphere.keyframes[next_keyframe_idx]
	interpolated_keyframe :=
		scene_interpolate_keyframes(last_keyframe, next_keyframe, global_time) if last_keyframe != next_keyframe else last_keyframe
	vertices, indices, line_indices := objects.get_sphere_data(sphere, interpolated_keyframe)

	// sphere.
	if sphere.id == highlighted_debug_object_id {
		objects.color_vertices(&vertices, HIGHLIGHTED_OBJECT_COLOR)
	}
	sphere_vao, sphere_vbo, sphere_ebo := get_buffer_objects()
	bind_data(sphere_vao, sphere_vbo, sphere_ebo, vertices, indices)
	draw_object(vertices, i32(len(indices)))
	// Points.
	point_vao, point_vbo, point_ebo := get_buffer_objects()
	objects.color_vertices(&vertices, objects.point_color)
	bind_data(point_vao, point_vbo, point_ebo, vertices, indices)
	draw_points(vertices, indices)
	// Lines.
	line_vao, line_vbo, line_ebo := get_buffer_objects()
	objects.color_vertices(&vertices, objects.line_color)
	bind_data(line_vao, line_vbo, line_ebo, vertices, line_indices)
	draw_lines(vertices, i32(len(line_indices)))

	gl.DeleteVertexArrays(1, &sphere_vao)
	gl.DeleteBuffers(1, &sphere_vbo)
	gl.DeleteBuffers(1, &sphere_ebo)
	gl.DeleteVertexArrays(1, &point_vao)
	gl.DeleteBuffers(1, &point_vbo)
	gl.DeleteBuffers(1, &point_ebo)
	gl.DeleteVertexArrays(1, &line_vao)
	gl.DeleteBuffers(1, &line_vbo)
	gl.DeleteBuffers(1, &line_ebo)
}

scene_render_coordinate_axes :: proc() {
	axes_vao, axes_vbo, axes_ebo := get_buffer_objects()
	bind_data(
		axes_vao,
		axes_vbo,
		axes_ebo,
		objects.coordinate_axes_vertices,
		objects.coordinate_axes_indices,
	)
	draw_axes(i32(len(objects.coordinate_axes_indices)))
	gl.DeleteVertexArrays(1, &axes_vao)
	gl.DeleteBuffers(1, &axes_vbo)
	gl.DeleteBuffers(1, &axes_ebo)
}

scene_render_subgrid_axes :: proc() {
	subgrid_axes_vao, subgrid_axes_vbo, subgrid_axes_ebo := get_buffer_objects()
	bind_data(
		subgrid_axes_vao,
		subgrid_axes_vbo,
		subgrid_axes_ebo,
		objects.subgrid_axes_vertices,
		objects.subgrid_axes_indices,
	)
	draw_axes(i32(len(objects.subgrid_axes_indices)))
	gl.DeleteVertexArrays(1, &subgrid_axes_vao)
	gl.DeleteBuffers(1, &subgrid_axes_vbo)
	gl.DeleteBuffers(1, &subgrid_axes_ebo)
}

// NOTE(Ansh): Could also use the built-in `lerp` functions, but the overhead in calling them may outweigh the cost of our own implementation.
scene_interpolate_keyframes :: proc(
	keyframe_a, keyframe_b: objects.KeyFrame,
	current_time: f64,
) -> (
	interpolated: objects.KeyFrame,
) {
	start_time: f64 = keyframe_a.start_time
	end_time: f64 = keyframe_b.start_time
	duration: f64 = end_time - start_time
	// Get parameter `t \in [t_a, t_b]`.
	t: f32 = f32((current_time - start_time) / duration)

	interpolated_scale: objects.Scale = {
		x = keyframe_a.scale.x * (1 - t) + t * keyframe_b.scale.x,
		y = keyframe_a.scale.y * (1 - t) + t * keyframe_b.scale.y,
		z = keyframe_a.scale.z * (1 - t) + t * keyframe_b.scale.z,
	}
	interpolated_orientation: objects.Orientation = objects.Orientation(
		glm.quatSlerp(glm.quat(keyframe_a.orientation), glm.quat(keyframe_b.orientation), f32(t)),
	)
	interpolated_center: glm.vec3 = {
		keyframe_a.center.x * (1 - t) + t * keyframe_b.center.x,
		keyframe_a.center.y * (1 - t) + t * keyframe_b.center.y,
		keyframe_a.center.z * (1 - t) + t * keyframe_b.center.z,
	}

	interpolated = {
		scale       = interpolated_scale,
		orientation = interpolated_orientation,
		center      = interpolated_center,
		start_time  = current_time,
	}

	return
}

