package render

import "core:c"
import "core:fmt"

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

import "../objects"

@(cold)
@(require_results)
@(deferred_out = mamino_deinit_gl)
mamino_init_gl :: proc() -> (program_id: u32, uniforms: map[string]gl.Uniform_Info) {
	when ODIN_DEBUG {
		gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
	}
	gl.Enable(gl.DEPTH_TEST)

	ok: bool
	program_id, ok = gl.load_shaders_source(mamino_render_vert, mamino_render_frag)

	if !ok {
		fmt.eprintln("Failed to load shaders.")
		return
	}
	gl.UseProgram(program_id)

	uniforms = gl.get_uniforms_from_program(program_id)

	return
}

mamino_deinit_gl :: proc(program_id: u32, uniforms: map[string]gl.Uniform_Info) {
	gl.DeleteProgram(program_id)
	delete(uniforms)
}

update_shader :: proc(uniforms: map[string]gl.Uniform_Info, window_aspect_ratio: f32) {
	proj := glm.mat4Perspective(glm.radians_f32(60), 1.0, 0.1, 100.0)
	scale := f32(0.3)
	model := glm.mat4{scale, 0., 0., 0., 0., scale, 0., 0., 0., 0., scale, 0., 0., 0., 0., 1}
	// MVP matrices.
	gl.UniformMatrix4fv(uniforms["proj"].location, 1, false, &proj[0, 0])
	gl.UniformMatrix4fv(uniforms["view"].location, 1, false, &objects.camera_view_matrix[0, 0])
	gl.UniformMatrix4fv(uniforms["model"].location, 1, false, &model[0, 0])
	// Window size.
	gl.Uniform1f(uniforms["aspect_ratio"].location, window_aspect_ratio)
}

draw_object :: proc(indices_count: i32) {
	gl.DepthFunc(gl.LESS)
	// TODO: figure out why this doesn't work with `gl.DrawArrays`
	gl.DrawElements(gl.TRIANGLES, indices_count, gl.UNSIGNED_SHORT, nil)
}

draw_points :: proc(indices: []u16) {
	gl.Enable(gl.PROGRAM_POINT_SIZE)
	gl.DrawElements(gl.POINTS, i32(len(indices)), gl.UNSIGNED_SHORT, nil)
}

draw_lines :: proc(indices_count: i32) {
	gl.DepthFunc(gl.LESS)
	gl.Enable(gl.LINE_SMOOTH)
	gl.LineWidth(1.)
	gl.DrawElements(gl.LINES, indices_count, gl.UNSIGNED_SHORT, nil)
}

draw_axes :: proc(indices_count: i32) {
	gl.DepthFunc(gl.LESS)
	gl.Enable(gl.LINE_SMOOTH)
	gl.LineWidth(1.)
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
	gl.DrawElements(gl.LINES, indices_count, gl.UNSIGNED_SHORT, nil)
}

get_buffer_objects :: proc() -> (vao: u32, vbo: u32, ebo: u32) {
	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)
	return
}

get_texture_id :: proc(pixels: []u32) -> (texture_id: u32) {
	gl.GenTextures(1, &texture_id)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		gl.RGBA,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		0,
		gl.BGRA,
		gl.UNSIGNED_BYTE,
		raw_data(pixels),
	)
	return
}

bind_data :: proc(vao: u32, vbo: u32, ebo: u32, data: []objects.Vertex, indices: []u16) {
	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(data) * size_of(objects.Vertex),
		raw_data(data),
		gl.STATIC_DRAW,
	)
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(
		0,
		3,
		gl.FLOAT,
		false,
		size_of(objects.Vertex),
		offset_of(objects.Vertex, position),
	)
	gl.VertexAttribPointer(
		1,
		4,
		gl.FLOAT,
		false,
		size_of(objects.Vertex),
		offset_of(objects.Vertex, color),
	)
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

