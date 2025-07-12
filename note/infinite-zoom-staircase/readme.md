# Infinite Zoom Staircase

https://www.shadertoy.com/view/sljfDD

This shader visualizes a simulated fluid field (provided in `iChannel0`) by:

1. Computing **surface normals** from intensity gradients,
2. Applying **diffuse and specular lighting** to those normals,
3. Rendering a bump-lit surface that looks like dynamic fluid motion.

It doesn't perform fluid simulation itself — it renders the **results** of a previous simulation, possibly stored in a buffer or another shader pass.

## 🔍 Key Concepts

* **getVal**: measures the "height" of the fluid at each UV point using the RGB vector length of `iChannel0`.
* **getGrad**: computes the 2D gradient of this height map — like a slope in X and Y.
* **Normal vector**: formed from the gradient and a fixed Z offset to simulate 3D slope.
* **Lighting**: applies both diffuse and specular light based on the normal.

## 🧱 Code Breakdown

### `getVal(vec2 uv)`

```glsl
float getVal(vec2 uv)
{
    return length(texture(iChannel0, uv).xyz);
}
```

* Samples a color from `iChannel0` at the given UV coordinate.
* Treats the RGB vector as a 3D vector and gets its length.
* This becomes the "height" of the fluid field at that point.

### `getGrad(vec2 uv, float delta)`

```glsl
vec2 getGrad(vec2 uv, float delta)
{
    vec2 d = vec2(delta, 0);
    return vec2(
        getVal(uv + d.xy) - getVal(uv - d.xy),
        getVal(uv + d.yx) - getVal(uv - d.yx)
    ) / delta;
}
```

* Computes the gradient (slope) in X and Y directions using centered finite differences.
* This represents how the fluid’s "height" changes spatially.

### `mainImage`

#### 1. Normalize fragment coordinates

```glsl
vec2 uv = fragCoord.xy / iResolution.xy;
```

#### 2. Calculate normal vector

```glsl
vec3 n = vec3(getGrad(uv, 1.0 / iResolution.y), 150.0);
n = normalize(n);
```

* Builds a pseudo-3D normal: gradient X and Y, and a constant Z of 150.
* This gives the surface a steep slope and enhances the lighting effect.

#### 3. Lighting setup

```glsl
vec3 light = normalize(vec3(1,1,2));
```

* Light shines from top-right and slightly above.

#### 4. Diffuse lighting

```glsl
float diff = clamp(dot(n, light), 0.5, 1.0);
```

* Dot product gives how aligned the normal is with the light.
* Clamped to keep it from getting too dark.

#### 5. Specular lighting

```glsl
float spec = clamp(dot(reflect(light, n), vec3(0,0,-1)), 0.0, 1.0);
spec = pow(spec, 36.0) * 2.5;
```

* Calculates sharp specular reflection from the eye’s view (`vec3(0,0,-1)`).
* High exponent = tight, shiny highlight.

#### 6. Combine and output final color

```glsl
fragColor = texture(iChannel0, uv) * vec4(diff) + vec4(spec);
```

* Base color modulated by diffuse light.
* Additive specular highlights.
* `alpha = 1.0` by default.

## 🎨 Visual Result

This produces a **lit surface** showing the texture’s contours as if they were a bumpy 3D fluid surface:

* **Light comes from top-right**, so ridges face the light, valleys are shaded.
* **Highlights sparkle** based on slope and camera position.
* Creates the illusion of depth and motion over a 2D field.

## 🔧 Use Cases

* Used as the **final pass** in a fluid simulation pipeline.
* Enhances perceptual detail of simulation using standard lighting.
* Could be used in:

  * Fluid visualizers
  * Audio-reactive textures
  * Artistic renderings of 2D data
