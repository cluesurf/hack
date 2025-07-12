# Octograms

https://www.shadertoy.com/view/tlVGDt

This shader draws a field of abstract, rotating, symmetrical box structures that pulse over time and fade with depth. It creates a glowing, volumetric look using **signed distance functions (SDF)** and **raymarching**, with the scene made from a set of **repeating rotated boxes** arranged in 3D.

### Key ingredients

* **Raymarching** to sample a 3D scene over time
* **Procedural box shapes** rotated and offset over time
* **Time-based motion** and **dynamic repetition**
* **Soft-glow accumulation** using exponential falloff
* **Background color blending** for ambiance

### 1. raymarching the scene

```glsl
for (int i = 0; i < 99; i++) {
  vec3 pos = ro + ray * t;
  pos = mod(pos - 2., 4.) - 2.;
  gTime = iTime - float(i) * 0.01;

  float d = map(pos, iTime);
  d = max(abs(d), 0.01);
  ac += exp(-d * 23.);
  t += d * 0.55;
}
```

* `ro` is the camera origin.
* `ray` is the viewing direction.
* For each step, the current point `pos` is:

  * Repeated every 4 units with `mod(...)`, creating **tiling geometry**.
  * Offset slightly in time (`gTime = iTime - i*0.01`) for a **sliding trail** effect.
* The distance `d` is computed using the `map(...)` function and converted to brightness with an exponential falloff.
* Accumulation (`ac`) builds up glow as the ray gets closer to shapes.

### 2. constructing the scene with `map()` and `box_set()`

```glsl
float map(vec3 pos, float iTime) {
  return box_set(pos, iTime);
}
```

The function `box_set()` constructs multiple **symmetrical box shapes** around a center:

```glsl
float box_set(vec3 pos, float iTime) {
  // Each box position is rotated and offset in X or Y.
  // They all pulse using sin(iTime * 0.4).
}
```

It builds:

* 4 boxes offset in X and Y directions, rotating and pulsing
* 2 center boxes scaled differently (`box5`, `box6`)
* The maximum distance is taken between them (`max(...)`) to form a **composite field**

### 3. defining a single box with SDF

```glsl
float sdBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}
```

This is a classic **signed distance function for a box**.

In `box()`, it's combined with scaling and rotation:

```glsl
pos *= scale;
float base = sdBox(pos, vec3(.4, .4, .1)) / 1.5;
...
return -base;
```

* The shapes are scaled, rotated, and repeated in `xy` to create the **octagram-like forms**.
* The negative value flips the field — controlling how the shape is lit and layered.

### 4. background and postprocessing

After raymarching, the final color is:

```glsl
col = vec3(ac * 0.02);
col += vec3(0., 0.2 * abs(sin(iTime)), 0.5 + sin(iTime) * 0.2);
```

* The glow `ac` creates a subtle volumetric light
* The background color animates with time (purple-blueish tint)

Opacity is reduced based on depth:

```glsl
fragColor = vec4(col, 1.0 - t * (0.02 + 0.02 * sin(iTime)));
```

This gives a **fading glow**, where things farther away are less visible.

### 5. key techniques

| Feature         | Technique                                    |
| --------------- | -------------------------------------------- |
| Geometry        | SDF boxes, rotated and layered               |
| Scene structure | Repetition with `mod(...)`                   |
| Motion          | `sin(iTime)`-based offsets                   |
| Raymarching     | Accumulated glow via `exp(-d * k)`           |
| Rotation        | 2D rotation matrix applied to XY and YZ      |
| Coloring        | Glow + animated background + fade with depth |

### Summary

This shader is compact, efficient, and visually rich:

* It animates over time using trigonometric functions.
* It builds shape complexity through repetition and rotation.
* It simulates a volumetric glow by accumulating brightness across ray steps.
* It enhances mood with a time-reactive color background and fading transparency.

The result is a **dynamic, glowing field of rotating geometries**, like a digital sculpture made of light and symmetry.
