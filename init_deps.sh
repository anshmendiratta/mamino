#!/bin/bash
# Manual `shared/` setup is annoying.
#
# DEPENDENCIES: [python3, python3-ply, sudo privileges, clang, git]

# Get repositories and build if necessary.
git clone https://gitlab.com/L-4/odin-imgui.git
git clone https://github.com/algo-boyz/tinyobj.git

python3 odin-imgui/build.py # Build all ImGui backends, even though some may be unnecessary.

# Create identical directory structure to README.md.
shared_dir=$(odin root)"shared/" 
mkdir $(shared_dir)/dear_imgui
mkdir $(shared_dir)/dear_imgui/gl
mkdir $(shared_dir)/dear_imgui/glfw
mkdir $(shared_dir)/tinyobj

# Copy files.
# ImGui.
cp odin-imgui/*.a $(shared_dir)/dear_imgui # Static library.
cp odin-imgui/*.odin $(shared_dir)/dear_imgui # Bindings.
cp odin-imgui/imgui_impl_opengl3/*.odin $(shared_dir)/dear_imgui/gl # OpenGL.
cp odin-imgui/imgui_impl_glfw/*.odin $(shared_dir)/dear_imgui/glfw # glfw.
cp tinyobj/*.odin $(shared_dir)/tinyobj/ # tinyobj.
cp tinyobj/tinyobj_{loader.odin,memory.odin} $(shared_dir)/tinyobj/ # tinyobj.

# Cleanup.
sudo rm -r odin-imgui
sudo rm -r tinyobj

