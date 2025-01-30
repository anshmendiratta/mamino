package animation

import "core:fmt"

import gl "vendor:OpenGL"

import "../render"

foreign import stbiw "../../lib/stb_image_write.a"
foreign stbiw {
	stbi_write_png :: proc(filename: cstring, w, h, comp: i32, data: rawptr, stride_in_bytes: i32) -> i32 ---
}

write_png :: #force_inline proc(
	filename: cstring,
	window_width, window_height, comp: i32,
	data: []u32,
	stride_in_bytes: i32,
) -> int {
	assert(comp >= 0 && comp <= 4)
	flipped_image: []u32 = make([]u32, len(data))
	defer delete(flipped_image)

	for row in 0 ..< window_height {
		for column in 0 ..< window_width {
			flipped_row := window_height - row - 1
			flipped_image[flipped_row * window_width + column] = data[row * window_width + column]
		}
	}

	return int(
		stbi_write_png(
			filename,
			window_width,
			window_height,
			comp,
			raw_data(flipped_image),
			stride_in_bytes,
		),
	)
}

get_framebuffer :: proc() -> (pixels: []u32) {
	pixels = make([]u32, render.WINDOW_WIDTH * render.WINDOW_HEIGHT)
	gl.ReadPixels(
		0,
		0,
		render.WINDOW_WIDTH,
		render.WINDOW_HEIGHT,
		gl.RGBA,
		gl.UNSIGNED_BYTE,
		raw_data(pixels),
	)

	return
}

