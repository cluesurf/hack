# Infinite Mandelbrot Zoom

https://www.shadertoy.com/view/7ly3Wh

This shader performs a **continuous zoom into a minibrot**—a tiny replica of the full Mandelbrot set. It's optimized for recursively zooming into *self-similar fractal copies* using mathematical tricks instead of brute-force high iterations or arbitrary-precision arithmetic.

## 🧠 Concept Summary

* Instead of just zooming into a static Mandelbrot set, this shader **repeats the zoom** into a *particular minibrot*, over and over, creating a kind of infinite tunnel effect.
* Each minibrot (small Mandelbrot clone) has:

  * A center (`MINIBROT_C`)
  * A complex scaling factor (`MINIBROT_SCALE`)
  * A complex affine correction (`MINIBROT_A`)
  * A periodicity estimate (`MINIBROT_PERIOD`)
* The shader **tracks and rescales the coordinates** recursively as you zoom deeper into each copy.

## 🧾 Important Constants

```glsl
const vec2 MINIBROT_C       // Center of the minibrot
const vec2 MINIBROT_SCALE   // Complex scaling factor between zoom levels
const vec2 MINIBROT_A       // Used to unzoom escaped values
const float MINIBROT_PERIOD // Rough period for orbit replication
```

## 🔄 Zooming Logic

```glsl
float t = iTime*iTime/(iTime+1.0);
float s = -log(length(MINIBROT_SCALE));
int n = int(ceil(t/s)); // how many times we've zoomed in

float zoom = exp(-(t-s*float(n)));
```

* Computes a smooth time-based zoom level `t`.
* Calculates how many zoom "steps" deep we are: `n`
* Each zoom multiplies by `MINIBROT_SCALE`, so this keeps track of the **number of recursive zooms** we've passed through.

## 🔃 Coordinate Re-Mapping

```glsl
vec2 dc = vec2(cos(theta),-sin(theta)) * 10.0 * zoom / length(iResolution);
vec2 c = C + cmul(dc, vec2(1.0,-1.0)*(fragCoord - iResolution.xy*0.5));
```

* `dc` is the pixel-to-complex-plane scale at the current zoom.
* `c` is the current complex coordinate in the Mandelbrot plane for this pixel.
* `theta` is used to **rotate the fractal** with each zoom (to keep orientation correct).
* Coordinates are transformed by recursively applying the inverse of `MINIBROT_SCALE`.

## 🔁 Recursive Unzooming (Before iteration)

```glsl
while (n > 0 && dot(c - MINIBROT_C, c - MINIBROT_C) > MINIBROT_R2) {
    c = MINIBROT_C + cmul(c, MINIBROT_SCALE);
    dc = cmul(dc, MINIBROT_SCALE);
    n--;
}
```

* If the current coordinate `c` is too far from the minibrot center, it’s recursively **scaled back outward**.
* This allows us to always stay close to the current minibrot copy we’re zooming into.
* It’s a key trick: stay near the self-similar region, no matter how deep you zoom.

## 🧮 Mandelbrot Iteration

```glsl
vec2 z = vec2(0.0);
vec2 dz = dc;  // derivative for distance estimation
```

* Standard Mandelbrot iteration: `z = z² + c`, but with derivative tracking `dz` for **distance estimation coloring**.
* If `z` escapes:

  * If we're inside a deeper minibrot (n > 0), we “unzoom” again using `MINIBROT_A` (adjustment).
  * Else we break the loop (pixel is outside the Mandelbrot set).

## 🎨 Coloring

```glsl
float d = !(i<ITER)? 0.0 :
          sqrt(dot(z,z)/dot(dz,dz)) * 0.5 * log(dot(z,z));

fragColor = vec4(vec3((1.0 - d)*(0.5 + 0.5 * cos(log(1.0 + i2 * 2.0e-5)))), 1.0);
```

* Uses **distance estimation** (`d`) for shading smooth gradients.
* Adds **logarithmic time-based coloring** (sinusoidal) for psychedelic color bands.
* Final color is grayscale; the `cos(log(...))` part gives wave-like intensity shifts across iterations.

## 🌀 What Makes This Special

* Efficient infinite fractal zoom, without the need for huge iterations or arbitrary-precision math.
* Leverages **self-similarity**: instead of zooming into arbitrary spots, it zooms into known "minibrots" which are smaller copies of the full set.
* By tweaking `MINIBROT_C`, `MINIBROT_SCALE`, and `MINIBROT_A`, you can smoothly tunnel into **different Mandelbrot subregions** like:

  * Seahorse Valley
  * Elephant Valley
  * Needles
* It’s a clever combination of **mathematics, recursion, and graphics optimization**.
