package render

import glm "core:math/linalg/glsl"

radius: f32 = 2
camera_position: glm.vec3 = {1., 1., 1.}
camera_target: glm.vec3 = {0., 0., 0.}
camera_direction: glm.vec3 = glm.normalize(camera_position - camera_target)
camera_speed: f32 = 3
camera_front: glm.vec3 = {0., 0., -1.}
camera_up: glm.vec3 = {0., 1., 0.}

view := glm.mat4LookAt(camera_position, camera_direction, camera_up)

