
// https://codepen.io/shubniggurath/pen/XZJozp?editors=1000

// ref.
// https://thebookofshaders.com/13/?lan=jp
// http://www.iquilezles.org/www/articles/warp/warp.htm

// Get random value
vec2 random(vec2 st, float seed) {
  st = vec2(
    dot(st,vec2(127.1,311.7)),
    dot(st,vec2(269.5,183.3))
  );
  return -1.0 + 2.0 * fract(sin(st)*seed);
}

float noise (in vec2 st, float seed) {
  vec2 i = floor(st);
  vec2 f = fract(st);

  // Four corners in 2D of a tile
  vec2 a = random(i, seed);
  vec2 b = random(i + vec2(1.0, 0.0), seed);
  vec2 c = random(i + vec2(0.0, 1.0), seed);
  vec2 d = random(i + vec2(1.0, 1.0), seed);

  vec2 u = f * f * (3.0 - 2.0 * f);

  return mix(
    mix(
      dot(
        random(i + vec2(0., 0.), seed),
        f - vec2(0., 0.)
      ),
      dot(
        random(i + vec2(1., 0.), seed),
        f - vec2(1., 0.)
      ),
      u.x
    ),
    mix(
      dot(
        random(i + vec2(0., 1.), seed),
        f - vec2(0., 1.)
      ),
      dot(
        random(i + vec2(1., 1.), seed),
        f - vec2(1., 1.)
      ),
      u.x
    ),
    u.y
  );
}

#define OCTAVES 6
float fbm(in vec2 st, float seed) {
  float value = 0.;
  float amp = .5;
  float freq = 0.;
  vec2 shift = vec2(100.);

  mat2 rot = mat2(
    cos(.5), sin(.5),
    -sin(.5), cos(.5)
  );

  for(int i = 0; i < OCTAVES; ++i) {
    value += amp * noise(st, seed);
    st = rot * st * 2. + shift;
    amp *= .4;
  }
  return value + .4;
}

float pattern(in vec2 p, float seed, float time, inout vec2 q, inout vec2 r) {
  float f = 0.;
  q = vec2(
    fbm(p + vec2(0.), seed),
    fbm(p + vec2(5.2, 1.3), seed)
  );
  r = vec2(
    fbm(p + 4. * q + vec2(1.7 - time / 2., 9.2), seed),
    fbm(p + 4. * q + vec2(8.3 - time / 2., 2.8), seed)
  );
  f = fbm(p + r * 4., seed);
  return f;
}

void main() {
  // fix aspect uv
  vec2 uv = (gl_FragCoord.xy - .5 * iResolution.xy);
  uv = 2. * uv.xy / iResolution.y;

  const float noiseSize = 3.;
  const float intensity = 20.;
  const float reflectionIntensity = 4.;
  float seed = 43758.5453123;

  vec2 _uv = uv * noiseSize;
  vec2 q = vec2(0.);
  vec2 r = vec2(0.);
  float pattern = pattern(_uv, seed, iTime / 2., q, r);
  uv += (.5 - pattern) / intensity;

  // sphere
  float len = length(uv) + .01;
  float field = len + .05 * (-1. * iTime / 5.);

  float ripple;
  ripple = sin(field * 80.) * .5 * r.x * pattern + 1.;
  ripple += smoothstep(.2, .0, len);
  ripple *= smoothstep(.3, .9, clamp(1. - len * 1.5, 0., 1.));
  ripple -= fract(ripple * 8.) / 100.;

  vec3 color = vec3(.2, .3, .4);
  color += ripple * length(r) * vec3(1., 1., .8);
  color += (1. - pattern * reflectionIntensity * .5)
    * smoothstep(0., .7, clamp(1. - len * 1.5, 0., 1.)) * vec3(-.2, -.1, 0.);
  color += (1. - pattern * reflectionIntensity * 2.)
    * smoothstep(.5, .9, clamp(1. - len * 1.5, 0., 1.)) * vec3(-.2, -.1, 0.);

  // color = vec3(ripple);

  gl_FragColor = vec4(color, 1.);
}