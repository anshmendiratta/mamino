package main

@(private = "file")
MaminoConfigurationEnum :: enum {
	enable_debugger,
	export_video,
}

MaminoConfiguration :: bit_set[MaminoConfigurationEnum]

