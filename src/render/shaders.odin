package render

mamino_vertex_shader := `
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


mamino_fragment_shader := `
	#version 410

	in vec2 tex_coords;
	in vec3 v_coord;
	in vec4 f_color;
	out vec4 out_color;

	uniform sampler2D text;
	uniform vec3 text_color;

	void main() {
		out_color = f_color;
	}
`


text_vertex_shader := `
	#version 410

	layout(location = 0) in vec4 glyph_data;
	out vec2 tex_coords;

	uniform mat4 text_transform;

	void main() {
		tex_coords = glyph_data.zw;
		gl_Position = text_transform * vec4(glyph_data.xy, 0., 1.0);
	}
`


text_fragment_shader := `
	#version 410

	in vec2 tex_coords;
	out vec4 out_color;

	uniform sampler2D text;
	uniform vec3 text_color;

	void main() {
		vec4 sampled_tex = vec4(1., 1., 1., texture(text, tex_coords).r);
		out_color = vec4(text_color, 1.) * sampled_tex;
	}
`

