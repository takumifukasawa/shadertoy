
//-----------------------------------------------------------
// fbm ref.
// https://thebookofshaders.com/13/?lan=jp
// http://www.iquilezles.org/www/articles/warp/warp.htm
//-----------------------------------------------------------


const vec3 red = vec3(1., 0., 0.);
const vec3 green = vec3(0., 1., 0.);
const vec3 blue = vec3(0., 0., 1.);
const vec3 orange = vec3(1., .5, .25);
const vec3 cyan = vec3(0., 1., 1.);
const vec3 white = vec3(1., 1., 1.);
const vec3 yellow = vec3(1., 1., 0.);

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
  float amp = .55;
  float freq = 0.;

  for(int i = 0; i < OCTAVES; i++) {
    value += amp * noise(st);
    st *= 2.1;
    amp *= .35;
  }
  return value;
}

float pattern(in vec2 p) {
  float f = 0.;
  vec2 q = vec2(
    fbm(p + iTime * .2 + vec2(0.)),
    fbm(p + iTime * .3 + vec2(2.4, 4.8))
  );
  vec2 r = vec2(
    fbm(q + iTime * .3 + 4. * q + vec2(3., 9.)),
    fbm(q + iTime * .2 + 8. * q + vec2(2.4, 8.4))
  );
  f = fbm(p + r * 2. + iTime * .09);
  return f;
}

vec3 gradient(float v) {
  float steps = 7.;
  float step = 1. / steps;
  vec3 col = green;
  // v: 0 ~ 1/7
  if(v >= 0. && v < step) {
    col = mix(yellow, orange, v * steps);
  // v: 1/7 ~ 2/7
  } else if (v >= step && v < step * 2.) {
    col = mix(orange, red, (v - step) * steps);
  // v: 2/7 ~ 3/7
  } else if (v >= step * 2. && v < step * 3.) {
    col = mix(red, white, (v - step * 2.) * steps);
  // v: 3/7 ~ 4/7
  } else if (v >= step * 3. && v < step * 4.) {
    col = mix(white, cyan, (v - step * 3.) * steps);
  // v: 4/7 ~ 5/7
  } else if (v >= step * 4. && v < step * 5.) {
    col = mix(cyan, blue, (v - step * 4.) * steps);
  // v: 5/7 ~ 6/7
  } else if (v >= step * 5. && v < step * 6.) {
    col = mix(blue, green, (v - step * 5.) * steps);
  }
  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // fix aspect uv
  vec2 uv = (fragCoord.xy - .5 * iResolution.xy);
  uv = 2. * uv.xy / iResolution.y;

  vec3 color = gradient(pattern(uv));

  fragColor = vec4(color, 1.);
}