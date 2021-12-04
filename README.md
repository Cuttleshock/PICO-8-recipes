# PICO-8 recipes

Large, modular chunks of code that are likely to be useful in multiple contexts.

## 3d.p8

Renders a cube in 3D, with buttons mapped to move around in 6 directions.

Unfortunately, trying to extend this to allow rotation OOM-kills the system, so it's not very useful as is. It may be that it needs to be extracted from the oo-base recipe, making it less nice to develop but more performant.

## make_atan_lookup.js

A utility that prints out a lookup table for arctan(x). Configurable by changing constants in the code.

## oo_base_3.p8

A 30-line setup to support object constructors and inheritance, with example usage. Based on the design used in [eev.ee's Pico-8 blog posts](https://eev.ee/blog/2021/01/26/gamedev-from-scratch-1-scaffolding/), with small tweaks (the number 3 indicates the iteration version).
