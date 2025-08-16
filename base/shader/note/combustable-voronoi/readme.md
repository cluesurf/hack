# Combustable Voronoi

https://www.shadertoy.com/view/4tlSzl

This shader generates a glowing, organic, **3D Voronoi-based pattern** that evolves over time and is colored with a **physically inspired fire palette**. It gives the impression of swirling plasma or heat layers — like looking through a field of animated, burning gas.

The key components are:

* A **multi-layer Voronoi noise** function with time distortion.
* A **Kelvin-temperature-based fire palette**.
* A simulated camera and raymarching direction.
* Optional dust/noise and chromatic dispersion for added richness.

### FirePalette: Physically-Based Flame Colors

```glsl
vec3 firePalette(float i) {
    float T = 1400. + 1300.*i;
    vec3 L = vec3(7.4, 5.6, 4.4); // Wavelengths (hundreds of nanometers)
    L = pow(L, vec3(5)) * (exp(1.43876e5 / (T * L)) - 1.);
    return 1. - exp(-5e8 / L);
}
```

* Computes light color based on **black-body radiation** at temperature `T` (1400–2700 K).
* The result mimics how fire glows across different intensities:

  * Low = dark red
  * Medium = orange/yellow
  * High = white/blue
* Based on a classic method from **Hugo Elias**’s procedural fire article.

### Hash Function: Deterministic Randomness

```glsl
vec3 hash33(vec3 p) {
    float n = sin(dot(p, vec3(7,157,113)));
    return fract(vec3(2097152, 262144, 32768) * n);
}
```

* Converts 3D position into a **pseudo-random 3D vector** in \[0, 1].
* Used in Voronoi point generation to randomly offset cell centers.

### Voronoi Function: 3D Cellular Noise

```glsl
float voronoi(vec3 p)
```

* Computes the squared distance to the **nearest random point** in neighboring cells.
* Uses a **3×3×3 neighborhood**, but with the Z loop unrolled for performance.
* `hash33(...)` adds pseudo-random jitter to cell positions.
* Returns a scalar in `[0, 1]`, lower values near cell centers.

### NoiseLayers: Layered Animated Voronoi fBm

```glsl
float noiseLayers(in vec3 p)
```

* Applies 5 octaves of animated Voronoi noise:

  * Each octave: `p *= 2.0`, `t *= 1.5`
  * Time advances in a separate vector `t = vec3(0, 0, p.z + iTime*1.5)`
* Returns a **fractal blend of Voronoi noise** with:

  * Smoother, deeper structure
  * Parallax-like motion from separate time scaling
  * Organic, cell-like visual complexity

### Ray Setup and Camera Motion

```glsl
vec2 uv = (fragCoord - iResolution.xy * 0.5) / iResolution.y;
uv += vec2(sin(iTime * 0.5) * 0.25, cos(iTime * 0.5) * 0.125);
vec3 rd = normalize(vec3(uv.x, uv.y, π/8.0));
rd.xy *= rotation matrix (simulated roll)
```

* Converts screen coordinates to **normalized view rays**.
* Adds gentle camera drift over time.
* Applies slow camera roll by rotating `rd.xy`.
* This simulates a **subtle flying-through-space effect**.

### Sampling and Color Calculation

```glsl
float c = noiseLayers(rd * 2.0);
c = max(c + dot(hash33(rd) * 2. - 1., vec3(0.015)), 0.0); // Add subtle noise
```

* Samples the `noiseLayers` field at scaled ray direction.
* Adds minor noise (simulating dust or flicker).

#### Color:

```glsl
c *= sqrt(c) * 1.5;
vec3 col = firePalette(c);
col = mix(col, col.zyx * 0.15 + c * 0.85, min(pow(dot(rd.xy, rd.xy) * 1.2, 1.5), 1.0));
col = pow(col, vec3(1.25));
```

* `sqrt(c) * 1.5`: boosts contrast in mid-high range.
* `firePalette(c)`: maps intensity to fire colors.
* `mix(...)`: adds **chromatic dispersion** — shifts red, green, and blue components depending on viewing angle.
* `pow(col, vec3(1.25))`: slightly increases contrast for final glow.

### Output

```glsl
fragColor = vec4(sqrt(clamp(col, 0., 1.)), 1.0);
```

* Applies gamma correction (`sqrt`) to simulate realistic display brightness.
* Final image is a **smooth, glowing, fire-like volumetric texture**.

### Summary of Techniques

| Feature         | Technique                                       |
| --------------- | ----------------------------------------------- |
| Color Palette   | Black-body radiation model (Kelvin temperature) |
| Geometry        | Layered animated 3D Voronoi noise               |
| Motion          | Time scaling and UV drift                       |
| Glow            | fBm accumulation + contrast boost               |
| Visual Richness | Dust noise + chromatic mixing                   |
| Final Shading   | Gamma correction + color grading                |

### Suggested Variations

Want to tweak the look?

* **Cooler colors**: Adjust `firePalette()` wavelength values.
* **More turbulence**: Increase `iTime` scaling or use `t += sin(p)` noise.
* **Harder cells**: Use `1.0 - voronoi(...)` to emphasize cell edges.
* **Black and white**: Replace `firePalette()` with grayscale logic.
