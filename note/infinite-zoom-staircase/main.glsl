/*

    Infinite 3D Zoom
    ----------------

	This is just a dressed up version of a basic cube zooming animation.
    The animation portion was pretty straight forward, so took no time at
    all. However, I spent way too long dressing it up to a stage where I
    was only mildy satisfied with the result. The original had a nicer
    reflective pass, but I couldn't afford to use it... You can't win them
    all, but if you like drab brown-looking one pass scenes, then you'll
    love this. :D Oh well, post and move on, as they say. :)

    For those not familiar with the infinite zoom illusion, it's a pretty
    simple concept: In the 2D sense, you produce a miniscule object then
    expand its size to some maximum before snapping it back to its original
    minimum size (the fract funciton does that). On its own, it's not very
    illusory, however, if you do the same with multiple objects at various
    stages in the expansion process, your mind gets tricked into believing
    that a camera is zooming toward the central object -- In reality, the
    camera is effectively stationary. This particular example is just a 3D
    extension on the aforementioned with various tweaks.

    Anyway, there are better zoom examples than this on Shadertoy, so if
    that kind of thing interests you, search "infinite zoom" or something
    along those lines. I have some 2D zooming animations that I might post
    at a later date.



	Other examples:

    // You can't list zoom examples without referencing this.
    // It's everywhere these days.
    Infinite KIFS Zoom - andyalias
    https://www.shadertoy.com/view/4sS3WV

    // Golden spiral zoom. Typical simple and stylish example
    // by IQ.
    Golden Ratio and Spiral - iq
    https://www.shadertoy.com/view/fslyW4

    // One of many of KilledByAPixel's really nice zoom examples.
    Infinity Matrix - KilledByAPixel
    https://www.shadertoy.com/view/Md2fRR

    // Fabrice has a few examples. This is his most recent.
    infinite zoom in rolling squares - FabriceNeyret2
    https://www.shadertoy.com/view/fl2Bzm

    // Awesome example -- Requires a strong GPU.
    Bloom [skull] - tdhooper
    https://www.shadertoy.com/view/WdScDG

    // Oldschool bump mapped zoom effect, written years ago.
    Quasi Infinite Zoom Voronoi  - Shane
	https://www.shadertoy.com/view/XlBXWw

*/

// No forced unroll.
#define ZERO min(0, iFrame)

// Max ray distance.
#define FAR 20.

// Scene object ID to separate the mesh object from the terrain.
int objID;
vec4 vID;

// Standard 2D rotation formula.
mat2 rot2(in float a) {
  float c = cos(a), s = sin(a);
  return mat2(c, -s, s, c);
}

// IQ's vec2 to float hash.
float hash21(vec2 p) {
  return fract(sin(dot(p, vec2(27.609, 57.583))) * 43758.5453);
}

// Tri-Planar blending function. Based on an old Nvidia tutorial by Ryan Geiss.
vec3 tex3D(sampler2D t, in vec3 p, in vec3 n) {

  n = max(abs(n) - .2, .001); // max(abs(n), 0.001), etc.
    //n /= dot(n, vec3(.8));
  n /= length(n);

  vec3 tx = texture(t, p.yz).xyz;
  vec3 ty = texture(t, p.zx).xyz;
  vec3 tz = texture(t, p.xy).xyz;

    // Textures are stored in sRGB (I think), so you have to convert them to linear space
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
  return mat3(tx * tx, ty * ty, tz * tz) * n;
}

// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h) {

    //vec2 w = vec2( sdf, abs(pz) - h );
  	//return min(max(w.x, w.y), 0.) + length(max(w, 0.));

    // Slight rounding. A little nicer, but slower.
  const float sf = .005;
  vec2 w = vec2(sdf, abs(pz) - h) + sf;
  return min(max(w.x, w.y), 0.) + length(max(w, 0.)) - sf;

}

// IQ's signed box formula.
float sBoxS(in vec2 p, in vec2 b, in float sf) {

  vec2 d = abs(p) - b + sf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - sf;
}

vec4 gS;
mat2 gR;
float map(vec3 p) {

    // Wall.
  float wall = -p.z + 32.;

    // Render 16 objects expanding from a minimum size to a maximum
    // one and back again at separate linear intervals. The result is
    // an infinite zoom illusion.
  const int N = 16;
  float L = float(N);
  float minSize = .001;

  float d = 1e5;
  gS = vec4(1e5);

    // There are probably faster methods out there, but this gets the
    // job done. Apologies for anyone with slower machines.
  for(int i = 0; i < N; i++) {

        // N objects spread out at linear time varying intervals.
    float s = fract((float(i) + iTime) / L);
        // Adding linear XY rotation for a bit of extra visual interest.
        // You can leave it out, if you'd prefer the boxes to look more static.
    mat2 r = rot2(s * 5.);

        // Exponential size increase. Boxes on the outside are larger. When
        // "i" is zero, "s" is equal to the minimum size. By the way, you can
        // increase iteration size in other ways (exp(x) will work too), but
        // I like doubling each iteration.
    s = exp2(s * L) * minSize; // exp2(x) = pow(2., x);

        // Rotate the XY plane.
    vec2 q = p.xy * r;

        // Rounded box.
    float box = sBoxS(q, vec2(s), .2 * s * 1.);//vec2(sf*sf)//
        // Circular box option... Otherwise known as a circle. :D
        // You'd need to make changes to the bump and texturing functions.
        //float box = length(q) - s;

        // Extrude -- Inner and outer.
    float di = opExtrusion(box + .0 * s, p.z - s, (.25));//sf*sf
    float di2 = opExtrusion(abs(box + .04 * s) - .04 * s, p.z - s, (.25 + .025));//sf*sf
        //di2 += smoothstep(0., .5, cos(box*80./s + .0))*.01*s;
    di = min(di, di2);

        // Record the minimum extruded box distance.
    if(di < d) {

      d = di;
      gS = vec4(s, q, i);
      gR = r;

    }
  }

    // Overall object ID.
  vID = vec4(d, wall, 1e5, 1e5);

    // Combining the wall with the extruded object.
  return min(d, wall);

}

// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd) {

    // Overall ray distance and scene distance.
  float t = 0., d;

  for(int i = ZERO; i < 80; i++) {

    d = map(ro + rd * t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
    if(abs(d) < .001 || t > FAR)
      break; // Alternative: 0.001*max(t*.25, 1.), etc.

        //t += i<32? d*.75 : d;
    t += d * .9;
  }

  return min(t, FAR);
}

// Standard normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p, float t) {

  const vec2 e = vec2(.001, 0);

    //vec3 n = normalize(vec3(map(p + e.xyy) - map(p - e.xyy),
    //map(p + e.yxy) - map(p - e.yxy),	map(p + e.yyx) - map(p - e.yyx)));

    // This mess is an attempt to speed up compiler time by contriving a break... It's
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
  float sgn = 1.;
  float mp[6];
  vec3[3] e6 = vec3[3](e.xyy, e.yxy, e.yyx);
  for(int i = ZERO; i < 6; i++) {
    mp[i] = map(p + sgn * e6[i / 2]);
    sgn = -sgn;
    if(sgn > 2.)
      break; // Fake conditional break;
  }

  return normalize(vec3(mp[0] - mp[1], mp[2] - mp[3], mp[4] - mp[5]));
}

// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with limited
// iterations is impossible... However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k) {

    // More would be nicer. More is always nicer, but not really affordable...
    // Not on my slow test machine, anyway.
  const int maxIterationsShad = 32;

  ro += n * .0015;
  vec3 rd = lp - ro; // Unnormalized direction ray.

  float shade = 1.;
  float t = 0.;//.0015; // Coincides with the hit condition in the "trace" function.
  float end = max(length(rd), .0001);
    //float stepDist = end/float(maxIterationsShad);
  rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest
    // number to give a decent shadow is the best one to choose.
  for(int i = ZERO; i < maxIterationsShad; i++) {

    float d = map(ro + rd * t);
    shade = min(shade, k * d / t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), dist += clamp(h, .01, stepDist), etc.
    t += clamp(d, .01, .15);

        // Early exits from accumulative distance function calls tend to be a good thing.
    if(d < 0. || t > end)
      break;
  }

    // Sometimes, I'll add a constant to the final shade value, which lightens the shadow a bit --
    // It's a preference thing. Really dark shadows look too brutal to me. Sometimes, I'll add
    // AO also just for kicks. :)
  return max(shade, 0.);
}

// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n) {
  float sca = 2., occ = 0.;
  for(int i = ZERO; i < 5; i++) {

    float hr = float(i + 1) * .125 / 5.;
    float d = map(p + n * hr);
    occ += (hr - d) * sca;
    sca *= .85;
  }

  return clamp(1. - occ, 0., 1.);

}

///////

#define STATIC

// vec2 to vec2 hash.
vec2 hash22(vec2 p) {

    // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked
    // amalgamation I put together, based on a couple of other random algorithms I've
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
  float n = sin(dot(p, vec2(27, 57)));

    #ifdef STATIC
  return fract(vec2(262144, 32768) * n);
    #else
    // Animated.
  p = fract(vec2(262144, 32768) * n);
    // Note the ".45," insted of ".5" that you'd expect to see. When edging, it can open
    // up the cells ever so slightly for a more even spread. In fact, lower numbers work
    // even better, but then the random movement would become too restricted. Zero would
    // give you square cells.
  return sin(p * 6.2831853 + iTime / 2.) * .5 + .5;
    #endif
}

/*
// Commutative smooth minimum function. Provided by Tomkh and taken from
// Alex Evans's (aka Statix) talk:
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin(float a, float b, float r)
{
   float f = max(0., 1. - abs(b - a)/r);
   return min(a, b) - r*.25*f*f;
}
*/

/*
// IQ's polynomial-based smooth minimum function.
vec3 smin( vec3 a, vec3 b, float k ){

    vec3 h = clamp(.5 + .5*(b - a)/k, 0., 1.);
    return mix(b, a, h) - k*h*(1. - h);
}
*/

// IQ's exponential-based smooth minimum function. Unlike the polynomial-based
// smooth minimum, this one is associative and commutative.
float sminExp(float a, float b, float k) {
  float res = exp(-k * a) + exp(-k * b);
  return -log(res) / k;
}

// The is a variation on a regular 2-pass Voronoi traversal that produces a Voronoi
// pattern based on the interior cell point to the nearest cell edge (as opposed
// to the nearest offset point). It's a slight reworking of Tomkh's example, which
// in turn, is based on IQ's original example. The links are below:
//
// On a side note, I have no idea whether a faster solution is possible, but when I
// have time, I'm going to try to find one anyway.
//
// Voronoi distances - iq
// https://www.shadertoy.com/view/ldl3W8
//
// Here's IQ's well written article that describes the process in more detail.
// https://iquilezles.org/articles/voronoilines
//
// Faster Voronoi Edge Distance - tomkh
// https://www.shadertoy.com/view/llG3zy

float vAng;

vec2 cellID; // Individual Voronoi cell IDs.

vec3 Voronoi(in vec2 p) {

    // One of Tomkh's snippets that includes a wrap to deal with
    // larger numbers, which is pretty cool.

#if 1
    // Slower, but handles big numbers better.
  vec2 n = floor(p);
  p -= n;
  vec2 h = step(.5, p) - 1.5;
  n += h;
  p -= h;
#else
  vec2 n = floor(p - 1.);
  p -= n;
#endif

    // Storage for all sixteen hash values. The same set of hash values are
    // reused in the second pass, and since they're reasonably expensive to
    // calculate, I figured I'd save them from resuse. However, I could be
    // violating some kind of GPU architecture rule, so I might be making
    // things worse... If anyone knows for sure, feel free to let me know.
    //
    // I've been informed that saving to an array of vectors is worse.
    //vec2 svO[3];

    // Individual Voronoi cell ID. Used for coloring, materials, etc.
  cellID = vec2(0); // Redundant initialization, but I've done it anyway.

    // As IQ has commented, this is a regular Voronoi pass, so it should be
    // pretty self explanatory.
    //
    // First pass: Regular Voronoi.
  vec2 mo, o;

    // Minimum distance, "smooth" distance to the nearest cell edge, regular
    // distance to the nearest cell edge, and a line distance place holder.
  float md = 8., md2, lMd = 8., lMd2 = 8., lnDist, d;

  for(int j = ZERO; j < 3; j++) {
    for(int i = ZERO; i < 3; i++) {

      o = vec2(i, j);
      o += hash22(n + o) - p;
        // Saving the hash values for reuse in the next pass. I don't know for sure,
        // but I've been informed that it's faster to recalculate the had values in
        // the following pass.
        //svO[j*3 + i] = o;

        // Regular squared cell point to nearest node point.
      d = dot(o, o);

      if(d < md) {

        md2 = md;
        md = d;  // Update the minimum distance.
            // Keep note of the position of the nearest cell point - with respect
            // to "p," of course. It will be used in the second pass.
        mo = o;
        cellID = vec2(i, j) + n; // Record the cell ID also.

        vAng = atan(o.y, o.x);
      } else if(d < md2) {
        md2 = d;

      }

    }
  }

    // Second pass: Distance to closest border edge. The closest edge will be one of the edges of
    // the cell containing the closest cell point, so you need to check all surrounding edges of
    // that cell, hence the second pass... It'd be nice if there were a faster way.
  for(int j = ZERO; j < 3; j++) {
    for(int i = ZERO; i < 3; i++) {

        // I've been informed that it's faster to recalculate the hash values, rather than
        // access an array of saved values.
      o = vec2(i, j);
      o += hash22(n + o) - p;
        // I went through the trouble to save all sixteen expensive hash values in the first
        // pass in the hope that it'd speed thing up, but due to the evolving nature of
        // modern architecture that likes everything to be declared locally, I might be making
        // things worse. Who knows? I miss the times when lookup tables were a good thing. :)
        //
        //o = svO[j*3 + i];

        // Skip the same cell... I found that out the hard way. :D
      if(dot(o - mo, o - mo) > .00001) {

            // This tiny line is the crux of the whole example, believe it or not. Basically, it's
            // a bit of simple trigonometry to determine the distance from the cell point to the
            // cell border line. See IQ's article for a visual representation.
        lnDist = dot(0.5 * (o + mo), normalize(o - mo));

            // Abje's addition. Border distance using a smooth minimum. Insightful, and simple.
            //
            // On a side note, IQ reminded me that the order in which the polynomial-based smooth
            // minimum is applied effects the result. However, the exponentional-based smooth
            // minimum is associative and commutative, so is more correct. In this particular case,
            // the effects appear to be negligible, so I'm sticking with the cheaper polynomial-based
            // smooth minimum, but it's something you should keep in mind. By the way, feel free to
            // uncomment the exponential one and try it out to see if you notice a difference.
            //
            // // Polynomial-based smooth minimum.
            //lMd = smin(lMd, lnDist, .1);
            //
            // Exponential-based smooth minimum. By the way, this is here to provide a visual reference
            // only, and is definitely not the most efficient way to apply it. To see the minor
            // adjustments necessary, refer to Tomkh's example here: Rounded Voronoi Edges Analysis -
            // https://www.shadertoy.com/view/MdSfzD
        lMd = sminExp(lMd, lnDist, 15.);

            // Minimum regular straight-edged border distance. If you only used this distance,
            // the web lattice would have sharp edges.
        lMd2 = min(lMd2, lnDist);

      }

    }
  }

    // Return the smoothed and unsmoothed distance. I think they need capping at zero... but
    // I'm not positive.
  return max(vec3(lMd, lMd2, md2 - md), 0.);
}
//////

// Surface bump function..
float bumpSurf3D(in vec3 p, in vec3 n) {

    // Applying a Voronoi pattern.
    // Globals from the map function.
  vec4 svS = gS; // Texture sizing factor.
  mat2 svR = gR; // Rotation matrix.

  p.xy *= svR / svS.x;
  n.xy *= svR;

  float s = svS.x;
  p.z -= s * .9;

  float c = 0.;

  vec3 v = Voronoi(p.xy * 8.);

  float vor = v.y;

    // Ignore the borders.
  float sq = sBoxS(p.xy, vec2(1. - .08), .2 / 1.6 * 1.); // See "map" function.
  if(n.z < -.25 && sq < .0) {

    c = vor;
  }

  return c * svS.x;

}

// Standard function-based bump mapping routine: This is the cheaper four tap version. There's
// a six tap version (samples taken from either side of each axis), but this works well enough.
vec3 doBumpMap(in vec3 p, in vec3 n, float bumpfactor) {

    // Larger sample distances give a less defined bump, but can sometimes lessen the aliasing.
  const vec2 e = vec2(.001, 0);

    // This utter mess is to avoid longer compile times. It's kind of
    // annoying that the compiler can't figure out that it shouldn't
    // unroll loops containing large blocks of code.
  mat4x3 p4 = mat4x3(p, p - e.xyy, p - e.yxy, p - e.yyx);

  vec4 b4;
  for(int i = ZERO; i < 4; i++) {
    b4[i] = bumpSurf3D(p4[i], n);
    if(n.x > 1e5)
      break; // Fake break to trick the compiler.
  }

    // Gradient vector: vec3(df/dx, df/dy, df/dz);
  vec3 grad = (b4.yzw - b4.x) / e.x;

    // Six tap version, for comparisson. No discernible visual difference, in a lot of cases.
    //vec3 grad = vec3(bumpSurf3D(p - e.xyy) - bumpSurf3D(p + e.xyy),
    //                 bumpSurf3D(p - e.yxy) - bumpSurf3D(p + e.yxy),
    //                 bumpSurf3D(p - e.yyx) - bumpSurf3D(p + e.yyx))/e.x*.5;

    // Adjusting the tangent vector so that it's perpendicular to the normal. It's some kind
    // of orthogonal space fix using the Gram-Schmidt process, or something to that effect.
  grad -= n * dot(n, grad);

    // Applying the gradient vector to the normal. Larger bump factors make things more bumpy.
  return normalize(n + grad * bumpfactor);

}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {

    // Screen coordinates.
  vec2 uv = (fragCoord - iResolution.xy * .5) / iResolution.y;

	// Camera Setup.
  vec3 ro = vec3(0, -.5, -1); // Camera position, doubling as the ray origin.
  vec3 lk = ro + vec3(.03 * cos(iTime / 2.) * 0., .125, .25);//vec3(0, -.25, iTime);  // "Look At" position.

    // Light positioning. One is just in front of the camera, and the other is in front of that.
  vec3 lp = ro + vec3(1, .5, -1);// Put it a bit in front of the camera.

    // Using the above to produce the unit ray-direction vector.
  float FOV = .75; // FOV - Field of view.
  vec3 fwd = normalize(lk - ro);
  vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x));
    // "right" and "forward" are perpendicular, due to the dot product being zero. Therefore, I'm
    // assuming no normalization is necessary? The only reason I ask is that lots of people do
    // normalize, so perhaps I'm overlooking something?
  vec3 up = cross(fwd, rgt);

    // rd - Ray direction.
    //vec3 rd = normalize(fwd + FOV*uv.x*rgt + FOV*uv.y*up);
  vec3 rd = normalize(uv.x * rgt + uv.y * up + fwd / FOV);

    // Swiveling the camera for extra motion sickness. :)
  rd.xy *= rot2(sin(iTime / 2.) / 16.);
  rd.xz *= rot2(sin(iTime) / 32.);

    // Raymarch to the scene.
  float t = trace(ro, rd);

    // Global scaling and rotation matrix.
  vec4 svS = gS;
  mat2 svR = gR;

    // Obtaining the object ID.
  objID = vID[0] < vID[1] ? 0 : 1;
    /*
    objID = 0;
    float obD = vID[0];
    for(int i = 0; i<4; i++){
        if(vID[i]<obD){ obD = vID[i]; objID = i; }
    }
    */

    // Initiate the scene color to black.
  vec3 col = vec3(0);

	// The ray has effectively hit the surface, so light it up.
  if(t < FAR) {

    	// Surface position and surface normal.
    vec3 sp = ro + rd * t;
	    //vec3 sn = getNormal(sp, edge, crv, ef, t);
    vec3 sn = getNormal(sp, t);

    vec3 sn0 = sn; // Normal with no bump.

    if(objID == 0)
      sn = doBumpMap(sp, sn, .5);///(1. + t/FAR*1.)

            	// Light direction vector.
    vec3 ld = lp - sp;

        // Distance from respective light to the surface point.
    float lDist = max(length(ld), .001);

    	// Normalize the light direction vector.
    ld /= lDist;

        // Shadows and ambient self shadowing.
    float sh = softShadow(sp, lp, sn, 8.);
    float ao = calcAO(sp, sn); // Ambient occlusion.

	    // Light attenuation, based on the distances above.
    float atten = 1. / (1. + lDist * lDist * .05);

    	// Diffuse lighting.
    float diff = max(dot(sn, ld), 0.);
        //diff = pow(diff, 4.)*2.; // Ramping up the diffuse.

    	// Specular lighting.
    float spec = pow(max(dot(reflect(ld, sn), rd), 0.), 32.);

	    // Fresnel term. Good for giving a surface a bit of a reflective glow.
    float fre = pow(clamp(1. + dot(sn, rd), 0., 1.), 5.);

		// Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
        // so could almost be aproximated by a constant, but I prefer it. Here, it's being
        // used to give a hard clay consistency... It "kind of" works.
		//float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
		//float freS = mix(.2, 1., Schlick);  //F0 = .2 - Glass... or close enough.

        // Obtaining the texel color.
    vec3 texCol;

        // Object coloring.

    if(objID == 0) { // The extruded rounded boxes.

            // Coordinatges.
      vec3 txP = sp;
      vec3 txN = sn;

            // XY rotation and scaling.
      txP.xy *= svR / svS.x;
      txN.xy *= svR;

            //txP.xy -= hash22(vec2(svS.w, svS.w*57.));
      float s = pow(svS.x, 1.);
      txP.z -= s * .9;// - hash21(vec2(svS.w, svS.w*113.));//See distance function.

            // Texture.
      vec3 tx = tex3D(iChannel0, txP, txN);
      texCol = .05 + tx * 1.5;

            // Alternative coloring.
            //texCol = mix(texCol, vec3(dot(texCol, vec3(.299, .587, .114))), mod(svS.w, 2.)*.35);
            // No texture.
            //texCol = vec3(.6);

            // Voronoi pattern.
      vec3 v = Voronoi(txP.xy * vec2(8));

      float vor = v.y;
      float sq = sBoxS(txP.xy, vec2(1. - .08), .2 / 1.6 * 1.); // See "map" function.
      if(sn0.z < -.5 && sq < .0) {

                // Greyscale toning.
        vec3 svCol = texCol;
        float gr = dot(texCol, vec3(.299, .587, .114));
        texCol = mix(texCol, vec3(gr), .15);

                // Color application.
                //vec3 iCol = (.5 + .45*cos(6.2831*svS.w/8. + vec3(0, 1, 2)*1.))*3.;
        vec3 iCol = vec3(2);
        vec3 iCol2 = (iCol + vec3(.1)) * 2.;
        texCol = mix(texCol * iCol, texCol * .25, 1. - smoothstep(0., .1, vor - .2));
        texCol = mix(texCol, svCol * iCol2, 1. - smoothstep(0., .04, abs(vor - .2 + .03) - .03));
        texCol = mix(texCol, svCol * iCol2 * 0., 1. - smoothstep(0., .04, abs(vor) - .01));

      } else {

               // Darker borders.
        texCol *= .5;
               // Lightening the edges.
        if(sn0.z < -.25) {
          texCol = mix(texCol, texCol * 3., 1. - smoothstep(0., .005, -(abs(sq - .04) - .03)));
        }
      }

    } else { //  Wall.

      texCol = vec3(0);
    }

        // Combining the above terms to procude the final color.
    col = texCol * (diff * sh + .2 + vec3(.5, .7, 1) * spec * sh * 1.);

        // Fake Fresnel reflections.
    vec3 refl = reflect(rd, sn);
    vec3 refTex = texture(iChannel1, refl).xyz;
    refTex *= refTex;
    col = mix(col, (col + .25) * refTex * (sh + .2) * 4., mix(.05, .35, fre));//*refTex*sh;

        // Shading.
    col *= ao * atten;

  }

    // Background fog.
  col = mix(col, vec3(.025, .015, .01), smoothstep(0., .99, t / FAR));

    // Rought gamma correction.
  fragColor = vec4(pow(max(col, 0.), vec3(1. / 2.2)), 1);

}
