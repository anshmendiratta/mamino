# mamino
A [manim](https://www.manim.community/) inspired 3D renderer that supports coordinate based object animation in Odin.

## Why?
To explore and learn both [Odin](https://odin-lang.org/) and 3D rendering and coordinate animation techniques (like those employed by [manim](https://www.manim.community/)) more deeply.

This project may be rewritten in Vulkan in the future if deemed necesssary.

## Dependencies
- [glfw](https://www.glfw.org/)
- [OpenGL 4.1](https://www.opengl.org/)
- [ffmpeg](https://www.ffmpeg.org/) (for exporting videos)
- [imgui](https://github.com/ocornut/imgui) (for rendering the debugger)

`freetype` is imported from the `shared/` directory -- this is located in `ODIN_ROOT` (to find out where this is, you can use `odin root`). Place your files inside the `freetype/` directory after creating it, and things should just work. For this project, we used [odin-freetype](https://github.com/englerj/odin-freetype).

`imgui` is imported from the `shared/` directory. Odin has imgui binds in progress, but for the time being, we've used the ones generated using https://gitlab.com/L-4/odin-imgui. Place the base imgui files in `dear_imgui` inside `shared/` and create subfolders `gl/` and `glfw/` for the library specific imgui files. Don't forget to move your OS's static libraries too (such as `imgui_linux_x64.a`).

Example structure:
```
shared/
 dear_imgui/
    imgui.odin
    imconfig.odin
    imgui_internal.odin
    impl_enabled.odin
    imgui_linux_x64.a

    gl/
      imgui_impl_opengl3.odin    

    glfw/
      imgui_impl_glfw.odin
```
Of course, you may choose to edit the source of this library to match the structure of your `shared/`.

## Usage
Add the project files to Odin's `shared` or otherwise a place to import the library from. Next, fill in the blanks and guess a way to use this library.

Finally, execute `odin run` with no additional flags.

## Features
See [goals](#goals) for a more detailed list on current features.

### Goals

## Features
- [x] Render vertices as points (respecting z-index).
- [x] Render cubes using indexed drawing.
- [x] Camera rotation with spherical coordinates.
- [x] Render edges as lines (respecting z-index).
- [x] Add perspective to renders.
- [x] Move to MVP translation matrices in shader.
- [x] Render coordinate axes (color-coded and labelled).
- [x] Translate meshes w.r.t the origin.
- [x] Render face normals (respecting z-index).
- [x] "Capture" frames from OpenGL/GLFW and composite them into a video.
- [x] Add configuration for video export.
- [x] Add debug panel with scene information.
- [x] Add sphere.
- [ ] Add tiling textures on faces.
- [ ] Add translucency to select faces.
- [ ] "Spawn meshes" (and their spawn animation).
- [ ] Smooth camera movements.
- [x] Allow a sequence of animations/movements to be programmed and ran.
- [ ] Increase render and video resolution.
- [x] Add keyframe interpolation.
- [ ] Import models.

## Quality of Life
- [ ] Add "ambient occlusion" to mesh face colors to indicate orientation.
- [ ] Make drawing aspect-ratio-independent.
- [ ] Easing modes for animations.

## Documentation
- [x] Think about and clean-up public API.
- [ ] Add example mains.

## Performance
- [ ] Speed up frame extraction.
- [ ] Add concurrency.
- [ ] Reduce draw calls.
- [ ] Cache calculations (such as vertex calculations of spheres).
