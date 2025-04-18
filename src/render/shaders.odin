package render

mamino_vertex_shader := `
	#version 410 core

	layout(location = 0) in vec3 position;
	layout(location = 1) in vec4 color;
	out vec4 f_color;
	out vec3 v_coord;

	uniform float aspect_ratio;
	uniform mat4 proj;
	uniform mat4 view;
	uniform mat4 model;

	void main() {
		mat4 v_transform = proj * view * model;
		gl_Position = v_transform * vec4(position, 1.0);
		gl_PointSize = 10.;
		gl_Position.x /= aspect_ratio;

		f_color = color;
		v_coord = position;
	}
`


mamino_fragment_shader := `
	#version 410 core

	in vec3 v_coord;
	in vec4 f_color;
	out vec4 out_color;

	void main() {
		out_color = f_color;
	}
`

