package render

@(private = "file")
MaminoConfigurationEnum :: enum {
	enable_debugger,
	export_video,
	render_axes,
	render_axes_subgrid,
}

MaminoConfiguration :: bit_set[MaminoConfigurationEnum]

mamino_configuration: MaminoConfiguration

