# Multiscale MIP Fluid

https://www.shadertoy.com/view/tsKXR3

This GLSL shader implements a **multi-scale fluid dynamics visualization** using **mipmaps** and **multiple buffers** to simulate fluid behavior like **vorticity, turbulence, and pressure**. It uses techniques inspired by **Large Eddy Simulation (LES)** and **Vorticity Confinement** while optimizing performance by leveraging mipmap-based sampling.

Let’s break it down:

## 🔧 High-Level Structure

This fragment shader (likely from Buffer A or the final image pass) renders the fluid simulation by:

1. Computing gradients (flow directions) from a **pressure texture (`iChannel1`)** at multiple mipmap levels.
2. Estimating **occlusion** to enhance visual depth.
3. Sampling **velocity/advection/curl** textures for visualization.
4. Computing **lighting and specular highlights**.
5. Blending it all together to produce a final visual that feels 3D and dynamic.

## 🧮 Core Concepts

### 1. **Mipmaps for Multi-Scale Gradient**

```glsl
vec2 diff(vec2 uv, float mip)
```

This function computes the **gradient** of the pressure field `iChannel1` at a given mipmap level.

* `textureLod(...)` is used to fetch from a *specific mipmap level*, simulating coarser resolutions.
* It approximates directional pressure differences using 3x3 sampling (e.g. north, east, northeast, etc.).
* This is similar to **finite difference gradient estimation**, but at multiple levels of detail.

### 2. **Main Loop: Multi-Scale Accumulation**

```glsl
for (mip = 1.0; mip <= STEPS; mip += 1.0)
```

* For each mipmap level:

  * It accumulates scaled gradient vectors (`dxy`).
  * It calculates an **occlusion metric** `occ` by comparing pressure at current mip level with base level.
  * Uses a custom `softclamp` function (not defined here) to blend smoothly and avoid harsh cutoffs.

This approximates **multi-scale pressure flow and turbulence** behavior efficiently.

## 💡 Lighting and Shading

```glsl
vec3 ld = light(uv, BUMP, 0.5, dxy, iTime, avd);
float spec = ggx(avd, vec3(0,1,0), ld, 0.1, 0.1);
```

* `light(...)` computes light direction based on bump normal approximation (`dxy`) and time animation.
* `ggx(...)` is a **specular reflection** model (microfacet-based), used to give fluid a shiny, flowing appearance.
* Specular intensity is tone-mapped with logarithmic scaling:

  ```glsl
  spec = (log(LOG_SPEC+1.0)/LOG_SPEC)*log(1.0+LOG_SPEC*spec);
  ```

## 🌀 Visualization Modes

Controlled by `#define` flags:

### Options:

* `VIEW_VELOCITY` → shows advected velocity (texture `iChannel0`).
* `VIEW_CURL` → shows curl or vorticity (texture `iChannel2`).
* `VIEW_ADVECTION` → shows additional advection components (also from `iChannel0`).
* `VIEW_GRADIENT` → visualizes the pressure gradient.
* (default) → shows vorticity confinement vectors from `iChannel3`.

Each uses different math to create a **false color visualization** of that field.

Example:

```glsl
vec4 diffuse = softclamp(0.0,1.0,6.0*vec4(texture(iChannel0,uv).xy,0,0)+0.5,2.0);
```

Scales and clamps velocity for display.

## 🎨 Final Output

```glsl
fragColor = (diffuse + 4.0 * mix(vec4(spec), 1.5 * diffuse * spec, 0.3));
fragColor = mix(1.0, occ, 0.7) * (softclamp(0.0, 1.0, contrast(fragColor, 4.5), 3.0));
```

* **Blends diffuse field with specular light**.
* **Modulates by occlusion** for depth.
* **Applies contrast** and `softclamp` to stylize the result.
* Optional debug views are commented out:

  ```glsl
  // fragColor = vec4(occ);
  // fragColor = vec4(spec);
  // fragColor = diffuse;
  ```

## 📚 Key Terms

| Term           | Meaning                                                   |
| -------------- | --------------------------------------------------------- |
| `iChannel0`    | Velocity/Advection data                                   |
| `iChannel1`    | Pressure buffer (used for solving divergence)             |
| `iChannel2`    | Curl/Vorticity                                            |
| `iChannel3`    | Vorticity confinement vector                              |
| `textureLod()` | Samples texture at specific mipmap level                  |
| `BUMP`         | Bump mapping scale factor                                 |
| `softclamp()`  | Presumably a smoother version of `clamp()` for aesthetics |
| `ggx()`        | A physically-based specular highlight model               |

## 🧠 Summary

This is a **performance-conscious fluid renderer** that:

* **Solves pressure and velocity fields** with approximate multi-scale techniques using mipmaps.
* **Avoids heavy computation** by pushing cost to mipmap generation (O(n log n) prepass).
* **Supports multiple visualization modes**.
* **Achieves rich visuals** via lighting, specular highlights, and occlusion.
