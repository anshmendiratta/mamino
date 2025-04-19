package objects

import "core:fmt"

import glm "core:math/linalg/glsl"

import "../objects"


camera_target: glm.vec3 = {0., 0., 0.}
// \phi's bound to avoid going over the poles.
phi_bound :: glm.PI - 1e-5
// Rates of rotation and zoom.
keyboard_rotation_rate :: 0.1
cursor_drag_sensitivity :: 0.005
cursor_scroll_sensitivity :: 0.3
zoom_rate :: 0.1
// Direction vectors.
world_up: glm.vec3 = {0., 1., 0.}

// Camera stored as spherical in the struct. Used as cartesian whenever necessary.
Camera :: struct {
	r:         f32 "Always positive",
	theta:     f32 "From 0 to 2pi",
	phi:       f32 "From -pi/2 to pi/2",
	keyframes: [dynamic]objects.KeyFrame "For animations",
}

camera := Camera {
	r         = 1.5,
	theta     = glm.PI / 4,
	phi       = glm.PI / 4,
	keyframes = {},
}

// Used for the actual vertex transformation.
camera_view_matrix := glm.mat4LookAt(
	camera_get_cartesian_coordinates(&camera),
	camera_target,
	world_up,
)

update_camera_matrix :: proc() {
	camera_view_matrix = glm.mat4LookAt(
		camera_get_cartesian_coordinates(&camera),
		camera_target,
		world_up,
	)
}

get_spherical_coordinates_from_cartesian :: proc(
	cartesian: glm.vec3,
) -> (
	spherical_camera: Camera,
) {
	spherical_camera.r = glm.length(cartesian)
	spherical_camera.phi = glm.atan2(cartesian.z / cartesian.x, cartesian.x)
	spherical_camera.theta = glm.acos(cartesian.y / spherical_camera.r)

	if cartesian.x < 0 {
		spherical_camera.phi += glm.PI
	}

	return
}

camera_get_cartesian_coordinates :: proc(camera: ^Camera) -> (cartesian: glm.vec3) {
	radius := camera.r
	phi := camera.phi
	theta := camera.theta

	cartesian.x = radius * glm.sin(phi) * glm.cos(theta)
	cartesian.y = radius * glm.cos(phi)
	cartesian.z = radius * glm.sin(phi) * glm.sin(theta)

	return
}
