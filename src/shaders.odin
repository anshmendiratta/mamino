package main
 
vertex_shader := `
	#version 330 core

	layout(location = 0) in vec2 position;
	layout(location = 1) in vec4 color;
	out vec4 f_color;

	void main() {
		// float angle_dt = radians(45);
		// mat2 rotation_matrix = mat2(
		// 	cos(angle_dt), -sin(angle_dt),
		// 	sin(angle_dt), cos(angle_dt)
		// );
		gl_Position = vec4(position, 0.0, 1.0);
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
