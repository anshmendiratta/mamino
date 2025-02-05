package animation

import "core:fmt"
import "core:mem"
import "core:os"
import "core:os/os2"
import "core:strings"

import "base:runtime"

import gl "vendor:OpenGL"

import "../render"

foreign import stbiw "../../lib/stb_image_write.a"
foreign stbiw {
	stbi_write_png :: proc(filename: cstring, w, h, comp: i32, data: rawptr, stride_in_bytes: i32) -> i32 ---
	// stbi_write_png_flip :: proc(filename: string, w, h: int, $comp: int, data: []u8, stride_in_bytes: int) -> int ---
}

write_png :: #force_inline proc(
	filename: string,
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
			strings.clone_to_cstring(filename),
			window_width,
			window_height,
			comp,
			raw_data(flipped_image),
			stride_in_bytes,
		),
	)
}

capture_frame :: proc(current_pbo_idx: int) -> (pixels: []u32) {
	pixels = make([]u32, render.WINDOW_WIDTH * render.WINDOW_HEIGHT)
	// Read displayed/front buffer.
	gl.ReadBuffer(gl.FRONT)

	/* TODO: Fix this PBO (Pixel Buffer Object) reading so the frames are not just black and white.
		// Generate OpenGL buffers and bind them to the pack pixel buffer.
		// pixels_pbos: [2]u32
		// gl.GenBuffers(1, &pixels_pbos[0])
		// gl.GenBuffers(1, &pixels_pbos[1])
		// defer gl.DeleteBuffers(1, &pixels_pbos[0])
		// defer gl.DeleteBuffers(1, &pixels_pbos[1])
		// gl.BindBuffer(gl.PIXEL_PACK_BUFFER, pixels_pbos[current_pbo_idx])
		// Should return immediately.
	*/

	gl.ReadPixels(
		0,
		0,
		render.WINDOW_WIDTH,
		render.WINDOW_HEIGHT,
		gl.RGBA,
		gl.UNSIGNED_BYTE,
		raw_data(pixels),
	)

	/* PBO Continued: 
		// Binds and copies data from the pack pixel buffer to our CPU buffer.
		// other_pbo_idx := 1 - current_pbo_idx
		// gl.BindBuffer(gl.PIXEL_PACK_BUFFER, pixels_pbos[other_pbo_idx])
		// read_pixels_ptr := gl.MapBuffer(gl.PIXEL_PACK_BUFFER, gl.READ_ONLY)
		// if read_pixels_ptr != nil {
		// 	// Success.
		// 	pixels = read_pixels_ptr
		// 	gl.UnmapBuffer(gl.PIXEL_PACK_BUFFER)
		// }
		// // Removes the bind from our CPU pbo.
		// gl.BindBuffer(gl.PIXEL_PACK_BUFFER, 0)
	*/

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
		// Hardware acceleration if available.
		"-hwaccel",
		"vaapi",
		"-hwaccel_output_format",
		"vulkan",
		"-init_hw_device",
		"vulkan=vk:0",
		// ffmpeg settings.
		"-framerate",
		ffmpeg_framerate,
		"-pattern_type",
		"glob",
		"-i",
		`frames/img_*.png`,
		"-c:v",
		// "av1",
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

