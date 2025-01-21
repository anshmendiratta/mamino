package render

import "core:fmt"

import glm "core:math/linalg/glsl"

// Camera properties.
camera_position_cartesian: glm.vec3 = get_cartesian_coordinates({1.5, 1.5, 1.5})
camera_position_spherical: glm.vec3 = get_spherical_coordinates(camera_position_cartesian)
camera_target: glm.vec3 = {0., 0., 0.}

// bound of theta to avoid going upside down
theta_bound :: (glm.PI / 2.0) - 0.00001

// rates of rotation and zoom
rotation_rate :: 0.1
zoom_rate :: 0.1

// Direction vectors.
world_up: glm.vec3 = {0., 1., 0.}

// Used for the actual vertex transformation.
camera_view_matrix := glm.mat4LookAt(camera_position_cartesian, camera_target, world_up)

update_camera :: proc() {
	camera_view_matrix = glm.mat4LookAt(get_cartesian_coordinates(camera_position_spherical), camera_target, world_up)
}
