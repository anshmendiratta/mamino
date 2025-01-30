package animation

import gl "vendor:OpenGL"

import "../render"

foreign import stbiw "../lib/stb_image_write.a"

foreign stbiw {
	stbi_write_png :: proc(filename: cstring, w, h, comp: i32, data: rawptr, stride_in_bytes: i32) -> i32 ---
}

write_png :: #force_inline proc(
	filename: string,
	w, h, comp: int,
	data: rawptr,
	stride_in_bytes: int,
) -> int {
	return(
		cast(int)stbi_write_png(
			cstring("test_image.png"),
			i32(w),
			i32(h),
			i32(comp),
			data,
			i32(stride_in_bytes),
		) \
	)
}

get_framebuffer :: proc() -> (pixels: [render.WINDOW_WIDTH * render.WINDOW_HEIGHT]u32) {
	gl.ReadPixels(
		0,
		0,
		render.WINDOW_WIDTH,
		render.WINDOW_HEIGHT,
		gl.RGBA,
		gl.UNSIGNED_BYTE,
		raw_data(&pixels),
	)
	return
}

