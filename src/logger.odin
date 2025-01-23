#+feature dynamic-literals

package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:time"

import gl "vendor:OpenGL"

import ft "shared:freetype"

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
	FONT_FILE_NAME :: "HackNerdFont-Regular.ttf"
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

	ft.set_pixel_sizes(ft_face, 0, 48)
	gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1) // disable byte-alignment restriction

	return
}

Character :: struct {
	texture_id: u32,
	size:       glm.ivec2,
	bearing:    glm.ivec2,
	advance:    u32,
}

characters: map[rune]Character

logger_render_font :: proc(ft_library: ft.Library, ft_face: ft.Face) {
	ft_load_flags: ft.Load_Flags
	ft_error := ft.load_char(ft_face, 'X', ft_load_flags)
	assert(ft_error == .Ok)
	ft_error = ft.render_glyph(ft_face.glyph, .Normal)
	assert(ft_error == .Ok)

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
	characters['X'] = character

	ft.done_face(ft_face)
	ft.done_free_type(ft_library)
}

logger_render :: proc() {

}

