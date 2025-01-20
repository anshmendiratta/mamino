package render

import "core:c"
import "core:fmt"

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

Vertex :: struct {
	position: glm.vec3,
	color:    glm.vec3,
}

update :: proc(vertices: []Vertex) -> []Vertex {
	angle: f32 = 0.01
	view := glm.mat4LookAt({0, -1, +1}, {0, 1, 0}, {0, 0, 1})
	proj := glm.mat4Perspective(90, 2.0, 0.1, 100.0)
	scale := glm.mat3{0.5, 0., 0., 0., 0.5, 0., 0., 0., 0.5}
	for &vertex, idx in vertices {
		vertex.position =
			(glm.vec4{vertex.position.x, vertex.position.y, vertex.position.z, 1.0} * glm.mat4Rotate({0.5, 0.5, 1.}, angle)).xyz
	}

	return vertices
}

draw_cube :: proc(indices: []u16) {
	gl.Enable(gl.DEPTH_TEST)
	// todo: figure out why setting to gl.GREATER results in no output on screen
	gl.DepthFunc(gl.LESS)
	gl.DrawElements(gl.TRIANGLES, i32(len(indices)), gl.UNSIGNED_SHORT, nil)
}

draw_points :: proc(vertices: []Vertex) {
	gl.Enable(gl.PROGRAM_POINT_SIZE)
	gl.Enable(gl.POINT_SMOOTH)
	gl.DrawArrays(gl.POINTS, 0, i32(len(vertices)))
}

get_objects :: proc() -> (vao: u32, vbo: u32, ebo: u32) {
	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)
	return
}

bind_data :: proc(
	cube_vao: u32,
	cube_vbo: u32,
	cube_ebo: u32,
	data: []Vertex,
	indices: []u16,
) {
	// Bind vertices to vertex buffer.
	gl.BindVertexArray(cube_vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, cube_vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(data) * size_of(Vertex), raw_data(data), gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, cube_ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices) * size_of(u16), raw_data(indices), gl.STATIC_DRAW)
}

