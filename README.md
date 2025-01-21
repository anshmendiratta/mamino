# mamino
A manim inspired 3D renderer that supports coordinate based object animation in Odin.

## Why?
To explore and learn both [Odin](https://odin-lang.org/) and 3D rendering and coordinate animation techniques (like those employed by [manim](https://www.manim.community/)) more deeply.

## Dependencies
- glfw

## Goals
- [x] Render vertices as points (respecting z-index)
- [x] Render cubes using indexed drawing
- [ ] Move to MVP translation matrices in shader
- [x] Camera rotation with spherical coordinates
- [ ] Render edges as lines (respecting z-index)
- [ ] Render coordinate axes
- [ ] Add perspective to renders
- [ ] Add tiling textures on faces
- [ ] Add translucency to select faces
- [ ] Translate meshes w.r.t the origin
- [ ] Add "ambient occlusion" to mesh face colors to indicate orientation
- [ ] Render face normals (respecting z-index)
- [ ] "Spawn meshes" (and their spawn animation)
- [ ] Add debug panel with scene information
