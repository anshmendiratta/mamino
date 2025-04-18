package render

import "core:fmt"

import glm "core:math/linalg/glsl"

// Camera properties.
// Stored as spherical in the struct. Used as cartesian whenever necessary.
Camera :: struct {
	r:     f32 "Always positive",
	theta: f32 "From 0 to 2pi",
	phi:   f32 "From -pi/2 to pi/2",
}

camera := Camera{1.5, glm.PI / 4, glm.PI / 4}

camera_position_cartesian: glm.vec3 = get_cartesian_coordinates(&camera)
camera_position_spherical: Camera = get_spherical_coordinates(camera_position_cartesian)
camera_target: glm.vec3 = {0., 0., 0.}

// Bound of theta to avoid going upside down.
phi_bound :: glm.PI - 1e-5

// Rates of rotation and zoom.
keyboard_rotation_rate :: 0.1
cursor_sensitivity :: 0.005
zoom_rate :: 0.1

// Direction vectors.
world_up: glm.vec3 = {0., 1., 0.}

// Used for the actual vertex transformation.
camera_view_matrix := glm.mat4LookAt(camera_position_cartesian, camera_target, world_up)

update_camera :: proc() {
	camera_view_matrix = glm.mat4LookAt(
		get_cartesian_coordinates(&camera),
		camera_target,
		world_up,
	)
}

get_spherical_coordinates :: proc(cartesian: glm.vec3) -> (spherical_camera: Camera) {
	spherical_camera.r = glm.length(cartesian)
	spherical_camera.phi = glm.atan2(cartesian.z / cartesian.x, cartesian.x)
	spherical_camera.theta = glm.acos(cartesian.y / spherical_camera.r)

	if cartesian.x < 0 {
		spherical_camera.phi += glm.PI
	}

	return
}

get_cartesian_coordinates :: proc(camera: ^Camera) -> (cartesian: glm.vec3) {
	radius := camera.r
	phi := camera.phi
	theta := camera.theta

	cartesian.x = radius * glm.sin(phi) * glm.cos(theta)
	cartesian.y = radius * glm.cos(phi)
	cartesian.z = radius * glm.sin(phi) * glm.sin(theta)

	return
}

