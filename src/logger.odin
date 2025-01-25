#+feature dynamic-literals

package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:time"

import gl "vendor:OpenGL"

import ft "shared:freetype"

import "render"

Logger :: struct {
	times_per_frame: [dynamic]f64,
}

calculate_avg_fps :: proc(times_per_frame: [dynamic]f64) -> (avg: f64) {
	total_fps: f64 = 0
	for time_per_frame in times_per_frame {
		total_fps += 1 / time_per_frame
	}
	avg = total_fps / f64(len(times_per_frame))
	return
}

logger_font_init :: proc() -> (ft_library: ft.Library, ft_face: ft.Face) {
	FONT_FILE_NAME :: "assets/HackNerdFont-Regular.ttf"
	ft_ok := ft.init_free_type(&ft_library)
	if ft_ok != .Ok {
		fmt.println("Logging: Could not init ft.")
		return
	}
	ft_ok = ft.new_face(ft_library, FONT_FILE_NAME, 0, &ft_face)
	if ft_ok != .Ok {
		fmt.println("Logging: Could not init font file.")
		return
	}

	return
}

Character :: struct {
	texture_id: u32,
	size:       glm.ivec2,
	bearing:    glm.ivec2,
	advance:    u32,
}

logger_create_characters :: proc(
	ft_library: ft.Library,
	ft_face: ft.Face,
	text: string,
) -> (
	characters: map[rune]Character,
) {
	ft.set_pixel_sizes(ft_face, 0, 48)
	gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1) // disable byte-alignment restriction

	ft_load_flags: ft.Load_Flags

	for r in text {
		ft_ok := ft.load_char(ft_face, u64(r), ft_load_flags)
		if ft_ok != .Ok {
			fmt.println("Logger: Could not load char:", r)
		}

		texture: u32
		gl.GenTextures(1, &texture)
		gl.BindTexture(gl.TEXTURE_2D, texture)
		gl.TexImage2D(
			gl.TEXTURE_2D,
			0,
			gl.RED,
			i32(ft_face.glyph.bitmap.width),
			i32(ft_face.glyph.bitmap.rows),
			0,
			gl.RED,
			gl.UNSIGNED_BYTE,
			ft_face.glyph.bitmap.buffer,
		)

		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)

		character: Character = {
			texture,
			glm.ivec2{i32(ft_face.glyph.bitmap.width), i32(ft_face.glyph.bitmap.rows)},
			glm.ivec2{i32(ft_face.glyph.bitmap.width), i32(ft_face.glyph.bitmap.rows)},
			u32(ft_face.glyph.advance.x),
		}

		characters[r] = character
	}
	gl.BindTexture(gl.TEXTURE_2D, 0)
	ft.done_face(ft_face)
	ft.done_free_type(ft_library)

	return
}

TextRenderInfo :: struct {
	x:     f32,
	y:     f32,
	scale: f32,
	color: glm.vec3,
}

logger_render_text :: proc(
	uniforms: map[string]gl.Uniform_Info,
	characters: map[rune]Character,
	vao: u32,
	vbo: u32,
	text_render_info: ^TextRenderInfo,
) -> Maybe(u32) {
	text_transformation := glm.mat4Ortho3d(
		0.,
		render.WINDOW_WIDTH,
		0.,
		render.WINDOW_HEIGHT,
		0.1,
		100.,
	)
	gl.UniformMatrix4fv(uniforms["text_transform"].location, 1, false, &text_transformation[0, 0])

	program, ok := gl.load_shaders_source(render.text_vertex_shader, render.text_fragment_shader)
	if !ok {
		fmt.eprintln("Could not load shaders.")
		return program
	}
	gl.UseProgram(program)
	gl.VertexAttribPointer(0, 4, gl.FLOAT, false, size_of(f32), 0.)

	gl.Uniform3f(
		gl.GetUniformLocation(program, "text_color"),
		text_render_info.color.x,
		text_render_info.color.y,
		text_render_info.color.z,
	)
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindVertexArray(vao)

	for r, char in characters {
		x_pos: f32 = text_render_info.x + f32(char.bearing.x) * text_render_info.scale
		y_pos: f32 =
			text_render_info.y - f32(char.size.y - char.bearing.y) * text_render_info.scale

		w: f32 = f32(char.size.x) * text_render_info.scale
		h: f32 = f32(char.size.y) * text_render_info.scale

		vertices: []glm.vec4 = {
			{x_pos, y_pos + h, 0., 0.},
			{x_pos, y_pos, 0., 1.},
			{x_pos + w, y_pos + h, 1., 1.},
			{x_pos, y_pos + h, 0., 0.},
			{x_pos + w, y_pos, 1., 1.},
			{x_pos + w, y_pos + h, 1., 0.},
		}

		gl.BindTexture(gl.TEXTURE_2D, char.texture_id)
		gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
		gl.BufferSubData(gl.ARRAY_BUFFER, 0, size_of(vertices), raw_data(vertices))
		gl.BindBuffer(gl.ARRAY_BUFFER, 0)
		gl.DrawArrays(gl.TRIANGLES, 0, 6)

		text_render_info.x += f32(char.advance >> 6) * text_render_info.scale
	}

	gl.BindVertexArray(0)
	gl.BindTexture(gl.TEXTURE_2D, 0)

	return program
}

