// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Created by S. Guillitte 2021
#define time -iTime

mat2 R(float a) {
  return mat2(cos(a), sin(a), -sin(a), cos(a));
}

vec3 l = vec3(2.);

//Yonatan clouds/mountains combined field
vec2 field(in vec3 p) {

  float s = 2., e, f, o;
  vec3 q = p;
  for(e = f = p.y; s < 4e2; s /= .6) p.xz *= R(s), q = p, q.x += time * .2 * log(s), e += abs(dot(sin(q.xz * s * .1) / s, l.xz * 2.)) * .9, f += abs(dot(sin(p * s * .15) / s, l)), p.x += time * .0005 * s;
  o = 1. + (f > .001 ? e : -exp(-f * f));
  return vec2(max(o, 0.), min(f, max(e, .07)));
}

vec3 raycast(in vec3 ro, vec3 rd) {
  float t = 2.5;
  float dt = .035;
  vec3 col = vec3(0.);
  for(int i = 0; i < 100; i++) {
    vec2 v = field(ro + t * rd);
    float c = v.x, f = v.y;
    t += dt * f;
    dt *= 1.03;
    col = .95 * col + .015 * vec3(c * c * c, c * c, c);
  }

  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  float t = iTime;
  vec2 q = fragCoord.xy / iResolution.xy;
  vec2 p = -1.0 + 2.0 * q;
  p.x *= iResolution.x / iResolution.y;
  p *= 2.;

    // camera

  vec3 ro = vec3(2.);

  ro.yz *= R(-1.5);
  ro.y += 4.;
  ro.xz *= R(0.1 * t);

  vec3 ta = vec3(0.0, 0.0, 0.0);
  vec3 ww = normalize(ta - ro);
  vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
  vec3 vv = normalize(cross(uu, ww));
  vec3 rd = normalize(p.x * uu + p.y * vv + 4.0 * ww);
  ro.x -= t * .4;

	// raymarch

  vec3 col = raycast(ro, rd);

	// shade

  col = .5 * (log(1. + col));
  col = clamp(col, 0., 1.);
  fragColor = vec4(col, 1.0);

}
