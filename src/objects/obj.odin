#+feature dynamic-literals

package objects

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:os/os2"
import "core:strings"

import tobj "shared:tinyobj"

load_obj_model :: proc(file_path: string) -> (models: tobj.OBJ) {
	model_string_buf, ok := os2.read_entire_file_from_path(file_path, context.allocator)
	// TODO: Not sure if comparison to ERROR_NONE should be made. Look for cleaner / more idiomatic alternatives.
	if ok != os2.ERROR_NONE {
		fmt.printfln("MODEL: could not read bytes from {}", file_path)
	}
	model_string_data, err := strings.clone_from_bytes(model_string_buf)
	models = tobj.parse_obj(model_string_data)
	if !models.success {
		fmt.printfln("MODEL: could not load {}", file_path)
	}

	return
}

load_model_data :: proc(
	models: tobj.OBJ,
	color: uint = 0xaa_aa_aa,
) -> (
	vertices: [dynamic]Vertex,
	indices: [dynamic]u16,
) {
	model_vertices := models.attrib.vertices
	for i in 0 ..< len(models.attrib.vertices) / 3 {
		position := glm.vec3 {
			model_vertices[3 * i],
			model_vertices[3 * i + 1],
			model_vertices[3 * i + 2],
		}
		append(&vertices, Vertex{position, rgb_hex_to_color(color)})
	}
	for face in models.attrib.faces {
		append(&indices, u16(face.v_idx))
	}

	return
}

