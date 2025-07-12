// zoom locations. comment this one and uncomment one of the others to zoom somewhere else
// needle
const vec2 MINIBROT_C = vec2(-1.98542425, 0.0);
const vec2 MINIBROT_SCALE = vec2(5.81884941e-5, 0.0);
const vec2 MINIBROT_A = vec2(-161.347726, 0.0);
const float MINIBROT_PERIOD = 5.0;

// seahorse valley 1
/*const vec2 MINIBROT_C = vec2(-0.862612214,-0.274371722);
const vec2 MINIBROT_SCALE = vec2(-5.33653763e-6,-1.60082654e-5);
const vec2 MINIBROT_A = vec2(187.960106,92.5553918);
const float MINIBROT_PERIOD = 12.0;*/

// seahorse valley 2
/*const vec2 MINIBROT_C = vec2(-0.722551290,-0.260810603);
const vec2 MINIBROT_SCALE = vec2(1.73516282e-5,-6.24633482e-6);
const vec2 MINIBROT_A = vec2(157.460179,-16.4403340);
const float MINIBROT_PERIOD = 21.0;*/

// elephant valley
/*const vec2 MINIBROT_C = vec2(0.34462359,0.0564018310);
const vec2 MINIBROT_SCALE = vec2(-2.21366831e-6,8.05314001e-7);
const vec2 MINIBROT_A = vec2(-113.398177,231.589991);
const float MINIBROT_PERIOD = 17.0;*/

// alternating whatever
/*const vec2 MINIBROT_C = vec2(-0.162415772,-1.04133681);
const vec2 MINIBROT_SCALE = vec2(-1.07141152e-6,1.02473337e-6);
const vec2 MINIBROT_A = vec2(30.7304447,-1057.92453);
const float MINIBROT_PERIOD = 24.0;*/

const float MINIBROT_R = 8.0;
const float MINIBROT_R2 = 32.0;

const int ITER = 500;
const float BAILOUT = 32.0;

vec2 cmul(vec2 a, vec2 b) {
  return vec2(dot(a, vec2(1.0, -1.0) * b), dot(a, b.yx));
}

vec2 cdiv(vec2 a, vec2 b) {
  return vec2(dot(a, b), dot(a.yx, vec2(1.0, -1.0) * b)) / dot(b, b);
}

// sort of a minimal example of an algorithm I've been working on for a while now.
// this version only supports zooming into the same minibrot again and again, but
// there's really nothing stopping one from changing the parameters for each minibrot,
// and adjusting them automatically as one explores the fractal.
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  float t = iTime * iTime / (iTime + 1.0);
  float s = -log(length(MINIBROT_SCALE));
  int n = int(ceil(t / s));
  float zoom = exp(-(t - s * float(n)));
  float theta = float(n) * atan(MINIBROT_SCALE.y, MINIBROT_SCALE.x);
  vec2 C = cmul(MINIBROT_C, cdiv(vec2(1.0, 0.0), vec2(1.0, 0.0) - MINIBROT_SCALE));
  vec2 dc = vec2(cos(theta), -sin(theta)) * 10.0 * zoom / length(iResolution);
  vec2 c = C + cmul(dc, vec2(1.0, -1.0) * (fragCoord - iResolution.xy * 0.5));
  while(n > 0 && dot(c - MINIBROT_C, c - MINIBROT_C) > MINIBROT_R2) {
    c = MINIBROT_C + cmul(c, MINIBROT_SCALE);
    dc = cmul(dc, MINIBROT_SCALE);
    n--;
  }

  vec2 z = vec2(0.0);
  vec2 dz = dc;
  int i = 0;
  float i2 = 0.0;
  float escapeRadius = n == 0 ? BAILOUT : MINIBROT_R;
  while(i < ITER) {
    if(dot(z, z) > escapeRadius) {
      if(n == 0) {
        break;
      } else {
        z = cdiv(z, MINIBROT_A);
        dz = cdiv(dz, MINIBROT_A);
        c = MINIBROT_C + cmul(c, MINIBROT_SCALE);
        dc = cmul(dc, MINIBROT_SCALE);
        n--;
        i2 *= MINIBROT_PERIOD;
        float escapeRadius = n == 0 ? BAILOUT : MINIBROT_R;
      }
    }
    dz = 2.0 * cmul(dz, z) + dc;
    z = cmul(z, z) + c;
    i++;
    i2++;
  }
    // mixture of distance estimation and logarithmic coloring. sadly, both break after a while.
  float d = !(i < ITER) ? 0.0 : sqrt(dot(z, z) / dot(dz, dz)) * 0.5 * log(dot(z, z));
  fragColor = vec4(vec3((1.0 - d) * (0.5 + 0.5 * cos(log(1.0 + i2 * 2.0e-5)))), 1.0);
}
