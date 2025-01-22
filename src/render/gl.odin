package render

import "core:c"
import "core:fmt"

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

//import ft "shared:freetype"

Vertex :: struct {
	position: glm.vec3,
	color:    glm.vec3,
}

update :: proc(vertices: []Vertex, uniforms: map[string]gl.Uniform_Info) {
	proj := glm.mat4Perspective(glm.radians_f32(45), 1.3, 0.1, 100.0)
	scale := f32(0.3)
	model := glm.mat4{scale, 0., 0., 0., 0., scale, 0., 0., 0., 0., scale, 0., 0., 0., 0., 1}
	v_transform := proj * camera_view_matrix * model
	gl.UniformMatrix4fv(uniforms["v_transform"].location, 1, false, &v_transform[0, 0])
}

draw_cube :: proc(vertices: []Vertex, indices_count: i32) {
	gl.DepthFunc(gl.LESS)
	// TODO: figure out why this doesn't work with `gl.DrawArrays`
	gl.DrawElements(gl.TRIANGLES, indices_count, gl.UNSIGNED_SHORT, nil)
}

draw_points :: proc(indices: []u16) {
	gl.Enable(gl.PROGRAM_POINT_SIZE)
	gl.Enable(gl.POINT_SMOOTH)
	gl.DrawArrays(gl.POINTS, 0, i32(len(indices)))
}

draw_lines :: proc(indices: []u16) {
	gl.DepthFunc(gl.LESS)
	gl.Enable(gl.LINE_SMOOTH)
	gl.LineWidth(5.)
	gl.DrawElements(gl.LINES, i32(len(indices)), gl.UNSIGNED_SHORT, nil)
}

draw_axes :: proc(indices: []u16) {
	gl.DepthFunc(gl.LESS)
	gl.Enable(gl.LINE_SMOOTH)
	gl.LineWidth(2.)
	gl.DrawElements(gl.LINES, i32(len(indices)), gl.UNSIGNED_SHORT, nil)
}

get_buffer_objects :: proc() -> (vao: u32, vbo: u32, ebo: u32) {
	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)
	return
}

// NOTE: VAO unused??? - Henock
// NOTE: Seems like it. Removed from func def. - Ansh
bind_data :: proc(vbo: u32, ebo: u32, data: []Vertex, indices: []u16) {
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(data) * size_of(Vertex), raw_data(data), gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))
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

