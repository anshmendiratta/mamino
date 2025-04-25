package render

import "core:fmt"
import "core:math"
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
global_time: f32

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
	// if !(.manual_camera in configuration) {
	scene_update_camera(&objects.camera)
	// }

	global_time = f32(glfw.GetTime())
}

scene_update_camera :: proc(camera: ^objects.Camera) {
	objects.object_catch_up_keyframe(&objects.camera, global_time)
	last_keyframe: objects.CameraKeyFrame =
		objects.camera.keyframes[objects.camera.current_keyframe]
	// Only pass through the keyframes once.
	next_keyframe_idx: u32 = glm.clamp(
		u32(objects.camera.current_keyframe + 1),
		u32(0),
		u32(len(objects.camera.keyframes) - 1),
	)
	next_keyframe: objects.CameraKeyFrame = objects.camera.keyframes[next_keyframe_idx]
	interpolated_keyframe := scene_interpolate_camera_keyframes(
		last_keyframe,
		next_keyframe,
		global_time,
	)
	camera_position_spherical := objects.get_cartesian_coordinates_from_spherical(
		glm.vec3{interpolated_keyframe.r, interpolated_keyframe.theta, interpolated_keyframe.phi},
	)
	objects.update_camera_matrix(
		camera_target = interpolated_keyframe.look_at,
		camera_position = camera_position_spherical,
	)
}

scene_render_cube :: proc(object: ^objects.Object, cube: ^objects.Cube) {
	objects.object_catch_up_keyframe(object, global_time) // Set appropriate keyframe.
	// Interpolate between the last and the almost-next frame.
	last_keyframe: objects.ModelKeyFrame = cube.keyframes[cube.current_keyframe]
	// Only pass through the keyframes once.
	next_keyframe_idx: u32 = glm.clamp(
		u32(cube.current_keyframe + 1),
		u32(0),
		u32(len(cube.keyframes) - 1),
	)
	next_keyframe: objects.ModelKeyFrame = cube.keyframes[next_keyframe_idx]
	interpolated_keyframe :=
		scene_interpolate_model_keyframes(last_keyframe, next_keyframe, global_time) if last_keyframe != next_keyframe else last_keyframe
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
	last_keyframe: objects.ModelKeyFrame = sphere.keyframes[sphere.current_keyframe]
	// Only pass through the keyframes once.
	next_keyframe_idx: u32 = glm.clamp(
		u32(sphere.current_keyframe + 1),
		u32(0),
		u32(len(sphere.keyframes) - 1),
	)
	next_keyframe: objects.ModelKeyFrame = sphere.keyframes[next_keyframe_idx]
	interpolated_keyframe :=
		scene_interpolate_model_keyframes(last_keyframe, next_keyframe, global_time) if last_keyframe != next_keyframe else last_keyframe
	vertices, indices, line_indices := objects.get_sphere_data(sphere, interpolated_keyframe)
	defer delete(vertices)
	defer delete(indices)
	defer delete(line_indices)

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
// NOTE(Ansh): All the reassignments are taken from https://easings.net/.
scene_interpolate_model_keyframes :: proc(
	keyframe_a, keyframe_b: objects.ModelKeyFrame,
	current_time: f32,
) -> (
	interpolated: objects.ModelKeyFrame,
) {
	start_time: f32 = keyframe_a.start_time
	end_time: f32 = keyframe_b.start_time
	duration: f32
	t: f32
	if start_time != end_time {
		duration = end_time - start_time
		// Get parameter `t \in [t_a, t_b]`.
		t = (current_time - start_time) / duration
	} else {
		duration = 0
		t = 0
	}

	// Just rewrite `t` depending on the required easing function.
	switch keyframe_a.easing {
	case objects.EasingFunction.Linear:
		t = t
	case objects.EasingFunction.Quad:
		if t < 0.5 {
			t = 2 * math.pow_f32(t, 2)
		} else {
			t = 1 - math.pow_f32(-2 * t + 2, 2) / 2
		}
	case objects.EasingFunction.Cubic:
		if t < 0.5 {
			t = 4 * math.pow_f32(t, 3)
		} else {
			t = 1 - math.pow_f32(-2 * t + 2, 3) / 2
		}
	case objects.EasingFunction.Sine:
		t = -(math.cos(glm.PI * t) - 1) / 2
	case objects.EasingFunction.Elastic:
		c_5 := f32(2 * glm.PI / 4.5)
		if t < 0.5 {
			t = -math.pow_f32(2, 20 * t - 10) * math.sin((20 * t - 11.125) * c_5) / 2
		} else {
			t = math.pow_f32(2, -20 * t + 10) * math.sin((20 * t - 11.125) * c_5) / 2 + 1
		}
	case objects.EasingFunction.Circ:
		if t < 0.5 {
			t = (1 - math.sqrt(1 - math.pow_f32(2 * t, 2))) / 2
		} else {
			t = (math.sqrt(1 - math.pow_f32(-2 * t + 2, 2)) + 1) / 2
		}
	}

	interpolated_scale: objects.Scale = {
		keyframe_a.scale.x * (1 - t) + t * keyframe_b.scale.x,
		keyframe_a.scale.y * (1 - t) + t * keyframe_b.scale.y,
		keyframe_a.scale.z * (1 - t) + t * keyframe_b.scale.z,
	}
	interpolated_orientation: objects.Orientation = objects.Orientation(
		glm.quatSlerp(glm.quat(keyframe_a.orientation), glm.quat(keyframe_b.orientation), f32(t)),
	)
	interpolated_position: glm.vec3 = {
		keyframe_a.position.x * (1 - t) + t * keyframe_b.position.x,
		keyframe_a.position.y * (1 - t) + t * keyframe_b.position.y,
		keyframe_a.position.z * (1 - t) + t * keyframe_b.position.z,
	}
	interpolated = {
		scale       = interpolated_scale,
		orientation = interpolated_orientation,
		position    = interpolated_position,
		start_time  = current_time,
	}

	return
}


scene_interpolate_camera_keyframes :: proc(
	keyframe_a, keyframe_b: objects.CameraKeyFrame,
	current_time: f32,
) -> (
	interpolated: objects.CameraKeyFrame,
) {
	start_time: f32 = keyframe_a.start_time
	end_time: f32 = keyframe_b.start_time
	duration: f32
	t: f32
	if start_time != end_time {
		duration = end_time - start_time
		// Get parameter `t \in [t_a, t_b]`.
		t = (current_time - start_time) / duration
	} else {
		duration = 0
		t = 0
	}

	interpolated_r: f32 = glm.lerp(keyframe_a.r, keyframe_b.r, t)
	interpolated_theta: f32 = glm.lerp(keyframe_a.theta, keyframe_b.theta, t)
	interpolated_phi: f32 = glm.lerp(keyframe_a.phi, keyframe_b.phi, t)

	last_look_at_spherical := objects.get_spherical_coordinates_from_cartesian(keyframe_a.look_at)
	final_look_at_spherical := objects.get_spherical_coordinates_from_cartesian(keyframe_b.look_at)
	// fmt.println(last_look_at_spherical, final_look_at_spherical, t)
	interpolated_look_at_spherical := glm.vec3 {
		glm.lerp(last_look_at_spherical.x, final_look_at_spherical.x, t),
		glm.lerp(last_look_at_spherical.y, final_look_at_spherical.y, t),
		glm.lerp(last_look_at_spherical.z, final_look_at_spherical.z, t),
	}
	interpolated_look_at_cartesian := objects.get_cartesian_coordinates_from_spherical(
		interpolated_look_at_spherical,
	)

	interpolated = {
		r          = interpolated_r,
		theta      = interpolated_theta,
		phi        = interpolated_phi,
		look_at    = interpolated_look_at_cartesian,
		start_time = current_time,
	}

	fmt.println(
		"cartesian =",
		objects.get_cartesian_coordinates_from_spherical(
			glm.vec3{interpolated.r, interpolated.theta, interpolated.phi},
		),
	)

	return
}

