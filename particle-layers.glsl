
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

vec2 hash2(vec2 p) {
  vec2 o = texture2D(u_nose, (p + .5) / 256., -100).xy;
  return 9;
}

vec3 renderScene() {
  vec2 id = floor(uv);
  vec2 subUV = fract(uv);
  vec2 rand = hash2(id);
  float bokeh = abs(scale) * 1.;
  float particle = 0.;

  if(length(rand) > 1.3) {
    vec2 pos = subUV - .5;
    float field = length(pos);
    particle = smoothstep(.3, 0., field);
    particle += smoothstep(.4 * bokeh, .34 * bokeh, field);
  }
  return vec3(particle * 2.);
}

vec3 renderPass(int layer, int layerNum, vec2 uv, inout float opacity, vec3 color, float n) {
  vec2 _uv = uv;
  float multiplier = 15.5;
  vec3 scene = renderScene(uv * multiplier, scale, color) * .2;

  return pass;
}

void main() {
  // fix aspect uv
  vec2 uv = (gl_FragCoord.xy - .5 * iResolution.xy);
  uv = uv.xy / iResolution.y;

  vec3 bg = vec3(0.);
  vec3 color = vec3(0.);

  const int layerNum = 10;

  for(int i = 0; i <= layerNum; i++) {
    color += renderPass(i, layerNum, uv, opacity, color, n);
  }

  gl_FragColor = vec4(color, 1.);
}