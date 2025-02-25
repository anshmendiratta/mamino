package render

mamino_vertex_shader := `
	#version 410 core

	layout(location = 0) in vec3 position;
	layout(location = 1) in vec4 color;
	layout(location = 2) in vec2 tex_coord;
	out vec4 f_color;
	out vec3 v_coord;
	out vec2 t_coord;

	uniform mat4 proj;
	uniform mat4 view;
	uniform mat4 model;

	void main() {
		mat4 v_transform = proj * view * model;
		gl_Position = v_transform * vec4(position, 1.0);
		gl_PointSize = 20.;

		f_color = color;
		v_coord = position;
		t_coord = tex_coord;
	}
`


mamino_fragment_shader := `
	#version 410 core

	in vec3 v_coord;
	in vec4 f_color;
	in vec2 t_coord;
	out vec4 out_color;

	uniform sampler2D tex_sampler;
	
	void main() {
		// out_color = f_color;
		out_color = texture(tex_sampler, t_coord);
	}
`

