#+feature dynamic-literals

package main

import "core:fmt"
import "core:time"

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

calculate_weighted_avg_fps :: proc(times_per_frame: [dynamic]f64) -> (avg: f64) {
	total_fps: f64 = 0
	five_percent_initial_frames_idx := f32(len(times_per_frame)) * 0.05
	for time_per_frame, idx in times_per_frame {
		if idx < int(five_percent_initial_frames_idx) {continue}
		total_fps += 1 / time_per_frame
	}
	avg = total_fps / f64(len(times_per_frame))
	return
}

