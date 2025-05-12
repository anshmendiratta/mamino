#+feature dynamic-literals

package objects

import "core:fmt"
import "core:os"
import "core:strings"

import "vendor:cgltf"


Model :: struct {
	// Generic object data.
	id:               ObjectID,
	file_path:        string,
	keyframes:        [dynamic]ModelKeyFrame,
	current_keyframe: uint,
	color:            int "Hex code",
}

import_model :: proc(gltf_file_path: string) -> (data: ^cgltf.data) {
	options: cgltf.options
	options.type = cgltf.file_type.gltf

	data_, result := cgltf.parse_file(
		options = options,
		path = strings.clone_to_cstring(gltf_file_path),
	)
	if result != cgltf.result.success {
		fmt.eprintln("Could not import model with path:", gltf_file_path)
	}

	data = data_
	return
}

get_model_vertices :: proc(
	gltf_data: ^cgltf.data,
	gltf_file_path: string,
	binary_file_path: string,
	accessor_idx: uint,
) -> (
	vertices: [dynamic]Vertex,
) {
	bin_file_contents, ok := os.read_entire_file_from_filename(name = binary_file_path)
	if !ok {
		fmt.eprintln("Could not read model binary file with path:", binary_file_path)
	}

	byte_offset := gltf_data.accessors[accessor_idx].offset
	byte_stride := gltf_data.accessors[accessor_idx].stride
	bytes_count := gltf_data.accessors[accessor_idx].count

	vertex_buffer_count := cgltf.accessor_unpack_floats(
		&gltf_data.accessors[accessor_idx],
		nil,
		bytes_count / 2,
	)
	vertices_: [^]f32 = make([^]f32, vertex_buffer_count)
	defer free(vertices_)

	for &vertex in vertices_[:vertex_buffer_count] {
		append(&vertices, Vertex{position = vertex})
	}

	return
}

