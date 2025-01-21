package render

import glm "core:math/linalg/glsl"

// equations here will differ from wikipedia due to a difference in conventions
// https://en.wikipedia.org/wiki/Spherical_coordinate_system#Cartesian_coordinates

// equations were found from: https://nerdhut.de/2020/05/09/unity-arcball-camera-spherical-coordinates/
// NOTE: assumes Unity uses the same coordinate system

// from empirical testing, phi may be backwards (depending on convention), however, it results
// in correct behavior if negated

// vec3 of { radius, phi, theta }
get_spherical_coordinates :: proc(cartesian: glm.vec3) -> (spherical: glm.vec3) {
    spherical[0] = glm.length(cartesian) // radius
    spherical[1] = glm.atan2(cartesian.z / cartesian.x, cartesian.x) // phi
    spherical[2] = glm.acos(cartesian.y / spherical[0]) // theta

    if cartesian.x < 0 {
        spherical[1] += glm.PI
    }

    return
}

get_cartesian_coordinates :: proc(spherical: glm.vec3) -> (cartesian: glm.vec3) {
    radius := spherical[0]
    phi := spherical[1]
    theta := spherical[2]

    cartesian.x = radius * glm.cos(theta) * glm.cos(phi)
    cartesian.y = radius * glm.sin(theta)
    cartesian.z = radius * glm.cos(theta) * glm.sin(phi)

    return
}