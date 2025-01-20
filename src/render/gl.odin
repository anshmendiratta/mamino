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

update :: proc(vertices: [dynamic]Vertex, uniforms: map[string]gl.Uniform_Info, time_s: f64) {
	view := glm.mat4LookAt({0, -1, +1}, {0, 1, 0}, {0, 0, 1})
	proj := glm.mat4Perspective(90, 1.3, 0.1, 100.0)
	rotation := glm.mat4Rotate({1., 1., 1.}, f32(time_s))
	scale_scalar := f32(0.2)
	scale := glm.mat4 {
		scale_scalar,
		0.,
		0.,
		0.,
		0.,
		scale_scalar,
		0.,
		0.,
		0.,
		0.,
		scale_scalar,
		0.,
		0.,
		0.,
		0.,
		1,
	}
	v_transform := rotation * scale
	gl.UniformMatrix4fv(uniforms["v_transform"].location, 1, false, &v_transform[0, 0])
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

draw_lines :: proc(vertices: []u16) {
	gl.Enable(gl.DEPTH_TEST)
	gl.DepthFunc(gl.LESS)
	gl.Enable(gl.LINE_SMOOTH)
	gl.LineWidth(10.)
	gl.DrawArrays(gl.LINES, 0, i32(len(vertices)))
}

get_cube_objects :: proc() -> (u32, u32, u32) {
	// Get Vertex arrays.
	triangle_vao, triangle_vbo, triangle_ebo: u32
	gl.GenVertexArrays(1, &triangle_vao)
	// Get Vertex buffer objects, and Element Buffer Objects (?)
	gl.GenBuffers(1, &triangle_vbo)
	gl.GenBuffers(1, &triangle_ebo)

	return triangle_vao, triangle_vbo, triangle_ebo
}

get_point_objects :: proc() -> (u32, u32, u32) {
	point_vao, point_vbo, point_ebo: u32
	// Get Vertex arrays.
	gl.GenVertexArrays(1, &point_vao)
	// Get Vertex buffer objects, and Element Buffer Objects (?)
	gl.GenBuffers(1, &point_vbo)
	gl.GenBuffers(1, &point_ebo)

	return point_vao, point_vbo, point_ebo
}

get_line_objects :: proc() -> (u32, u32, u32) {
	line_vao, line_vbo, line_ebo: u32
	// Get Vertex arrays.
	gl.GenVertexArrays(1, &line_vao)
	// Get Vertex buffer objects, and Element Buffer Objects (?)
	gl.GenBuffers(1, &line_vbo)
	gl.GenBuffers(1, &line_ebo)

	return line_vao, line_vbo, line_ebo
}

// NOTE: VAO unused??? - Henock
bind_data :: proc(vao: u32, vbo: u32, ebo: u32, data: [dynamic]Vertex, indices: [dynamic]u16) {
	// Bind vertices to vertex buffer.
	// TODO: Find a way to use `BufferSubData` instead. Using `BufferData` works but reallocates memory.
	// Rebind the updated vertices to the vertex buffer.
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

