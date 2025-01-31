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

delete_previous_frames :: proc() {
	if !os2.is_directory("frames") {
		return
	}

	allocator: runtime.Allocator
	frames_directory, open_ok := os.open("frames")
	directory_file_infos, read_ok := os.read_dir(frames_directory, -1)
	if read_ok != nil {
		fmt.eprintln("Error: could not open frames/ even though it exists.")
	}
	for file in directory_file_infos {
		os.remove(file.fullpath)
	}
}

make_frames_directory :: proc() {
	directory_name :: "frames"
	if os2.is_directory("frames") {
		return
	}

	ok := os.make_directory(directory_name)
	if ok != nil {
		fmt.eprintfln("Error: Could not make a frames/ directory. {}", ok)
	}
}

ffmpeg_composite_video :: proc(framerate: f64) -> os2.Error {
	if os.is_file_path("vid.mp4") {
		remove_ok := os.remove("vid.mp4")
		if remove_ok != nil {
			fmt.eprintln("Error: could not remove vid.mp4")
		}
	}
	os2.set_working_directory("~/development/mamino/")

	ffmpeg_framerate := fmt.aprintf("%d", int(framerate))
	process_description: os2.Process_Desc
	process_description.command = {
		"ffmpeg",
		"-hwaccel",
		"vulkan",
		"-framerate",
		ffmpeg_framerate,
		"-pattern_type",
		"glob",
		"-i",
		`frames/img_*.png`,
		"-init_hw_device",
		"vulkan=vk:0",
		"-c:v",
		"av1",
		// "libx264",
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

