# Molten Bismuth

https://www.shadertoy.com/view/WdVXWy

This shader by **Florian Berger (flockaroo)** is the **rendering pass** of a real-time fluid simulation (CFD = *Computational Fluid Dynamics*), building on the project ["Spilled"](https://www.shadertoy.com/view/MsGSRd). It displays a **dynamic liquid-like surface** with **lighting, reflections**, and **velocity-based distortion**, all in a **single-pass** approach.

Let’s break it down section by section:

### Visualizing a Simulated Fluid Surface

* This shader renders a **liquid surface** that has been simulated in another buffer (typically in `iChannel0`).
* It extracts surface normals from the data, computes lighting and reflection, and outputs a glossy, smooth look.
* There is **no mesh** — everything is done in screen-space using gradient approximations.

### Key Concepts and Features

| Feature              | Description                                                           |
| -------------------- | --------------------------------------------------------------------- |
| Fluid visualization  | Reads a simulated fluid field from `iChannel0`.                       |
| Screen-space shading | Uses gradient to compute normals.                                     |
| Reflection           | Reflects view ray off surface normal and samples `iChannel2`.         |
| Velocity feedback    | Adds velocity-based color distortion (gives it an oily/bismuth look). |
| Interactive pushing  | Mouse interaction is handled in simulation, not here.                 |
| Initialization       | Press `I` key to reset fluid (in simulation pass).                    |

### 1. Texture Access Functions

```glsl
vec4 getCol(vec2 uv) { return texture(iChannel0, scuv(uv)); }
float getVal(vec2 uv) { return length(getCol(uv).xyz); }
```

* `iChannel0` stores the fluid field (typically RG = velocity, B = density).
* `getCol` fetches the RGBA at a location.
* `getVal` converts that to a scalar (norm of RGB), used to compute gradients.

Note: `scuv(uv)` is undefined here, likely a macro/function defined elsewhere (e.g., to add wrapping or scaling).

### 2. Surface Normal from Gradient

```glsl
vec2 getGrad(vec2 uv, float delta)
```

* Approximates the **gradient** (∇field) using finite differences.
* This is used to create a **pseudo-normal** for the surface.

```glsl
vec3 n = vec3(-getGrad(uv, 1.4/iResolution.x)*.02, 1.);
n = normalize(n);
```

* Builds a 3D normal from 2D screen-space gradient.
* The normal points upward (`z = 1`) and is tilted by the gradient in `x` and `y`.
* Scaling `0.02` controls how bumpy the surface appears.

### 3. Environment Reflection

```glsl
vec2 sc = (fragCoord - Res * 0.5) / Res.x;
vec3 dir = normalize(vec3(sc, -1.));
vec3 R = reflect(dir, n);
vec3 refl = myenv(vec3(0), R.xzy, 1.).xyz;
```

* Converts fragment coordinate to a **view direction** `dir`.
* Reflects `dir` off the surface normal `n`.
* `myenv(...)` samples the **environment map** (`iChannel2`) in the reflected direction.

This simulates a **skybox reflection** — giving the fluid surface a realistic shine.

### 4. Color Composition

```glsl
vec4 col = getCol(uv) + 0.5;
col = mix(vec4(1), col, 0.35);
col.xyz *= 0.95 + -0.05 * n;
```

* Boosts the sampled fluid color (adds +0.5).
* Mixes it with white (to desaturate and brighten).
* Slightly tints the color based on the surface normal (for visual depth).

The final color is then modulated by the reflection:

```glsl
fragColor.xyz = col.xyz * refl;
fragColor.w = 1.0;
```

So you get **fluid color × reflected sky/environment**, simulating **specular reflection** on a smooth fluid surface.

### 5. (Commented-Out) Lighting Code

This part is present but unused:

```glsl
// vec3 light = normalize(vec3(-1,1,2));
// float diff = clamp(dot(n,light), 0., 1.0);
// float spec = clamp(dot(reflect(light,n), vec3(0,0,-1)), 0.0, 1.0);
// spec = exp2(log2(spec)*24.0)*2.5;
```

It would:

* Compute **diffuse lighting** from a directional light.
* Compute **specular highlights** with high shininess (`spec^24`).
* However, this is not used in the final fragment color — likely removed in favor of the reflection-based shading.

### Summary of Techniques

| Feature        | Method                                               |       |     |
| -------------- | ---------------------------------------------------- | ----- | --- |
| Surface normal | Screen-space gradient (\`∇                           | field | \`) |
| Lighting       | Environment reflection using `reflect()`             |       |     |
| Fluid color    | Sampled from `iChannel0`, enhanced and distorted     |       |     |
| Interaction    | Not handled here — done in simulation buffer         |       |     |
| Realism        | Achieved through subtle reflection + normal tweaking |       |     |

### What Makes It Look So Fluid?

* The **gradient-derived normals** simulate a flowing, deforming surface.
* The **real-time reflections** give it a glassy, bismuth/oily shimmer.
* The **feedback from the velocity field** introduces subtle motion-based tinting.
* The **animated field (in another buffer)** brings the simulation to life.
