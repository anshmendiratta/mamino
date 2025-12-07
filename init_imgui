#!/bin/bash
# Manual setup is annoying.
#
# DEPENDENCIES: [python3, python3-ply, sudo privileges, clang]

# Get repo and build.
git clone https://gitlab.com/L-4/odin-imgui
python3 build.py # Build all backends, even though some may be unnecessary.

# Create identical directory structure to README.md.
shared_dir=$(odin root)+"shared/" 
mkdir $(shared_dir)/dear_imgui
mkdir $(shared_dir)/dear_imgui/gl
mkdir $(shared_dir)/dear_imgui/glfw

cp *.a $(shared_dir)/dear_imgui # Static library.
cp *.odin $(shared_dir)/dear_imgui # Bindings.
cp imgui_impl_opengl3/*.odin $(shared_dir)/dear_imgui/gl # OpenGL.
cp imgui_impl_glfw/*.odin $(shared_dir)/dear_imgui/glfw # glfw.

# Cleanup.
sudo rm -r odin-imgui
