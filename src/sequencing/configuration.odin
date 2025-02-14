package sequencing

import "core:slice"
import "core:strings"

VALID_ENCODINGS: []string : {"av1", "libx264", "libx265"}
VALID_OUT_FORMATS: []string : {".mp4", ".mov", ".mkv"}

VideoOptions :: struct {
	resolution: []u32,
	framerate:  int,
	encoding:   string,
	out_name:   string,
}

validate_video_options :: proc(vo: VideoOptions) -> (valid: bool) {
	valid_framerate := vo.framerate > 0
	_, valid_encoding := slice.linear_search(VALID_ENCODINGS, vo.encoding)
	out_name_point_index := strings.index(vo.out_name, ".")
	_, valid_out_name := slice.linear_search(VALID_OUT_FORMATS, vo.out_name[out_name_point_index:])
	valid = valid_framerate && valid_encoding && valid_out_name

	return
}

