package test

import "core:fmt"

import glm "core:math/linalg/glsl"
import "core:testing"

import "../src/objects"
// import "../src/render"


@(test)
test_cartesian_to_spherical :: proc(_: ^testing.T) {
	cartesian: glm.vec3 = {1., glm.sqrt(f32(2)), 1.}
	expected_spherical: glm.vec3

	expected_spherical.x = glm.length(cartesian)
	expected_spherical.y = glm.acos(cartesian.y / expected_spherical.r)
	expected_spherical.z = glm.atan2(cartesian.z, cartesian.x)

	if cartesian.x < 0 {
		expected_spherical.z += glm.PI
	}

	assert(
		expected_spherical == objects.get_spherical_coordinates_from_cartesian(cartesian),
		"Did not convert from cartesian to spherical correctly.",
	)
}

@(test)
test_spherical_to_cartesian :: proc(_: ^testing.T) {
	spherical: glm.vec3 = {2., glm.PI / 4, glm.PI / 4}

	radius := spherical.x
	theta := spherical.y
	phi := spherical.z

	expected_cartesian: glm.vec3 = {1., 1., glm.sqrt(f32(2))}

	fmt.println(expected_cartesian, objects.get_cartesian_coordinates_from_spherical(spherical))

	assert(
		expected_cartesian == objects.get_cartesian_coordinates_from_spherical(spherical),
		"Did not convert from spherical to cartesian correctly.",
	)
}

