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

update :: proc(vertices: []Vertex, uniforms: map[string]gl.Uniform_Info) {
	proj := glm.mat4Perspective(glm.radians_f32(45), 1.3, 0.1, 100.0)
	scale := f32(0.3)
	model := glm.mat4{scale, 0., 0., 0., 0., scale, 0., 0., 0., 0., scale, 0., 0., 0., 0., 1}
	v_transform := proj * camera_view_matrix * model
	gl.UniformMatrix4fv(uniforms["v_transform"].location, 1, false, &v_transform[0, 0])
}

draw_cube :: proc(indices: []u16) {
	// TODO: figure out why setting to gl.GREATER results in no output on screen
	// NOTE: This is because it checks for the depth that our fragment shader stores to be greater than whatever the incoming depth value is. In our case, we define the depth to be `1.0` in our vertex shader (in the vec4 conversion), which is the max value, so the frag shader always sees that its own depth value is <= the given value, meaning the fragment does not pass the depth check, and so is not rendered.
	// - Ansh
	gl.DepthFunc(gl.LESS)
	gl.DrawElements(gl.TRIANGLES, i32(len(indices)), gl.UNSIGNED_SHORT, nil)
}

draw_points :: proc(vertices: []Vertex) {
	gl.Enable(gl.PROGRAM_POINT_SIZE)
	gl.Enable(gl.POINT_SMOOTH)
	gl.DrawArrays(gl.POINTS, 0, i32(len(vertices)))
}

draw_lines :: proc(vertices: []u16) {
	gl.DepthFunc(gl.LESS)
	gl.Enable(gl.LINE_SMOOTH)
	gl.LineWidth(10.)
	gl.DrawArrays(gl.LINES, 0, i32(len(vertices)))
}

get_buffer_objects :: proc() -> (u32, u32, u32) {
	vao, vbo, ebo: u32
	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)
	return vao, vbo, ebo
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

