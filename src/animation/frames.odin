package animation

import "core:fmt"
import "core:mem"
import "core:os"
import "core:os/os2"
import "core:slice"
import "core:strings"

import "base:runtime"

import gl "vendor:OpenGL"

import "../render"

foreign import stbiw "../../lib/stb_image_write.a"
foreign stbiw {
	stbi_write_png :: proc(filename: cstring, w, h, comp: i32, data: rawptr, stride_in_bytes: i32) -> i32 ---
	// stbi_write_png_flip :: proc(filename: string, w, h: int, $comp: int, data: []u8, stride_in_bytes: int) -> int ---
}

write_frames :: proc(frames: [dynamic][]u32) {
	for frame, idx in frames {
		// defer delete(frame)
		padded_frame_count := fmt.aprintf("%04d", idx)
		image_name := fmt.aprintf("frames/img_{}.png", padded_frame_count)
		success := write_png(
			image_name,
			render.WINDOW_WIDTH,
			render.WINDOW_HEIGHT,
			4,
			frame,
			render.WINDOW_WIDTH * 4,
		)
		if success != 1 {
			// Failure.
			fmt.eprintln("Error: could not write frame.")
		}
	}

	fmt.println("Wrote", len(frames), "frames.")
}

write_png :: #force_inline proc(
	filename: string,
	window_width, window_height, comp: i32,
	data: []u32,
	stride_in_bytes: i32,
) -> int {
	assert(comp >= 0 && comp <= 4)
	flipped_image: []u32 = make([]u32, len(data), context.temp_allocator)

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

// FIX: this PBO (Pixel Buffer Object) reading so the frames are not just black and white.
capture_frame :: proc(pixel_pbo: u32) -> (pixels: []u32) {
	gl.ReadBuffer(gl.FRONT)
	// Generate OpenGL buffers and bind them to the pack pixel buffer.
	gl.BindBuffer(gl.PIXEL_PACK_BUFFER, pixel_pbo)
	// Allocating the space.
	gl.BufferData(
		gl.PIXEL_PACK_BUFFER,
		int(render.WINDOW_WIDTH * render.WINDOW_HEIGHT * 4),
		nil,
		gl.STREAM_READ,
	)

	gl.BindBuffer(gl.PIXEL_PACK_BUFFER, pixel_pbo)
	gl.ReadPixels(0, 0, render.WINDOW_WIDTH, render.WINDOW_HEIGHT, gl.RGBA, gl.UNSIGNED_BYTE, nil)
	pbo_ptr := ([^]u32)(gl.MapBuffer(gl.PIXEL_PACK_BUFFER, gl.READ_ONLY))
	// defer free(pbo_ptr)
	if pbo_ptr != nil {
		pbo_pixels := pbo_ptr[:render.WINDOW_WIDTH * render.WINDOW_HEIGHT]
		pixels = make([]u32, len(pbo_pixels), context.temp_allocator)
		// pixels = slice.clone(pbo_pixels)
		copy(pixels, pbo_pixels)
	}
	// Removes the bind from our CPU pbo.
	unmap_success := gl.UnmapBuffer(gl.PIXEL_PACK_BUFFER)
	if !unmap_success {
		fmt.eprintln("frames.odin: Failed to unmap the PBO.")
	}
	gl.BindBuffer(gl.PIXEL_PACK_BUFFER, 0)
	// Waits for the Fence.
	gl.FenceSync(gl.SYNC_GPU_COMMANDS_COMPLETE, 0)

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

