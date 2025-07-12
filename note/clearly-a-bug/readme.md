# Clearly a Bug

https://www.shadertoy.com/view/33cGDj

This shader creates an **infinitely deepening animation** using a clever combination of **ray marching**, **domain repetition**, **fractal transformations**, and **time-based motion** — all wrapped up in what began as a *bug*. Let's break down how the illusion of infinite depth and animation emerges:

### 🌀 1. **Raymarching Through 3D Space**

Each pixel casts a 3D ray (`vec3(C - 0.5 * r, r.y)`) into a virtual space. The shader "walks" forward along that ray in steps (`z += .6 * d`) until it finds something (a surface), computing lighting/color as it goes.

* `z` is the depth along the ray.
* The loop goes for `77` steps max.
* The stepping size is tied to `d` (distance to surface), so it speeds up when far away and slows near geometry — this is **sphere tracing**.

### 🔁 2. **Infinite Repetition (Tiling the Universe)**

```glsl
p = abs(fract(p) - .5);
```

This line makes the space **repeat infinitely** in all directions, like mirrored tiles:

* `fract(p)` keeps the fractional part of the position, effectively wrapping it to a `[0, 1)` cube.
* Subtracting `0.5` recenters it to `[-0.5, 0.5)`.
* `abs()` folds the space across its center.

🔁 **Result**: Every object is **copied infinitely**, creating an endless, recursive-looking world.

### 🔄 3. **Recursive / Fractal Transformations**

```glsl
p.xy *= mat2(cos(2. + O.z + vec4(0, 11, 33, 0)));
p.xy *= mat2(cos(O + vec4(0, 11, 33, 0)));
```

These lines rotate and distort the space **over time**, depending on the current position `O` and time (`O.z`). One of these lines was apparently a bug, but it created chaotic complexity reminiscent of fractals.

* Using cosine to rotate based on position + time makes the shapes **shift, twist, and fold** as the camera moves forward.
* These transforms are nonlinear and **stack**, increasing the feeling of complexity the deeper the ray goes.

### 🧠 4. **Motion Through the World**

```glsl
p.z += iTime;
```

This line shifts the scene along the z-axis over time, simulating **camera forward motion** into the endless fractal world.

🔄 The result is that every frame moves deeper into the recursive, infinitely tiled, dynamically shifting universe.

### 🎨 5. **Color Based on Depth and Distortion**

```glsl
O = (1. + sin(...)) / (... + dot(...));
```

This line:

* Adds color variation using sine waves over distance and depth.
* Uses `dot()` to create a falloff — colors dim farther from the origin.
* Lighting is added more strongly when the ray is close to a surface (`1/d`).

### 🌌 6. **Final Glow and Tone Mapping**

```glsl
O = tanh(o / 2e4);
```

This final step:

* Accumulates light contributions from all steps.
* Compresses brightness with `tanh`, producing an HDR glow effect.

### 🔮 Summary: Why It Feels "Infinitely Deep"

1. **Raymarching** lets us trace complex 3D shapes with precise surface detection.
2. **Domain repetition** makes the world wrap endlessly.
3. **Dynamic fractal-like transforms** cause complexity to increase with depth.
4. **Camera motion** (via `p.z += iTime`) creates an illusion of diving deeper.
5. **Color, glow, and light falloff** reinforce spatial cues.
6. The unintended **matrix bug** adds chaotic layers that deepen the recursive feel.

### 🔧 Happy Accident

That “bug” in the matrix application (`p.xy *= mat2(cos(O + vec4(...)))`) unintentionally created **nonlinear, recursive-like distortion** of space. Instead of clean geometry, you get a chaotic unfolding — which **mimics fractal depth**, making the animation look like it's falling endlessly into itself.
