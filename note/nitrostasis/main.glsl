/*--------------------------------------------------------------------------------------
License CC0 - http://creativecommons.org/publicdomain/zero/1.0/
To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
----------------------------------------------------------------------------------------
^This means do anything you want with this code. Because we are programmers, not lawyers.

-Otavio Good
*/

float localTime = 0.0;
float marchCount;

float PI = 3.14159265;

vec3 saturate(vec3 a) {
  return clamp(a, 0.0, 1.0);
}
vec2 saturate(vec2 a) {
  return clamp(a, 0.0, 1.0);
}
float saturate(float a) {
  return clamp(a, 0.0, 1.0);
}

vec3 RotateX(vec3 v, float rad) {
  float cos = cos(rad);
  float sin = sin(rad);
  return vec3(v.x, cos * v.y + sin * v.z, -sin * v.y + cos * v.z);
}
vec3 RotateY(vec3 v, float rad) {
  float cos = cos(rad);
  float sin = sin(rad);
  return vec3(cos * v.x - sin * v.z, v.y, sin * v.x + cos * v.z);
}
vec3 RotateZ(vec3 v, float rad) {
  float cos = cos(rad);
  float sin = sin(rad);
  return vec3(cos * v.x + sin * v.y, -sin * v.x + cos * v.y, v.z);
}

// noise functions
float Hash2d(vec2 uv) {
  float f = uv.x + uv.y * 37.0;
  return fract(sin(f) * 104003.9);
}
float Hash3d(vec3 uv) {
  float f = uv.x + uv.y * 37.0 + uv.z * 521.0;
  return fract(sin(f) * 110003.9);
}
float mixP(float f0, float f1, float a) {
  return mix(f0, f1, a * a * (3.0 - 2.0 * a));
}
const vec2 zeroOne = vec2(0.0, 1.0);
float noise2d(vec2 uv) {
  vec2 fr = fract(uv.xy);
  vec2 fl = floor(uv.xy);
  float h00 = Hash2d(fl);
  float h10 = Hash2d(fl + zeroOne.yx);
  float h01 = Hash2d(fl + zeroOne);
  float h11 = Hash2d(fl + zeroOne.yy);
  return mixP(mixP(h00, h10, fr.x), mixP(h01, h11, fr.x), fr.y);
}
float noiseValue(vec3 uv) {
  vec3 fr = fract(uv.xyz);
  vec3 fl = floor(uv.xyz);
  float h000 = Hash3d(fl);
  float h100 = Hash3d(fl + zeroOne.yxx);
  float h010 = Hash3d(fl + zeroOne.xyx);
  float h110 = Hash3d(fl + zeroOne.yyx);
  float h001 = Hash3d(fl + zeroOne.xxy);
  float h101 = Hash3d(fl + zeroOne.yxy);
  float h011 = Hash3d(fl + zeroOne.xyy);
  float h111 = Hash3d(fl + zeroOne.yyy);
  return mixP(mixP(mixP(h000, h100, fr.x), mixP(h010, h110, fr.x), fr.y), mixP(mixP(h001, h101, fr.x), mixP(h011, h111, fr.x), fr.y), fr.z);
}

// IQ's style of super fast texture noise
float noiseTex(in vec3 x) {
  vec3 fl = floor(x);
  vec3 fr = fract(x);
  fr = fr * fr * (3.0 - 2.0 * fr);
  vec2 uv = (fl.xy + vec2(37.0, 17.0) * fl.z) + fr.xy;
  vec2 rg = textureLod(iChannel0, (uv + 0.5) * 0.00390625, 0.0).xy;
  return mix(rg.y, rg.x, fr.z);
}
// 2 components returned
vec2 noiseTex2(in vec3 x) {
  vec3 fl = floor(x);
  vec3 fr = fract(x);
  fr = fr * fr * (3.0 - 2.0 * fr);
  vec2 uv = (fl.xy + vec2(37.0, 17.0) * fl.z) + fr.xy;
  vec4 rgba = textureLod(iChannel0, (uv + 0.5) * 0.00390625, 0.0).xyzw;
  return mix(rgba.yw, rgba.xz, fr.z);
}

vec3 camPos = vec3(0.0), camFacing;
vec3 camLookat = vec3(0, 0.0, 0);

// polynomial smooth min (k = 0.1);
float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  return mix(b, a, h) - k * h * (1.0 - h);
}
float smax(float a, float b, float k) {
  float h = clamp(0.5 + 0.5 * ((-b) + a) / k, 0.0, 1.0);
  return -(mix(-b, -a, h) - k * h * (1.0 - h));
}

vec2 matMin(vec2 a, vec2 b) {
  if(a.x < b.x)
    return a;
  else
    return b;
}

// Calculate the distance field that defines the object.
vec2 DistanceToObject(in vec3 p) {
    // first distort the y with some noise so it doesn't look repetitive.
    //p.xyz = RotateY(p, length(p.xz) + iTime);
    //p.y += 0.1;
    //p.xyz = RotateZ(p, length(p.z) + iTime);
  p.y += noiseTex(p * 0.5) * 0.5;
    // multiple frequencies of noise, with time added for animation
  float n = noiseTex(p * 2.0 + iTime * 0.6);
  n += noiseTex(p * 4.0 + iTime * 0.7) * 0.5;
  n += noiseTex(p * 8.0) * 0.25;
  n += noiseTex(p * 16.0) * 0.125;
  n += noiseTex(p * 32.0) * 0.0625;
  n += noiseTex(p * 64.0) * 0.0625 * 0.5;
  n += noiseTex(p * 128.0) * 0.0625 * 0.25;
    // subtract off distance for cloud thickness
  float dist = n * 0.25 - (0.275);// - abs(p.y*0.02)/* - iTime*0.01*/);
    //dist = smax(dist, -(length(p-camPos) - 0.3), 0.1);	// nice near fade
    // smooth blend subtract repeated layers
  dist = smax(dist, -(abs(fract(p.y * 4.0) - 0.5) - 0.15), 0.4);
  vec2 distMat = vec2(dist, 0.0);
    // sun in the distance
  distMat = matMin(distMat, vec2(length(p - camLookat - vec3(0.0, 0.5, -1.0)) - 0.6, 6.0));
  return distMat;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  localTime = iTime - 0.0;
	// ---------------- First, set up the camera rays for ray marching ----------------
  vec2 uv = fragCoord.xy / iResolution.xy * 2.0 - 1.0;
  float zoom = 1.7;
  uv /= zoom;

	// Camera up vector.
  vec3 camUp = vec3(0, 1, 0);

	// Camera lookat.
  camLookat = vec3(0, 0.0, 0);

    // debugging camera
  float mx = (iMouse.x / iResolution.x + 0.375) * PI * 2.0 - 0.7 + localTime * 3.1415 * 0.0625 * 0.666 * 0.0;
  float my = -iMouse.y * 0.0 / iResolution.y * 10.0 - sin(localTime * 0.31) * 0.5 * 0.0;//*PI/2.01;
  camPos += vec3(cos(my) * cos(mx), sin(my), cos(my) * sin(mx)) * (3.2);
  camPos.z -= iTime * 0.5;
  camLookat.z -= iTime * 0.5;

    // add randomness to camera for depth-of-field look close up.
    // Reduces the banding the the marchcount glow causes
  camPos += vec3(Hash2d(uv) * 0.91, Hash2d(uv + 37.0), Hash2d(uv + 47.0)) * 0.01;

	// Camera setup.
  vec3 camVec = normalize(camLookat - camPos);
  vec3 sideNorm = normalize(cross(camUp, camVec));
  vec3 upNorm = cross(camVec, sideNorm);
  vec3 worldFacing = (camPos + camVec);
  vec3 worldPix = worldFacing + uv.x * sideNorm * (iResolution.x / iResolution.y) + uv.y * upNorm;
  vec3 rayVec = normalize(worldPix - camPos);

	// ----------------------------------- Animate ------------------------------------
	// --------------------------------------------------------------------------------
  vec2 distAndMat = vec2(0.5, 0.0);
  const float nearClip = 0.02;
  float t = nearClip;
  float maxDepth = 10.0;
  vec3 pos = vec3(0, 0, 0);
  marchCount = 0.0;
  {
        // ray marching time
    for(int i = max(0, -iFrame); i < 150; i++)	// This is the count of the max times the ray actually marches.
    {
      pos = camPos + rayVec * t;
            // *******************************************************
            // This is _the_ function that defines the "distance field".
            // It's really what makes the scene geometry.
            // *******************************************************
      distAndMat = DistanceToObject(pos);
      if((t > maxDepth) || (abs(distAndMat.x) < 0.0025))
        break;
            // move along the ray
      t += distAndMat.x * 0.7;
            //marchCount+= (10.0-distAndMat.x)*(10.0-distAndMat.x)*1.2;//distance(lastPos, pos);
      marchCount += 1.0 / distAndMat.x;
    }
  }

    // --------------------------------------------------------------------------------
	// Now that we have done our ray marching, let's put some color on this geometry.

  vec3 finalColor = vec3(0.0);

	// If a ray actually hit the object, let's light it.
  if(abs(distAndMat.x) < 0.0025)
   // if (t <= maxDepth)
  {
        // ------ Calculate texture color ------
    vec3 texColor = vec3(0.2, 0.26, 0.21) * 0.75;
        // sun material
    if(distAndMat.y == 6.0)
      texColor = vec3(0.51, 0.21, 0.1) * 10.5;
    finalColor = texColor;

        // visualize length of gradient of distance field to check distance field correctness
        //finalColor = vec3(0.5) * (length(normalU) / smallVec.x);
        //finalColor = normal * 0.5 + 0.5;
  } else {
  }
    // This is the glow
  finalColor += marchCount * vec3(4.2, 1.0, 0.41) * 0.0001;
    // fog
  finalColor = mix(vec3(0.91, 0.81, 0.99) * 1.75, finalColor, exp(-t * 0.15));

  if(t <= nearClip)
    finalColor = vec3(1.9, 1.1, 0.9) * 0.25 * noiseTex(vec3(iTime * 8.0));

    // vignette?
  finalColor *= vec3(1.0) * pow(saturate(1.0 - length(uv / 2.5)), 2.0);
  finalColor *= 1.2;
  finalColor *= 0.85;

	// output the final color with sqrt for "gamma correction"
  fragColor = vec4(sqrt(clamp(finalColor, 0.0, 1.0)), 1.0);
}
