# mamino
A manim inspired 3D renderer that supports coordinate based object animation in Odin.

## Why?
To explore and learn both [Odin](https://odin-lang.org/) and 3D rendering and coordinate animation techniques (like those employed by [manim](https://www.manim.community/)) more deeply.

## Dependencies
- glfw
- OpenGL 4.1
- freetype

`freetype` is imported from the `shared/` directory -- this is located in `ODIN_ROOT` (to find out where this is, you can use `odin root`). Place your files inside the `freetype/` directory after creating it, and things should just work. For this project, we used [odin-freetype](https://github.com/englerj/odin-freetype).

## Goals
- [x] Render vertices as points (respecting z-index)
- [x] Render cubes using indexed drawing
- [x] Camera rotation with spherical coordinates
- [x] Render edges as lines (respecting z-index)
- [x] Add perspective to renders
- [x] Move to MVP translation matrices in shader
- [x] Render coordinate axes (color-coded and labelled)
- [x] Translate meshes w.r.t the origin
- [x] Render face normals (respecting z-index)
- [ ] Add tiling textures on faces
- [ ] Add translucency to select faces
- [ ] Add "ambient occlusion" to mesh face colors to indicate orientation
- [ ] "Spawn meshes" (and their spawn animation)
- [ ] Add debug panel with scene information
- [ ] Smooth camera movements
- [ ] Allow a sequence of animations/movements to be programmed and ran
- [ ] "Capture" frames from OpenGL/GLFW and composite them into a video
