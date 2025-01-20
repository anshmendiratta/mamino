#+feature dynamic-literals

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

update :: proc(vertices: [dynamic]Vertex) -> [dynamic]Vertex {
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

draw_cube :: proc(vertices: []Vertex) {
	gl.Enable(gl.DEPTH_TEST)
	gl.DepthFunc(gl.LESS)
	gl.DrawArrays(gl.TRIANGLES, 0, i32(len(vertices)))
}

draw_points :: proc(vertices: []Vertex) {
	gl.Enable(gl.PROGRAM_POINT_SIZE)
	gl.Enable(gl.POINT_SMOOTH)
	gl.DrawArrays(gl.POINTS, 0, i32(len(vertices)))
}

draw_lines :: proc(vertices: []Vertex) {
	gl.DrawArrays(gl.LINE_STRIP, 0, i32(len(vertices)))
}

get_cube_objects :: proc() -> (u32, u32, u32) {
	// Get Vertex arrays.
	triangle_vao: u32
	gl.GenVertexArrays(1, &triangle_vao)
	// Get Vertex buffer objects, and Element Buffer Objects (?)
	triangle_vbo, triangle_ebo: u32
	gl.GenBuffers(1, &triangle_vbo)
	gl.GenBuffers(1, &triangle_ebo)

	return triangle_vao, triangle_vbo, triangle_ebo
}

get_point_objects :: proc() -> (u32, u32, u32) {
	// Get Vertex arrays.
	point_vao: u32
	gl.GenVertexArrays(1, &point_vao)
	// Get Vertex buffer objects, and Element Buffer Objects (?)
	point_vbo, point_ebo: u32
	gl.GenBuffers(1, &point_vbo)
	gl.GenBuffers(1, &point_ebo)

	return point_vao, point_vbo, point_ebo
}

get_line_objects :: proc() -> (u32, u32, u32) {
	line_vao, line_vbo, line_ebo: u32
	gl.GenVertexArrays(n=1, arrays = &line_vao)
	gl.GenBuffers(1, &line_vao)
	gl.GenBuffers(1, &line_ebo)

	return line_vao, line_vbo, line_ebo
}

// NOTE: VAO unused??? - Henock
bind_data :: proc(
	vao: u32,
	vbo: u32,
	ebo: u32,
	data: [dynamic]Vertex,
	indices: [dynamic]u16,
) {
	// Bind vertices to vertex buffer.
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(data) * size_of(Vertex), raw_data(data), gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))

	// Bind vertex array indices to index buffer.
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(indices) * size_of(u16),
		raw_data(indices),
		gl.STATIC_DRAW,
	)
}

