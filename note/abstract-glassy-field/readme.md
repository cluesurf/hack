# Abstract Glassy Field

https://www.shadertoy.com/view/4ttGDH

This shader creates the illusion of a **hot, glowing, fluid-filled glass structure**, achieved not through full physical simulation, but via *stylized approximations*. It uses a combination of:

* Signed distance fields (SDF)
* Raymarching
* Tri-planar texture blending
* Fake reflection/refraction
* Accumulated glow and electric effects

The result is a visually rich, glass-like field through which a camera flies.

### The field: blobby sinusoidal shapes

The `map(vec3 p)` function defines the core geometry:

```glsl
p = cos(mod(p*.315*1.25 + sin(mod(p.zxy*.875*1.25, 2.*PI)), 2.*PI));
float n = length(p);
return (n - 1.025)*1.33;
```

What this does:

* Applies cosine and sine-based deformation in 3D.
* Produces *blobby, noise-like shapes* that resemble smooth, wavy surfaces.
* Uses `length(p)` to make the result vaguely spherical.
* Creates a signed distance field: negative inside the surface, positive outside.

The blobs appear to *move* because `p.xy` is offset by the `camPath(p.z)` — making the geometry "swim" around the moving camera.

### Camera motion: flowing through space

The `camPath(float t)` function defines a smooth, curving camera path:

```glsl
vec3 camPath(float t) {
  float a = sin(t * 0.11);
  float b = cos(t * 0.14);
  return vec3(a*4. - b*1.5, b*1.7 + a*1.5, t);
}
```

This allows the camera to:

* Move forward along z
* Weave smoothly in x and y
* Avoid fixed geometry or clipping

This design ensures the field can be endlessly traversed without discontinuities or object boundaries.

### Surface detection: raymarching with glow accumulation

The core raymarching loop is in `trace(vec3 ro, vec3 rd)`:

```glsl
for (...) {
  h = map(ro + rd*t);
  if (abs(h) < 0.001 * (t * 0.25 + 1.) || t > FAR) break;
  t += h;

  if (abs(h) < 0.35)
    accum += (.35 - abs(h)) / 24.;
}
```

What it does:

* Marches along the ray until the surface is found (or max distance reached).
* Uses **sphere tracing**, with variable step sizes.
* Accumulates glow (`accum`) when close to the surface.

### Lighting: faked but layered

Lighting is built from several approximations:

* **Ambient occlusion** (`cao`) samples how exposed the surface is.
* **Shadows** (`sha`) use a raymarch in the light direction.
* **Specular reflection** and **Fresnel effect** add realism.
* **Fake reflections/refractions** simulate glass:

```glsl
vec3 refl = envMap(reflect(r, n));
vec3 refr = envMap(refract(r, n, 1.0 / 1.35));
vec3 refCol = mix(refr, refl, pow(fresnel, 5.));
```

No actual multi-bounce ray tracing is used — these are directional lookups into a tri-planar-mapped texture.

### Texturing: tri-planar projection

The function `tpl(...)` blends texture samples from the XY, YZ, and ZX planes based on the surface normal. It simulates 3D texture mapping without seams or UVs.

This is used for:

* Surface bumping (`db`)
* Environmental reflection/refraction (`envMap`)
* Subtle color variation

### Visual effects: glow, electric pulses, fog

After lighting, multiple layers are added:

#### Accumulated glow

```glsl
vec3 gc = pow(...accum...) * 0.5 + accCol * 0.5;
col += col * gc * 12.0;
```

This makes edges and interior areas appear **hot** and **molten**.

#### Electric pulse

```glsl
float hi = abs(mod(...));
vec3 cCol = vec3(.01, .05, 1) * col / (.001 + hi*hi*0.2);
col += mix(cCol.yxz, cCol, n3D(p*3.));
```

Adds **blue electric shimmer** that pulses in time.

#### Fog

```glsl
vec3 fog = vec3(.125, .04, .05) * (r.y * .5 + .5);
col = mix(col, fog, smoothstep(0., .95, t/FAR));
```

Softens far-away parts with colored haze.

### Post-processing: vignette and gamma

* A radial **vignette** darkens edges of the screen for cinematic framing.
* Final **gamma correction** uses `sqrt()` to approximate perceptual color balance.

### Summary of techniques

| Element        | Technique                                            |
| -------------- | ---------------------------------------------------- |
| Field geometry | Cosine + sine deformations of position vectors       |
| Camera motion  | Smooth curve via sine/cosine                         |
| Raymarching    | Signed distance field with glow accumulation         |
| Normals        | Finite difference + tri-planar bump mapping          |
| Lighting       | Diffuse + specular + fake shadows/occlusion          |
| Reflections    | Environment map with fake reflection/refraction      |
| Texture detail | Tri-planar projection blending                       |
| Visual flair   | Accumulated glow, blue pulse, fog, vignette          |
| Performance    | Efficient tricks instead of full physical simulation |
