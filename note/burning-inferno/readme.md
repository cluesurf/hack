# Burning Inferno

https://www.shadertoy.com/view/mljSWV

This shader by **S. Guillitte** creates a dynamic field of glowing, cloud-like structures built from swirling, wave-based distortions in 3D space. It combines:

* Sinusoidal field layering
* Logarithmic time-based distortion
* Radial rotations
* A soft glow accumulation via raymarching

The result looks like mountains or clouds made of energy, slowly shifting and breathing over time.

### Field Function: Swirling Interference Pattern

```glsl
vec2 field(in vec3 p)
```

This function builds a **3D interference pattern** using recursive rotation, sine noise, and dot products.

#### How It Works:

* A loop runs with a scale value `s` from 2 to 400.
* At each step:

  * `p.xz` is rotated by `s` (via `R(s)`).
  * `q = p`, then `q.x` is offset by `log(s)` times time.
  * Sine wave patterns are computed with `sin(p * s * factor)` and dotted with constant vectors like `l`.
  * Two accumulators are used:

    * `e`: measures wave energy in `xz`
    * `f`: measures wave energy across full 3D `p`

#### Purpose:

* These computations stack to form **cloud-like or mountainous density fields**, with directional flow and time-based shifting.
* The final result is a `vec2`:

  * `x`: controls how much light to accumulate (density or brightness)
  * `y`: controls how fast to march the ray (detail/speed modulation)

### Raycasting: Accumulating Light Along the Ray

```glsl
vec3 raycast(in vec3 ro, vec3 rd)
```

This function marches a ray through the 3D field and **accumulates brightness** as it moves:

* Starts at a depth `t = 2.5` and steps through the scene.
* The `field()` is sampled at each point.
* `c = v.x`: controls the intensity of light.
* `f = v.y`: controls how fast the ray should march.

The color is blended as:

```glsl
col = 0.95 * col + 0.015 * vec3(c³, c², c);
```

This weighting:

* Emphasizes **blue and white glow**.
* Builds depth and layering by blending old color into new.
* Creates the **glassy, ghostly density** look.

### Camera: Orbiting the Field

```glsl
vec3 ro = vec3(2.);
ro.yz *= R(-1.5);
ro.y += 4.;
ro.xz *= R(0.1 * t);
```

The camera:

* Starts off-center at `(2, 2, 2)` and rotates around the origin.
* Moves upward (`ro.y += 4`) and orbits horizontally (`ro.xz *= R(...)`).
* This causes the entire scene to slowly rotate around the camera.

The direction vector is built from standard `lookAt` logic:

* `ww`: forward vector (target - origin)
* `uu`: right vector
* `vv`: up vector

And the ray for each pixel is computed as:

```glsl
vec3 rd = normalize(p.x * uu + p.y * vv + 4.0 * ww);
```

### Final Color: Log Compression and Clamping

```glsl
col = 0.5 * log(1.0 + col);
col = clamp(col, 0.0, 1.0);
fragColor = vec4(col, 1.0);
```

* `log(1 + col)` compresses high intensities, simulating **high dynamic range tone mapping**.
* The glow is softened and spread out.
* Clamping ensures values stay within valid color range.

### Summary of Techniques

| Feature           | Method Used                                    |
| ----------------- | ---------------------------------------------- |
| Geometry          | Recursive sinusoidal distortions with rotation |
| Animation         | Time-based shifts using `log(s)` and offsets   |
| Symmetry          | Radial/polar rotations (`R(s)`)                |
| Glow Accumulation | `col = blend + sin-based density`              |
| Camera Motion     | Rotating orbit with smooth drift               |
| Tone Mapping      | Logarithmic compression of accumulated light   |

### Suggested Modifications

Want to explore variations?

* **Change `l = vec3(...)`** to alter the direction and style of field interference.
* **Adjust `s` bounds** or scaling logic to get smoother or sharper patterns.
* **Try linear instead of logarithmic time shifts** for more rhythmic waves.
* **Use color grading** in the final blending step for a different glow palette (e.g., green, orange, or purple).
