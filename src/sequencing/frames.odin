package sequencing

import "core:fmt"
import "core:mem"
import "core:os"
import "core:os/os2"
import "core:slice"
import "core:strings"

import "base:runtime"

import gl "vendor:OpenGL"
import stbi "vendor:stb/image"

import "../render"

@(private)
pixels_pbos: [2]u32 = {0, 0}
@(private)
current_pbo_idx: u32 = 0
@(private)
frame_data := make([]u32, render.WINDOW_WIDTH * render.WINDOW_HEIGHT)
@(private)
stored_frames: [dynamic][]u32 = {}

@(cold)
mamino_frame_capture_init :: proc() {
	gl.GenBuffers(1, &pixels_pbos[0])
	gl.GenBuffers(1, &pixels_pbos[1])

	delete_previous_frames()
	make_directory("frames")
}

@(optimization_mode = "favor_size")
mamino_capture_frame :: proc() {
	frame_data = capture_frame(current_pbo_idx)
	frame_copy := slice.clone(frame_data)
	defer delete(frame_data)
	append(&stored_frames, frame_copy)
	current_pbo_idx = current_pbo_idx ~ 1
}

@(cold)
mamino_exit :: proc(vo: Maybe(VideoOptions) = nil) {
	// Cleanup.
	gl.DeleteBuffers(1, &pixels_pbos[0])
	gl.DeleteBuffers(1, &pixels_pbos[1])

	if vo == nil {
		return
	}
	vo := vo.?
	write_frames(stored_frames) // Do video export.
	composite_video(vo)
}

@(private)
@(cold)
@(optimization_mode = "favor_size")
write_frames :: proc(
	frames: [dynamic][]u32,
	window_width: i32 = render.WINDOW_WIDTH,
	window_height: i32 = render.WINDOW_HEIGHT,
) {
	for frame, idx in frames {
		padded_frame_count := fmt.aprintf("%04d", idx)
		image_name := fmt.aprintf("frames/img_{}.png", padded_frame_count)
		success := write_png(image_name, window_width, window_height, 4, frame, window_width * 4)
		if success != 1 {
			// Failure.
			fmt.eprintln("Error: could not write frame.")
		}
	}

	fmt.println("Wrote", len(frames), "frames.")
}

@(private)
@(optimization_mode = "favor_size")
write_png :: #force_inline proc(
	filename: string,
	window_width, window_height, comp: i32,
	data: []u32,
	stride_in_bytes: i32,
) -> int {
	assert(comp >= 0 && comp <= 4)
	flipped_image: []u32 = make([]u32, len(data))

	for row in 0 ..< window_height {
		for column in 0 ..< window_width {
			flipped_row := window_height - row - 1
			flipped_image[flipped_row * window_width + column] = data[row * window_width + column]
		}
	}

	return int(
		stbi.write_png(
			strings.clone_to_cstring(filename),
			window_width,
			window_height,
			comp,
			raw_data(flipped_image),
			stride_in_bytes,
		),
	)
}

@(private)
@(optimization_mode = "favor_size")
capture_frame :: proc(
	current_pbo_idx: u32,
	allocator: runtime.Allocator = context.allocator,
) -> (
	pixels: []u32,
) {
	gl.ReadBuffer(gl.FRONT)
	// Generate OpenGL buffers and bind them to the pack pixel buffer.
	gl.BindBuffer(gl.PIXEL_PACK_BUFFER, pixels_pbos[current_pbo_idx])
	// Allocating the space.
	gl.BufferData(
		gl.PIXEL_PACK_BUFFER,
		int(render.WINDOW_WIDTH * render.WINDOW_HEIGHT * 4),
		nil,
		gl.STREAM_READ,
	)

	gl.BindBuffer(gl.PIXEL_PACK_BUFFER, pixels_pbos[current_pbo_idx])
	gl.ReadPixels(0, 0, render.WINDOW_WIDTH, render.WINDOW_HEIGHT, gl.RGBA, gl.UNSIGNED_BYTE, nil)
	pbo_ptr := ([^]u32)(gl.MapBuffer(gl.PIXEL_PACK_BUFFER, gl.READ_ONLY))
	if pbo_ptr != nil {
		pbo_pixels := pbo_ptr[:render.WINDOW_WIDTH * render.WINDOW_HEIGHT]
		pixels = make([]u32, len(pbo_pixels), context.allocator)
		// pixels = new_clone(pbo_pixels)
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

@(cold)
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

@(private)
make_directory :: proc(dir_name: string = "frames") {
	if os2.is_directory(dir_name) {
		return
	}

	ok := os.make_directory(dir_name)
	if ok != nil {
		fmt.eprintfln("Error: Could not make a", dir_name, " directory. {}", ok)
	}
}

@(private)
@(cold)
composite_video :: proc(vo: VideoOptions, dir_name: string = "outputs") {
	ok: union {
		os2.Error,
		os.Error,
	}

	make_directory(dir_name)
	os2.set_working_directory(fmt.aprintf("~/development/mamino/{}/", dir_name))
	if os.is_file_path(vo.out_name) {
		remove_ok := os.remove(vo.out_name)
		if remove_ok != nil {
			fmt.eprintln("Error: could not remove", vo.out_name)
			ok = remove_ok
		}
	}

	framerate := fmt.aprintf("%d", vo.framerate)
	process_description: os2.Process_Desc
	// Hardware acceleration if available. Not on macOS.
	ffmpeg_hw_accel: []string = {
		"-hwaccel",
		"vaapi",
		"-hwaccel_output_format",
		"vulkan",
		"-init_hw_device",
		"vulkan=vk:0",
	}
	// Ffmpeg settings.
	ffmpeg_video_args: []string = {
		"-framerate",
		framerate,
		"-pattern_type",
		"glob",
		"-i",
		`frames/img_*.png`,
		"-c:v",
		vo.encoding,
		vo.out_name,
	}
	when ODIN_OS == .Darwin {
		args_to_concat: [][]string = {{"ffmpeg"}, ffmpeg_video_args}
		process_description.command = slice.concatenate(args_to_concat)
	} else {
		args_to_concat: [][]string = {{"ffmpeg"}, ffmpeg_hw_accel, ffmpeg_video_args}
		process_description.command = slice.concatenate(args_to_concat)
	}

	allocator: runtime.Allocator
	process_state, _, stderr, process_ok := os2.process_exec(process_description, allocator)
	if !process_state.success {
		fmt.printfln("Error: could not run ffmpeg. {}", process_ok)
		fmt.printfln("stderr of command: {}", string(stderr))
		ok = process_ok
	}

	if ok != nil {
		fmt.eprintln(ok)
		return
	}

	fmt.println(fmt.aprintf("Wrote file in {}/", dir_name))
}

