# Swirly Thing

https://www.shadertoy.com/view/4s23WK

This shader, created by Nikita Miropolskiy, is a complex piece of procedural generative art written for Shadertoy. It combines **simplex noise**, **vector fields**, and **multi-pass sampling** to create fluid, evolving visuals with a flowing or smoke-like aesthetic. Below is a breakdown of its major components and how they work:

## 🌪 High-Level Summary

* The visual effect is made by **repeatedly sampling a texture** along a flow field that is derived from **animated 2D and 3D noise**.
* The shader includes **2D and 3D simplex noise** implementations with **animated rotations**, which give the texture a **flowing, organic feel**.
* It uses a technique similar to **feedback loops**, sampling the original texture multiple times with offsets guided by the noise field to create complexity and motion.

## 🔄 Main Pass: `mainImage`

```glsl
void mainImage( out vec4 fragColor, in vec2 fragCoord )
```

### Setup

```glsl
vec2 uv = fragCoord.xy / iResolution.xy;
uv.x *= iResolution.x / iResolution.y;   // aspect correction
uv.y = 1.0 - uv.y;                        // flip Y (Shadertoy coords)
```

### Accumulation Loop

```glsl
vec3 d = vec3(0.);
vec3 e = vec3(0.);
for (int i=0; i<25; i++) {
    d += texture(iChannel0, uv + iTime * 0.05, lod).xyz;
    e += texture(iChannel0, -uv.yx * 3. + iTime * 0.0125, lod).xyz;

    vec2 new_uv = field(uv) * 0.00625 * 0.5;
    lod += length(new_uv) * 5.;
    uv += new_uv;
}
```

* **`d` and `e`** accumulate warped samples of the input texture (`iChannel0`) over 25 steps.
* The **warp direction** comes from the `field(uv)` function, which uses 3D noise-based gradients.
* **`lod`** simulates depth of sampling (level-of-detail), adding blur and softness.

### Final Color Composition

```glsl
vec3 c = texture(iChannel0, uv * 0.1 + iTime * 0.025, lod).xyz;

d *= 1./50.;
e *= 1./50.;
c = mix(c, d, length(d));
c = mix(c, e, length(e));
fragColor = vec4(c, 1.0);
```

* Blends the base color with the `d` and `e` accumulations, creating a **soft glowing effect**.

## 🌀 `field(pos)`: Flow Field From Noise

```glsl
vec2 field(vec2 pos)
```

* Returns a **vector field** based on the gradient of `pot(pos)` (potential).

* `pot` is composed of **3D and 2D noise layers**:

  ```glsl
  float n = noise(p);
  n += 0.5 * noise(p*2.13);
  n += 3. * noise(pos*0.333);
  ```

* Then `field` estimates the gradient numerically:

  ```glsl
  vec2(nx, ny) = ∇pot = (pot(x+e) - pot(x), pot(y+e) - pot(y))
  ```

* This **approximates the flow of a fluid**, directing pixel warping along that flow.

## 🔊 `noise(...)` Functions

### 3D Simplex Noise

```glsl
float noise(vec3 p)
```

* Implements **3D simplex noise**.
* Uses **random surflets** (`random3()`) from the lattice corners.
* Fade function: `w *= w; w *= w;` for smooth transitions.
* Time-based rotation in `random3` gives the noise **temporal flow**.

### 2D Simplex Noise

```glsl
float noise(vec2 p)
```

* Implements **IQ-style 2D simplex noise**.
* Includes **rotations for time-varying behavior**:

  ```glsl
  float t = iTime * 0.5;
  a = RotCS(a, co, si);  // time rotation for smoother flow
  ```

## 🔁 `Rot` and `RotCS`: 2D Rotation

```glsl
vec2 Rot(vec2 p, float t)
```

* Rotates a 2D vector `p` by angle `t`.

```glsl
vec2 RotCS(vec2 p, float c, float s)
```

* Same, but passes in `cos(t)` and `sin(t)` for optimization inside loops.

## 🌈 What This Produces

* The code creates **smoky, dreamy, flowing visuals** that feel alive.
* It evolves over time using `iTime` and recursive sampling of the source texture.
* Visual complexity arises from **multi-scale noise**, **animated flow fields**, and **multi-pass sampling**.

## 🎨 Applications & Inspirations

* This technique is commonly used for:

  * Fluid simulations
  * Procedural fog or clouds
  * Glitch or feedback visuals
  * Organic abstract animations
