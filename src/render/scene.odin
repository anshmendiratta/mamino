package render

import gl "vendor:OpenGL"

import "../objects"

render_normals: bool = false
render_faces: bool = false

render_objects :: proc(render_objects: []union {
		objects.Cube,
	}) {
	vertices: []objects.Vertex
	defer delete(vertices)

	for generic_object in render_objects {
		#partial switch object in generic_object {
		case objects.Cube:
			// Do not need to worry about the constant coloring below, as the below call copies over from the base cube, whose color is unchanging.
			vertices = objects.get_vertices(object)
			// Cube.
			cube_vao, cube_vbo, cube_ebo := get_buffer_objects()
			bind_data(cube_vao, cube_vbo, cube_ebo, vertices, objects.cube_indices)
			draw_cube(vertices, i32(len(objects.cube_indices)))
			// Points.
			point_vao, point_vbo, point_ebo := get_buffer_objects()
			objects.color_vertices(vertices, objects.point_color)
			bind_data(point_vao, point_vbo, point_ebo, vertices, objects.point_indices)
			draw_points(vertices, objects.point_indices)
			// Lines.
			line_vao, line_vbo, line_ebo := get_buffer_objects()
			objects.color_vertices(vertices, objects.line_color)
			bind_data(line_vao, line_vbo, line_ebo, vertices, objects.line_indices)
			draw_lines(vertices, objects.line_indices)
			// FIX(Ansh): Normal rendering doesn't want to happen on debug mode. Probably to do with setting the PolygonMode.
			// Normals of faces.
			if ODIN_DEBUG && render_normals {
				normal_vao, normal_vbo, normal_ebo := get_buffer_objects()
				face_normals := objects.get_cube_normals_coordinates(object)
				bind_data(normal_vao, normal_vbo, normal_ebo, face_normals, {0, 1, 2, 3, 4, 5})
				draw_lines(face_normals, {0, 1, 2, 3, 4, 5})

				gl.DeleteVertexArrays(1, &normal_vao)
				gl.DeleteBuffers(1, &normal_vbo)
				gl.DeleteBuffers(1, &normal_ebo)
			}

			gl.DeleteVertexArrays(1, &cube_vao)
			gl.DeleteBuffers(1, &cube_vbo)
			gl.DeleteBuffers(1, &cube_ebo)
			gl.DeleteVertexArrays(1, &point_vao)
			gl.DeleteBuffers(1, &point_vbo)
			gl.DeleteBuffers(1, &point_ebo)
			gl.DeleteVertexArrays(1, &line_vao)
			gl.DeleteBuffers(1, &line_vbo)
			gl.DeleteBuffers(1, &line_ebo)
		case:
		}
	}
}

render_coordinate_axes :: proc() {
	axes_vao, axes_vbo, axes_ebo := get_buffer_objects()
	bind_data(
		axes_vao,
		axes_vbo,
		axes_ebo,
		objects.coordinate_axes_vertices,
		objects.coordinate_axes_indices,
	)
	draw_axes(objects.coordinate_axes_indices)
	// gl.DeleteVertexArrays(1, &axes_vao)
	// gl.DeleteBuffers(1, &axes_vbo)
	// gl.DeleteBuffers(1, &axes_ebo)
}

render_subgrid_axes :: proc() {
	subgrid_axes_vao, subgrid_axes_vbo, subgrid_axes_ebo := get_buffer_objects()
	bind_data(
		subgrid_axes_vao,
		subgrid_axes_vbo,
		subgrid_axes_ebo,
		objects.subgrid_axes_vertices,
		objects.subgrid_axes_indices,
	)
	draw_axes(objects.subgrid_axes_indices)
	// gl.DeleteVertexArrays(1, &subgrid_axes_vao)
	// gl.DeleteBuffers(1, &subgrid_axes_vbo)
	// gl.DeleteBuffers(1, &subgrid_axes_ebo)
}

