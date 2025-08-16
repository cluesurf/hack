# Nitrostasis

This shader by **Otavio Good** creates a beautiful **volumetric cloudscape** or **nebula-like scene** using **signed distance field (SDF) raymarching**, procedural noise, and camera animation. The result is a dreamy, soft, and glowing volume with embedded "sun" spheres and layered cloud textures, achieved entirely in fragment shader code.

Let’s break it down.

### What This Shader Does

This is a **volumetric raymarcher** that renders clouds and embedded objects using:

* A **distance field** (SDF) built from layered 3D noise.
* **Camera animation** and controls.
* **Noise-based shading** for subtle color and glow.
* **Sun spheres** inside the cloud.
* **Glow, fog, and vignette** for polish.

The core idea is: trace a ray from the camera, walk through space using distance steps (raymarching), and stop when you hit a surface (small distance). While marching, accumulate glow and color to simulate light scattering in a dense volume.

### Key Concepts and Techniques

| Feature               | How It’s Done                                           |
| --------------------- | ------------------------------------------------------- |
| Procedural noise      | Layered 3D texture-based noise (`noiseTex`)             |
| Clouds                | Using noise as density + soft falloff                   |
| SDF raymarching       | March through space using `DistanceToObject()`          |
| Glow accumulation     | `marchCount` increases near dense regions               |
| Fog and blending      | Distance-based fog + vignetting                         |
| Animated camera       | Controlled by mouse and time                            |
| Objects inside clouds | Optional spheres (e.g., “sun”) with different materials |

### Camera Setup

```glsl
camPos.z -= iTime * 0.5;
camLookat.z -= iTime * 0.5;
```

The camera moves forward slowly through the volume, creating an illusion of drifting through clouds.

`camPos` is jittered with hash-based noise for a subtle **depth-of-field effect** (reducing banding and adding realism).

### Ray Direction and Projection

```glsl
vec3 camVec = normalize(camLookat - camPos);
vec3 rayVec = normalize(worldPix - camPos);
```

These vectors define the **viewing direction** and generate a ray for each pixel in screen space.

### Distance Field: Defining Cloud Volume

```glsl
float n = noiseTex(p*2.0+iTime*0.6);
n += noiseTex(p*4.0+iTime*0.7)*0.5;
...
float dist = n*0.25 - 0.275;
```

This block builds **layered fractal noise** to define the **density and thickness of clouds**. The output `dist` defines how close the ray is to the "cloud surface."

It also includes:

```glsl
dist = smax(dist, -(abs(fract(p.y*4.0)-0.5) - 0.15), 0.4);
```

This introduces **layered horizontal cuts**, making the volume appear more layered like clouds or vapor.

It also checks for embedded “suns”:

```glsl
distMat = matMin(distMat, vec2(length(p - sunPos) - 0.6, 6.0));
```

This adds glowing orbs at fixed positions within the volume.

### Raymarching Loop

```glsl
for (int i = 0; i < 150; i++) {
    pos = camPos + rayVec * t;
    distAndMat = DistanceToObject(pos);
    if (t > maxDepth || abs(distAndMat.x) < 0.0025) break;
    t += distAndMat.x * 0.7;
    marchCount += 1.0 / distAndMat.x;
}
```

* Marches through the scene up to 150 steps.
* Stops early if the ray hits something (`dist < epsilon`) or goes too far.
* Accumulates **`marchCount`**, which increases when close to dense surfaces, producing **glow intensity**.

### Shading and Color

```glsl
if (abs(distAndMat.x) < 0.0025) {
    finalColor = texColor; // surface shading
}
```

* If a surface was hit, color it based on material (default = dusty gray, sun = red-orange).
* Otherwise, background color stays.

Then, regardless of hit:

```glsl
finalColor += marchCount * vec3(4.2, 1.0, 0.41) * 0.0001;
finalColor = mix(fogColor, finalColor, exp(-t * 0.15));
```

* Adds **glow based on march count** (more glow near denser areas).
* **Fog blending** based on how far the ray traveled.

Also:

```glsl
finalColor *= pow(saturate(1.0 - length(uv / 2.5)), 2.0);
```

Adds a **vignette**, darkening edges of the screen for aesthetic framing.

### Optional Effects

* **Noise-based near plane flicker** (`t <= nearClip`) adds dynamic texture to the near plane if ray starts inside a cloud.
* **Gamma correction** using `sqrt()` on the final color.

### Summary of Techniques

| Feature             | Technique                                     |
| ------------------- | --------------------------------------------- |
| Cloud volume        | Layered 3D procedural noise (texture-based)   |
| Glow and lighting   | Accumulated `marchCount`, boosted with color  |
| Fog                 | Distance-based exponential blending           |
| Objects             | Distance fields for embedded spheres (“suns”) |
| Camera              | Time-based drift + noise jittering            |
| Vignette and polish | Edge fading, gamma correction                 |

### Suggested Modifications

Want to try new effects?

* **Change noise scale/frequency** to get puffier or wispier clouds.
* **Add directional light** with normals estimated from SDF gradients.
* **Replace sun orbs** with more complex shapes using SDF combinations.
* **Control camera with mouse** for real navigation.
