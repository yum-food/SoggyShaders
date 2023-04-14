# Soggy Shaders

A collection of shaders by yum\_food.

MIT licensed: feel free to modify, redistribute, and sell!

To use, clone this repo somewhere inside your Unity assets folder.
Then assign the shader you want (like yum\_food/parallax) to a material.

Please ask setup questions [on the discord](https://discord.gg/YWmCvbCRyn).

## Parallax

![Parallax demo](Demos/parallax_demo.gif)

A simple parallax shader with three parallax planes. Each plane can be textured with PBR textures: base color, normal, metallic, and roughness. The size, depth,
and emission strength of each plane is configurable.

In these demos, I have the shader on a quad.

Full demo video [here](https://youtu.be/WvPdqxmrZzI).

## Displacement

![Displacement demo](Demos/displacement_demo.gif)

A simple displacement shader.

* Displacement height is specified with a texture.
* Height texture can be translated at configurable X/Y speeds, giving a
  flowy effect.
* Height can be masked to concentrate height mapping into specific areas.
* A built-in center-out effect is available.
* Basic physically-based shading is implemented (albedo with alpha, normal,
  roughness, metallic, cubemap).

In these demos, I have the shader on a 100x100 plane.

Full demo video [here](https://youtu.be/Giui4aCjtI0).

