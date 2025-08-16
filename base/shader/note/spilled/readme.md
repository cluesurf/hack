# Spilled

https://www.shadertoy.com/view/MsGSRd

This shader, created by Florian Berger ("flockaroo"), is a **single-pass fluid dynamics visualizer** with a twist: it uses a **purely rotational, scale-independent self-advection** system that doesn't require a divergence-free velocity field — an unusual and creative technique.

Here’s a breakdown of what it does and how:

## 🌀 Core Idea

Instead of computing a classic velocity field with conservation of mass (as in traditional CFD), this shader uses **rotational advection** on all spatial scales. That means particles or colors are effectively rotated over time and space, creating natural turbulence-like visuals.

This shader displays the **lighting and 3D bump effect** based on the **gradient of the texture** in `iChannel0`.

## 🔍 Line-by-Line Explanation

### 1. `getVal(uv)`

```glsl
float getVal(vec2 uv)
{
    return length(texture(iChannel0,uv).xyz);
}
```

* Samples the RGB value of `iChannel0` at UV.
* Returns its **length**, treating the RGB as a vector (i.e., its magnitude).
* This serves as the "height" or "intensity" at that point — think of it like a **heightmap**.

### 2. `getGrad(uv, delta)`

```glsl
vec2 getGrad(vec2 uv,float delta)
{
    vec2 d=vec2(delta,0);
    return vec2(
        getVal(uv+d.xy)-getVal(uv-d.xy),
        getVal(uv+d.yx)-getVal(uv-d.yx)
    )/delta;
}
```

* Calculates the **gradient** of the field around `uv` using central difference.
* This gives the slope in x and y directions (i.e. partial derivatives).
* `delta` is typically `1.0 / resolution`, giving pixel-size step.
* Used for **normal calculation** later.

### 3. Main rendering logic

```glsl
vec2 uv = fragCoord.xy / iResolution.xy;
```

* Normalize coordinates to the \[0, 1] UV space.

```glsl
vec3 n = vec3(getGrad(uv,1.0/iResolution.y),150.0);
n = normalize(n);
```

* Constructs a 3D **normal vector**:

  * X and Y from the gradient.
  * Z set to 150.0, creating a steep "up" normal.
* Then normalizes the vector to simulate **surface orientation**.

### 4. Lighting and Shading

```glsl
vec3 light = normalize(vec3(1,1,2));
float diff = clamp(dot(n,light),0.5,1.0);
```

* Defines a light direction from above and to the right.
* `diff` is **diffuse shading** using Lambert’s cosine law.
* Clamped to minimum 0.5 for baseline illumination.

```glsl
float spec = clamp(dot(reflect(light,n),vec3(0,0,-1)),0.0,1.0);
spec = pow(spec,36.0)*2.5;
```

* Computes **specular highlights** with a shiny exponent (36).
* View direction assumed to be `vec3(0,0,-1)` (camera facing into screen).

### 5. Final Output

```glsl
fragColor = texture(iChannel0,uv)*vec4(diff)+vec4(spec);
```

* Modulates the sampled color by the diffuse light (`diff`).
* Adds specular reflection (`spec`) for shine.
* `fragColor` ends up as a shaded visualization of the underlying dynamic texture (`iChannel0`), with 3D lighting effects.

## 🧪 Optional/Unused Features

* `n *= n;` is commented out — would emphasize steeper gradients.
* `spec = 0.0;` is also commented — useful for turning off specular reflection for debugging.

## 💡 Summary

| Feature                  | Description                                                                                                       |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------- |
| Gradient Calculation     | Computes normal from texture values.                                                                              |
| Lighting                 | Simple diffuse + specular.                                                                                        |
| Rotation-based dynamics  | The texture in `iChannel0` evolves over time with rotational advection.                                           |
| No divergence correction | Unlike traditional fluids, this uses purely rotational self-advection, so divergence-free fields are unnecessary. |
| Visual Output            | A shaded representation of fluid motion (with bumps, light, and highlight).                                       |

## 🎨 Visual Result

This shader would create a **fluid-like flow** that appears to be **illuminated from one side**, with ridges and valleys showing up as **bumps** through lighting. It's a clever fusion of **fluid simulation + lighting shader** in a single pass, perfect for real-time generative art or motion graphics.
