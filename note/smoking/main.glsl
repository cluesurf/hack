// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Created by S. Guillitte 2015
#define time iTime

vec2 cmul(vec2 a, vec2 b) {
  return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}
vec2 csqr(vec2 a) {
  return vec2(a.x * a.x - a.y * a.y, 2. * a.x * a.y);
}

mat2 rot(float a) {
  return mat2(cos(a), sin(a), -sin(a), cos(a));
}

float zoom = 1.;

mat2 mr;

float field(in vec3 p) {

  float res = 0.;

  vec3 c = p;
  c.xz *= mr;
  for(int i = 0; i < 10; ++i) {
    p = 1.1 * abs(p) / dot(p, p) - .6;
    p.yz = csqr(p.yz);

    res += exp(-6. * abs(dot(p, c)) * dot(p.xz, p.xz));

  }
  return res / 2.;
}

vec3 raycast(in vec3 ro, vec3 rd) {
  float t = 8.0 * zoom;
  float dt = .05 * zoom;
  vec3 col = vec3(0.);
  for(int i = 0; i < 64; i++) {

    float c = field(ro + t * rd);
    t -= dt * (.3 + c * c);
    col = .92 * col + .19 * vec3(c, c * c, c * c * c);

  }

  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  mr = rot(time * .2);
  vec2 q = fragCoord.xy / iResolution.xy;
  vec2 p = -1.0 + 2.0 * q;
  p.x *= iResolution.x / iResolution.y;
  vec2 m = vec2(0.);
  if(iMouse.z > 0.0)
    m = iMouse.xy / iResolution.xy * 3.14;
  m -= .5;

    // camera

  vec3 ro = zoom * vec3(4.);
  ro.yz *= rot(m.y);
  ro.xz *= rot(m.x + 0.1 * time);
  vec3 ta = vec3(0.0, 0.0, 0.0);
  vec3 ww = normalize(ta - ro);
  vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
  vec3 vv = normalize(cross(uu, ww));
  vec3 rd = normalize(p.x * uu + p.y * vv + 4.0 * ww);

	// raymarch
  vec3 col = raycast(ro, rd);

	// shade

  col = 1. - .5 * (log(1. + col));
  col = clamp(col, 0., 1.);
  fragColor = vec4((col), 1.0);

}
