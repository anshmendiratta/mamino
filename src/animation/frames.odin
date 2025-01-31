package animation

import "core:fmt"
import "core:os"
import "core:os/os2"

import "base:runtime"

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

make_frames_directory :: proc() {
	directory_name :: "frames"
	ok := os.make_directory(directory_name)
	if ok != nil {
		fmt.printfln("Error: Could not make a frames/ directory. {}", ok)
	}
}

ffmpeg_composite_video :: proc() -> os2.Error {
	os2.set_working_directory("~/development/mamino/")
	process_description: os2.Process_Desc
	process_description.command = {
		"ffmpeg",
		"-framerate",
		"30",
		"-pattern_type",
		"glob",
		"-i",
		`frames/img_*.png`,
		"-c:v",
		"libx264",
		"vid.mp4",
	}
	allocator: runtime.Allocator
	process_state, stdout, stderr, ok := os2.process_exec(process_description, allocator)
	if !process_state.success {
		fmt.printfln("Error: could not run ffmpeg. {}", ok)
		fmt.printfln("stderr of command: {}", string(stderr))
	}
	fmt.println(#directory)

	return ok
}

