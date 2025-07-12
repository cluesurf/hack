# Phantom Star

https://www.shadertoy.com/view/ttKGDt

This shader creates a **dynamic, glowing field of recursive boxes** that rotate and pulse in space as time flows. The visual impression is something like floating crystals or sci-fi glyphs, arranged in symmetrical patterns and softly fading as they extend into the distance.

### key techniques at a glance

| Feature           | Technique                                                    |
| ----------------- | ------------------------------------------------------------ |
| Shape             | Repeated boxes with recursive folding (`abs(p) - 1.0`)       |
| Symmetry          | Polar modulo on `xy` plane to create radial tiling           |
| Raymarching       | Marches through space using signed distance functions        |
| Glow accumulation | Exponential falloff (`exp(-d * k)`) to accumulate brightness |
| Visual effects    | Phantom-band glow modulation based on position + time        |
| Movement          | Global rotation over time using `rot(...)`                   |

### 1. ray setup

The ray starts from a moving camera position:

```glsl
vec3 cPos = vec3(0.0, 0.0, -3.0 * iTime);
```

* This moves the camera **forward along the z-axis** over time.
* Camera orientation is based on `cUp`, `cSide`, and `cDir` vectors, allowing rotation with time (`sin(iTime)` used in `cUp`).
* The final `ray` vector is built like a simple camera raycasting system.

### 2. repeating space and radial symmetry

Before the main shape is rendered, space is **tiled and symmetrized**:

```glsl
p1.x = mod(p1.x - 5., 10.) - 5.;
p1.y = mod(p1.y - 5., 10.) - 5.;
p1.z = mod(p1.z, 16.) - 8.;
p1.xy = pmod(p1.xy, 5.0);
```

* **mod()** creates a repeated tiling in 3D: every 10 units on x/y and 16 units on z.
* `pmod()` applies **polar modular symmetry** to the `xy` plane.

#### what is `pmod()`?

```glsl
vec2 pmod(vec2 p, float r)
```

* Divides the plane into `r` equal radial slices (like a pie).
* Snaps the angle of `p` to the nearest slice boundary.
* Rotates the position to that slice’s local orientation.
* Creates **radial symmetry**, resulting in **multi-armed patterns**.

### 3. defining the fractal box field

The geometry is created by folding space recursively:

```glsl
for (int i = 0; i < 5; i++) {
  p = abs(p) - 1.0;
  p.xy *= rot(iTime * 0.3);
  p.xz *= rot(iTime * 0.1);
}
```

* **Iterated Function System (IFS)** style transformation.
* Each iteration folds space closer to the origin, making the pattern more intricate.
* Dynamic rotation (`rot(iTime * ...)`) adds **continuous morphing**.
* Finally, it calls:

```glsl
return box(p, vec3(0.4, 0.8, 0.3));
```

Using this distance function:

```glsl
float box(vec3 p, vec3 b)
```

* A **signed distance to a box**, using standard SDF math.
* Provides a smooth surface boundary for raymarching.

### 4. raymarch loop with phantom glow

```glsl
for (int i = 0; i < 99; i++) {
  vec3 pos = cPos + ray * t;
  float dist = map(pos, cPos);
  dist = max(abs(dist), 0.02);
  float a = exp(-dist * 3.0);
```

* The ray moves forward by `t += dist * 0.5`, typical for sphere tracing.
* `a = exp(-dist * 3.0)` fades brightness as the ray is farther from surfaces.
* Two accumulators are used:

```glsl
if (mod(length(pos) + 24.0 * iTime, 30.0) < 3.0) {
  a *= 2.0;
  acc2 += a;
}
```

#### what’s this?

This adds **banded glowing pulses** at regular intervals along the ray path. It uses a trick called “phantom mode” to modulate brightness based on distance and time, adding movement.

### 5. final color and glow

```glsl
vec3 col = vec3(
  acc * 0.01,
  acc * 0.011 + acc2 * 0.002,
  acc * 0.012 + acc2 * 0.005
);
```

* Red, green, and blue are weighted slightly differently to give **color variation**.
* `acc2` (phantom glow) adds bluish sparkles.
* The alpha fades with ray depth: `1.0 - t * 0.03`

### summary of visual output

What you get:

* **Recursive, rotating box forms** tiled in 3D space
* **Radial symmetry** on the XY plane
* A camera that moves forward smoothly, creating a flying-through effect
* **Soft volumetric glow**, building up near shapes
* **Flickering ghost trails** and spark bands from distance modulation

### if you want to tweak it…

* Change the number in `pmod(p1.xy, 5.0)` to increase/decrease symmetry arms.
* Adjust `acc2` band timing: `mod(length(pos)+24.*iTime, 30.)` for faster/slower flicker.
* Increase iterations in the IFS loop (`for (int i = 0; i < 5; i++)`) for more fractal complexity.
* Modify box size in `box(p, vec3(...))` to change the structure.
