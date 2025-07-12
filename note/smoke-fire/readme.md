# Smoke Fire

https://www.shadertoy.com/view/wtB3RG

This shader visualizes **fluid dynamics** by computing **normals** from a height-like field (derived from the length of RGB values in `iChannel0`) and applying **lighting** using those normals.

It's described as "computational flockarooid dynamics" — a playful twist on CFD (computational fluid dynamics). The actual simulation is not done here; this shader simply renders the result using surface lighting effects.

## 🔍 Function Breakdown

### 1. `getVal(uv)`

```glsl
float getVal(vec2 uv) {
    return length(texture(iChannel0, uv).xyz);
}
```

* Retrieves the magnitude (length) of the RGB color at coordinate `uv`.
* Interprets RGB as a vector: `sqrt(R² + G² + B²)`.
* Used as a pseudo-height value.

### 2. `getGrad(uv, delta)`

```glsl
vec2 getGrad(vec2 uv, float delta) {
    vec2 d = vec2(delta, 0);
    return vec2(
        getVal(uv + d.xy) - getVal(uv - d.xy),
        getVal(uv + d.yx) - getVal(uv - d.yx)
    ) / delta;
}
```

* Computes a 2D **gradient vector** using finite differences.
* Measures change in `getVal` in both X and Y directions.
* Output represents the slope of the field at that point.

## 🧱 Main Shader Logic

### Normalize UV

```glsl
vec2 uv = fragCoord.xy / iResolution.xy;
```

* Converts fragment coordinates into normalized space (0 to 1).

### Compute Normal Vector

```glsl
vec3 n = vec3(getGrad(uv, 1.0 / iResolution.y), 150.0);
n = normalize(n);
```

* Constructs a **3D normal vector** from the gradient.
* The Z-component (150.0) is large to create a "steep slope" effect.
* The result is normalized to form a proper surface normal.

### Lighting Setup

```glsl
vec3 light = normalize(vec3(1, 1, 2));
```

* Light direction from top-right and slightly above.

### Diffuse Shading

```glsl
float diff = clamp(dot(n, light), 0.5, 1.0);
```

* Computes the **Lambertian diffuse** term.
* Ensures minimum brightness (0.5) to avoid total darkness.

### Specular Highlight

```glsl
float spec = clamp(dot(reflect(light, n), vec3(0, 0, -1)), 0.0, 1.0);
spec = pow(spec, 36.0) * 2.5;
```

* Computes specular reflection assuming the viewer is looking forward (`vec3(0, 0, -1)`).
* Uses **Phong-style exponent** (`36.0`) for sharpness.

### Final Color

```glsl
fragColor = texture(iChannel0, uv) * vec4(diff) + vec4(spec);
```

* Multiplies texture color by diffuse light.
* Adds specular highlight.
* Outputs as final fragment color.

## 🎨 Visual Result

You see a 3D-illuminated **fluid surface**:

* Bright ridges and shaded valleys,
* With shiny highlights from the specular reflection,
* Simulating bump lighting on the evolving field in `iChannel0`.

## 🔄 Notes

* The actual fluid behavior is simulated elsewhere (e.g., in prior passes).
* This pass is only **visualizing** that fluid using surface lighting tricks.
* You can toggle/comment various parts (e.g. `n *= n;` or `spec = 0.0;`) for debugging or stylistic effects.
