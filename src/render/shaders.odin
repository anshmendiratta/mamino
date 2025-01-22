package render

vertex_shader := `
	#version 410

	layout(location = 0) in vec3 position;
	layout(location = 1) in vec4 color;
	out vec4 f_color;
	out vec3 v_coord;

	uniform mat4 v_transform;

	void main() {
		gl_Position = v_transform * vec4(position, 1.0);
		gl_PointSize = 20.;
		v_coord = position;
		f_color = color;
	}
`


fragment_shader := `
	#version 410

	in vec3 v_coord;
	in vec4 f_color;
	out vec4 out_color;

	void main() {
		out_color = f_color;
	}
`

