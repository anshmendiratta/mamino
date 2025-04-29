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
	keyframes:        [dynamic]CameraKeyFrame "For animations",
	current_keyframe: uint,
}

// Stores `posotion` and `look_at` as cartesian coordinates.
CameraKeyFrame :: struct {
	r:          f32 "Always positive",
	theta:      f32 "From 0 to 2pi",
	phi:        f32 "From 0 to pi",
	look_at:    glm.vec3 "where to point the camera",
	start_time: f32,
}

camera: Camera = {
	keyframes        = {},
	current_keyframe = 0,
}

// Default position is equivalent to the spherical coordinates (1.5, \pi/4, \pi/4).
init_camera :: proc(
	look_at: glm.vec3 = {0., 0., 0.},
	cartesian_position: glm.vec3 = {0.75, 0.75, 1.0606601718},
) {
	cartesian_to_spherical := get_spherical_coordinates_from_cartesian(cartesian_position)
	// (x, y, z) = (r, \theta, \phi)
	append(
		&camera.keyframes,
		CameraKeyFrame {
			r = cartesian_to_spherical.x,
			theta = cartesian_to_spherical.y,
			phi = cartesian_to_spherical.z,
			look_at = look_at,
			start_time = 0,
		},
	)
}

// Used for the actual vertex transformation.
camera_view_matrix: glm.mat4

update_camera_matrix :: proc(camera_target: glm.vec3, camera_position: glm.vec3) {
	camera_view_matrix = glm.mat4LookAt(camera_position, camera_target, world_up)
}

// (x, y, z) = (r, \theta, \phi)
get_spherical_coordinates_from_cartesian :: proc(cartesian: glm.vec3) -> (spherical: glm.vec3) {
	if cartesian == {0., 0., 0.} {
		spherical = {0., 0., 0.}
		return
	}

	// TODO(Ansh): \theta and \phi are switched for some reason. Figure out why.
	spherical.x = glm.length(cartesian)
	spherical.y = glm.acos(cartesian.y / spherical.x)
	spherical.z = glm.atan2(cartesian.z, cartesian.x)

	if cartesian.x < 0 {
		spherical.z += glm.PI
	}

	return
}

// (x, y, z) = (r, \theta, \phi)
camera_get_cartesian_coordinates :: proc(
	camera_keyframe: ^CameraKeyFrame,
) -> (
	cartesian: glm.vec3,
) {
	radius := camera_keyframe.r
	phi := camera_keyframe.phi
	theta := camera_keyframe.theta

	cartesian.x = radius * glm.sin(phi) * glm.cos(theta)
	cartesian.y = radius * glm.cos(phi)
	cartesian.z = radius * glm.sin(phi) * glm.sin(theta)

	return
}

get_cartesian_coordinates_from_spherical :: proc(spherical: glm.vec3) -> (cartesian: glm.vec3) {
	radius := spherical.x
	theta := spherical.y
	phi := spherical.z

	cartesian.x = radius * glm.sin(phi) * glm.cos(theta)
	cartesian.y = radius * glm.cos(phi)
	cartesian.z = radius * glm.sin(phi) * glm.sin(theta)

	return
}

