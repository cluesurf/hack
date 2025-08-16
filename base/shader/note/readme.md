# 🧠 THE THEORY: How Infinite Kaleidoscopes Work

## 1. **Symmetry via Polar Subdivision**

* Split a circle into `N` equal wedges (think of a pizza with N slices).
* One base pattern is reflected and rotated into each wedge.
* Reflections give the signature kaleidoscope "mirror" feel.

## 2. **Zoom via Logarithmic Depth**

* To simulate infinite zoom, your shader or geometry should **scale down repeatedly** toward the center.
* In shaders, you can do this with:

  * A spiral tiling
  * Log-polar transforms
  * Möbius transformations (for 3D feel)

## 3. **3D Illusion**

You're looking for the illusion of “falling inward forever.” You achieve that by combining:

* **Zoom scaling** (scale all by `1 + t * 0.01`)
* **Radial motion** (rotating slowly)
* **Depth cues** (color/fade based on distance, simulated lighting)

# 🧮 KEY MATH TRICKS

## Polar to Cartesian

```js
x = r * Math.cos(theta);
y = r * Math.sin(theta);
```

## Log-Polar Transform (shader-style idea)

```glsl
vec2 logPolar(vec2 uv, vec2 center) {
  vec2 offset = uv - center;
  float r = log(length(offset));       // log distance
  float a = atan(offset.y, offset.x);  // angle
  return vec2(a, r);
}
```

## Tiling + Mirror

```glsl
float symmetry = 6.0;
float angle = atan(uv.y, uv.x);
angle = mod(angle, 2.0 * PI / symmetry);
```

# 🧰 IMPLEMENTATION PLAN (in JavaScript)

You can do this with either:

* **Canvas 2D** (simpler, but less 3D)
* **WebGL or Three.js** (ideal for 3D infinite tunnel effects)
* **ShaderToy port** using `regl`, `twgl`, or pure `glsl-canvas`

# 🧪 SAMPLE STARTER CODE (Canvas 2D Kaleidoscope)

## Simple JavaScript + Canvas — Rotating Reflected Pattern

```html
<canvas id="kaleido"></canvas>
<script>
const canvas = document.getElementById("kaleido");
const ctx = canvas.getContext("2d");

canvas.width = window.innerWidth;
canvas.height = window.innerHeight;

function drawBaseShape(ctx, t) {
  ctx.beginPath();
  for (let i = 0; i < 100; i++) {
    let angle = i * 0.2 + t * 0.002;
    let radius = 100 + 50 * Math.sin(i * 0.1 + t * 0.01);
    let x = radius * Math.cos(angle);
    let y = radius * Math.sin(angle);
    ctx.lineTo(x, y);
  }
  ctx.strokeStyle = `hsl(${t * 0.1 % 360}, 100%, 50%)`;
  ctx.stroke();
}

function drawKaleidoscope(t) {
  const w = canvas.width;
  const h = canvas.height;
  const slices = 12;
  const angle = (2 * Math.PI) / slices;

  ctx.clearRect(0, 0, w, h);
  ctx.save();
  ctx.translate(w / 2, h / 2);

  for (let i = 0; i < slices; i++) {
    ctx.save();
    ctx.rotate(i * angle);
    drawBaseShape(ctx, t);
    ctx.scale(1, -1);
    drawBaseShape(ctx, t);
    ctx.restore();
  }

  ctx.restore();
}

function animate(t) {
  drawKaleidoscope(t);
  requestAnimationFrame(animate);
}
requestAnimationFrame(animate);
</script>
```

# 🔭 NEXT STEP: INFINITE ZOOM SHADER

For the deep, fractal feel like the **MesmerizeApp**, you'll want to work in WebGL or GLSL.

## ⚡ Try This: Use `glsl-canvas` for ShaderToy-like experience in JS

```bash
npm install glsl-canvas
```

Then you can embed any ShaderToy-style `.frag` file in your page or canvas.

Or use [https://glslsandbox.com/](http://glslsandbox.com/) to preview and copy-paste.

# 🔧 ShaderToy-Style Infinite Zoom

I recommend experimenting with shaders like:

* [Kaleido Zoom](https://www.shadertoy.com/view/3lK3Wn)
* [Infinite Spiral Tunnel](https://www.shadertoy.com/view/tdyGzc)
* [Mobius Transformations](https://www.shadertoy.com/view/3dfSzr)

You can **embed them into your site** using:

* `regl`
* `three.js` with `RawShaderMaterial`
* or [twgl.js](https://twgljs.org/)

# 👣 Where to Go Next

1. **Start with the canvas sketch above.**
2. Then try porting a ShaderToy into your own GLSL canvas using `glsl-canvas` or `three.js`.
3. I can help you:

   * Pick the best shaders to adapt
   * Simplify or remix them
   * Make them interactive
   * Add audio or user input
   * Handle fullscreen, mobile, controls
