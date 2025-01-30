package render

import "core:c"
import "core:fmt"

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

Vertex :: struct {
	position: glm.vec3,
	color:    glm.vec4,
}

update_shader :: proc(uniforms: map[string]gl.Uniform_Info) {
	proj := glm.mat4Perspective(glm.radians_f32(60), 1.0, 0.1, 100.0)
	scale := f32(0.3)
	model := glm.mat4{scale, 0., 0., 0., 0., scale, 0., 0., 0., 0., scale, 0., 0., 0., 0., 1}
	gl.UniformMatrix4fv(uniforms["proj"].location, 1, false, &proj[0, 0])
	gl.UniformMatrix4fv(uniforms["view"].location, 1, false, &camera_view_matrix[0, 0])
	gl.UniformMatrix4fv(uniforms["model"].location, 1, false, &model[0, 0])
}

draw_cube :: proc(vertices: []Vertex, indices_count: i32) {
	gl.DepthFunc(gl.LESS)
	// TODO: figure out why this doesn't work with `gl.DrawArrays`
	gl.DrawElements(gl.TRIANGLES, indices_count, gl.UNSIGNED_SHORT, nil)
}

draw_points :: proc(vertices: []Vertex, indices: []u16) {
	gl.Enable(gl.PROGRAM_POINT_SIZE)
	gl.Enable(gl.POINT_SMOOTH)
	gl.DrawElements(gl.POINTS, i32(len(indices)), gl.UNSIGNED_SHORT, nil)
}

draw_lines :: proc(vertices: []Vertex, indices: []u16) {
	gl.DepthFunc(gl.LESS)
	gl.Enable(gl.LINE_SMOOTH)
	gl.LineWidth(5.)
	gl.DrawElements(gl.LINES, i32(len(indices)), gl.UNSIGNED_SHORT, nil)
}

draw_axes :: proc(indices: []u16) {
	gl.DepthFunc(gl.LESS)
	gl.Enable(gl.LINE_SMOOTH)
	gl.LineWidth(2.)
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
	gl.DrawElements(gl.LINES, i32(len(indices)), gl.UNSIGNED_SHORT, nil)
}

get_buffer_objects :: proc() -> (vao: u32, vbo: u32, ebo: u32) {
	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)
	return
}

bind_data :: proc(vbo: u32, ebo: u32, data: []Vertex, indices: []u16) {
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(data) * size_of(Vertex), raw_data(data), gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
	gl.VertexAttribPointer(1, 4, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(indices) * size_of(u16),
		raw_data(indices),
		gl.STATIC_DRAW,
	)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(indices) * size_of(u16),
		raw_data(indices),
		gl.STATIC_DRAW,
	)
}

