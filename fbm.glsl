
// ref.
// https://thebookofshaders.com/13/?lan=jp
// http://www.iquilezles.org/www/articles/warp/warp.htm

// Get random value
float random(in vec2 st)
{
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define OCTAVES 6
float fbm(in vec2 st) {
  float value = 0.;
  float amp = .5;
  float freq = 0.;

  for(int i = 0; i < OCTAVES; i++) {
    value += amp * noise(st);
    st *= 2.1;
    amp *= .4;
  }
  return value;
}

float pattern(in vec2 p) {
  float f = 0.;
  vec2 q = vec2(
    fbm(p + iTime * .2 + vec2(0.)),
    fbm(p + iTime * .30 + vec2(2.4, 4.8))
  );
  vec2 r = vec2(
    fbm(q + iTime * .3 + 4. * q + vec2(3., 9.)),
    fbm(q + iTime * .2 + 8. * q + vec2(2.4, 8.4))
  );
  f = fbm(p + r * 2. + iTime * .09);
  return f;
}

void main() {
  // fix aspect uv
  vec2 uv = (gl_FragCoord.xy - .5 * iResolution.xy);
  uv = 2. * uv.xy / iResolution.y;

  vec3 color = vec3(0.);
  color += pattern(uv);

  gl_FragColor = vec4(color, 1.);
}