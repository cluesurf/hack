# Smoking

https://www.shadertoy.com/view/Mlf3RB

This shader by **S. Guillitte (2015)** renders an abstract, glowing volumetric structure using a fractal-like transformation in 3D space. It blends complex number operations with spatial folding to create a hypnotic, swirling energy field — similar to a *3D Julia set* or *spatial attractor*. Let’s walk through how it works.

The shader builds a **recursive 3D field** by repeatedly transforming a point in space through folding, inversion, and **complex squaring**. Then, a raymarcher samples this space in reverse depth, accumulating light for a glowing, nebula-like effect.

### Key Techniques

| Feature              | Method Used                                          |
| -------------------- | ---------------------------------------------------- |
| Field Geometry       | Inversion + absolute folding + complex squaring      |
| Motion               | Camera orbit and rotation using time and mouse input |
| Glow Accumulation    | Exponential distance-based brightness                |
| Complex Arithmetic   | 2D vectors used as complex numbers (`csqr`, `cmul`)  |
| Volumetric Rendering | Backward raymarch with light buildup over steps      |

### 1. Complex Math Helpers

```glsl
vec2 cmul(vec2 a, vec2 b) { ... }
vec2 csqr(vec2 a) { return vec2(a.x*a.x - a.y*a.y, 2.0*a.x*a.y); }
```

These treat `vec2` as **complex numbers**:

* `csqr` squares a complex number.
* Used later to transform `p.yz` as though it's a complex plane.

### 2. Field Function: Inversion and Folding

```glsl
float field(in vec3 p)
```

This is the heart of the geometry:

#### Transformation Loop:

```glsl
for (int i = 0; i < 10; ++i) {
    p = 1.1 * abs(p) / dot(p,p) - 0.6;
    p.yz = csqr(p.yz);
    res += exp(-6. * abs(dot(p,c)) * dot(p.xz,p.xz));
}
```

#### What's Happening:

* **abs(p)**: folds space across axes (like a mirror)
* **division by dot(p,p)**: inverts space, pushing outer regions inward
* **csqr(p.yz)**: recursively warps the `y,z` plane with complex squaring (like 2D fractals)
* `res += ...`: builds up a brightness metric based on how the transformed point relates to the original

This produces **dense structures near the origin**, with layers that swirl and twist due to the complex squaring.

### 3. Raymarching: Sampling the Glowing Volume

```glsl
float t = 8.0 * zoom;
float dt = 0.05 * zoom;
vec3 col = vec3(0.0);
for (int i = 0; i < 64; i++) {
    float c = field(ro + t * rd);
    t -= dt * (0.3 + c*c);
    col = 0.92 * col + 0.19 * vec3(c, c*c, c*c*c);
}
```

#### Purpose:

* Samples backwards along the ray (`t` starts far and decreases).
* `field(...)` gives a brightness value `c` at each sample point.
* Higher `c` values cause the ray to **step more quickly** back.
* Color is **accumulated over time**, with non-linear RGB components:

  * Red = c
  * Green = c²
  * Blue = c³ → more color variation and depth

This gives a **volumetric fog or plasma-like glow** with intensity changing based on shape.

### 4. Camera: Mouse and Time-Based Rotation

```glsl
vec3 ro = zoom * vec3(4.0);
ro.yz *= rot(m.y);
ro.xz *= rot(m.x + 0.1 * time);
```

* Starts at position `(4, 4, 4)` then rotated:

  * `yz` rotation = vertical orbit
  * `xz` rotation = horizontal orbit over time
* If the mouse is clicked (`iMouse.z > 0.0`), it influences the camera angle.

Final ray direction is calculated with:

```glsl
vec3 rd = normalize(p.x * uu + p.y * vv + 4.0 * ww);
```

This gives a standard perspective projection with field of view controlled by the forward vector `ww`.

### 5. Final Color and Postprocessing

```glsl
col = 1.0 - 0.5 * log(1.0 + col);
col = clamp(col, 0.0, 1.0);
fragColor = vec4(col, 1.0);
```

* Applies **logarithmic tone mapping** to compress highlights and simulate HDR.
* `1 - log(...)` inverts the glow, making it look more *electric* or *dense*.
* Clamps to \[0, 1] for valid display color.

### Summary

This shader uses mathematical folding and inversion techniques — inspired by fractals — to simulate a **shifting, glowing energy field**. Its beauty lies in the simplicity of the transformation math and the elegant glow accumulation.

#### Visual Impression:

* Feels like floating through a **quantum plasma** or **dimensional rift**
* Motion and depth come from **rotation**, **recursive squaring**, and **soft color buildup**
* Responds well to mouse movement for **interactive camera control**

Would you like a variation of this using sphere-based distortions or simpler SDFs for easier learning?
