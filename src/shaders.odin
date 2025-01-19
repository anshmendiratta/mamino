package main

vertex_shader := `
	#version 460

	layout(location = 0) in vec3 position;
	layout(location = 1) in vec4 color;
	out vec4 f_color;
	out vec3 v_coord;

	void main() {
		gl_Position = vec4(position, 1.0);
		v_coord = position;
		f_color = color;
	}
`


fragment_shader := `
	#version 460

	in vec3 v_coord;
	in vec4 f_color;
	out vec4 out_color;

	void main() {
		out_color = f_color;
	}
`
