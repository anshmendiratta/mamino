package render

import "core:fmt"

import glm "core:math/linalg/glsl"

// Camera properties.
camera_position: glm.vec3 = {1., 1., 1.}
camera_target: glm.vec3 = {0., 0., 0.}
camera_direction := -glm.normalize(camera_position)
camera_speed: f32 = 0.05

// Direction vectors.
world_front: glm.vec3 = {0., 0., -1.}
world_up: glm.vec3 = {0., 1., 0.}
camera_right: glm.vec3 = glm.normalize(glm.cross(world_up, camera_direction))

scaled_delta_angle: f32 = delta_angle * 1e5
accumulated_angle: f32

camera_y_clockwise_rotation_matrix := glm.mat4Rotate({0., 1., 0.}, -scaled_delta_angle)
camera_y_cclockwise_rotation_matrix := glm.mat4Rotate({0., 1., 0.}, scaled_delta_angle)
camera_xz_positive_rotation_matrix := glm.mat4Rotate(camera_right, scaled_delta_angle)
camera_xz_negative_rotation_matrix := glm.mat4Rotate(camera_right, -scaled_delta_angle)

// Used for the actual vertex transformation.
camera_view_matrix := glm.mat4LookAt(camera_position, camera_target, world_up)

update_camera :: proc() {
	camera_direction = -glm.normalize(camera_position)
	camera_right = glm.normalize(glm.cross(world_up, camera_direction))
	scaled_delta_angle = delta_angle * 1e5

	camera_y_clockwise_rotation_matrix = glm.mat4Rotate({0., 1., 0.}, -scaled_delta_angle)
	camera_y_cclockwise_rotation_matrix = glm.mat4Rotate({0., 1., 0.}, scaled_delta_angle)
	camera_xz_positive_rotation_matrix = glm.mat4Rotate(camera_right, scaled_delta_angle)
	camera_xz_negative_rotation_matrix = glm.mat4Rotate(camera_right, -scaled_delta_angle)
}

