package main

vertex_shader := `
	#version 330 core

	layout(location = 0) in vec4 position;
	layout(location = 1) in vec4 color;
	out vec4 f_color;

	void main() {
		gl_Position = position;
		// gl_PointSize = 10.0;
		f_color = color;
	}
`


fragment_shader := `
	#version 330 core

	in vec4 f_color;

	void main() {
		gl_FragColor = f_color;
	}
`
