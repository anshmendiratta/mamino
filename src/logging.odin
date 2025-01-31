#+feature dynamic-literals

package main

import "core:fmt"
import "core:time"

Logger :: struct {
	times_per_frame: [dynamic]f64,
}

calculate_avg_fps :: proc(times_per_frame: [dynamic]f64) -> (avg: f64) {
	total_fps: f64 = 0
	// Ignore the first 5% of frames since they are usually inflated.
	five_percent_initial_frames_idx := len(times_per_frame) / 20
	for time_per_frame, idx in times_per_frame {
		if idx < five_percent_initial_frames_idx {continue}
		total_fps += 1 / time_per_frame
	}
	avg = total_fps / f64(len(times_per_frame))
	return
}

