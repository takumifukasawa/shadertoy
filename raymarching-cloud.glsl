
// https://qiita.com/edo_m18/items/cbba0cc4e33a5aa3be55

#define EPS 0.0001
#define PI 3.14159265359
#define USE_LIGHT 0

precision highp float;

const int maxIterations = 64;
const float stepScale = 1.;
const float stopThreshold = .005;

struct RayMarchOutput {
  float dist;
  vec4 color;
};

mat3 m = mat3(
  0., .8, .6,
  -.8, .36, -.48,
  -.6, -.48, .64
);

float hash(float n) {
  return fract(sin(n) * 43758.5453);
}

float noise(in vec3 x) {
  vec3 p = floor(x);
  vec3 f = fract(x);

  f = f * f * (3. - 2. * f);
  float n = p.x + p.y * 57. + 113. * p.z;
  return mix(
    mix(
      mix(hash(n + 0.), hash(n + 1.), f.x),
      mix(hash(n + 57.), hash(n + 58.), f.x),
      f.y
    ),
    mix(
      mix(hash(n + 113.), hash(n + 114.), f.x),
      mix(hash(n + 170.), hash(n + 171.), f.x),
      f.y
    ),
    f.z
  );
}

float fbm(vec3 p) {
  float f;
  f = .5 * noise(p); p = m * p * 2.02;
  f += .25 * noise(p); p = m * p * 2.03;
  f += .125 * noise(p);
  return f;
}

float sphere(vec3 p, float size) {
  return length(p) - size;
}

float scene(vec3 z) {
  return .1 - length(z) * .05 + fbm(z * .3);
}

vec3 getNormal(vec3 p) {
  const float e = EPS;
  return normalize(vec3(
    scene(p + vec3(e,   0.0, 0.0)) - scene(p + vec3(-e,  0.0, 0.0)),
    scene(p + vec3(0.0,   e, 0.0)) - scene(p + vec3(0.0,  -e, 0.0)),
    scene(p + vec3(0.0, 0.0,   e)) - scene(p + vec3(0.0, 0.0,  -e))
  ));
}

RayMarchOutput rayMarching(vec3 origin, vec3 dir, float start, float end) {
  float sceneDist = 0.;
  float rayDepth = start;

  float T = 1.;
  float absorption = 100.;
  vec4 color = vec4(0.);

  float zMax = 40.;
  float zStep = zMax / float(maxIterations);

  for(int i = 0; i < maxIterations; i++) {
    sceneDist = scene(origin + dir * rayDepth);
    // if((sceneDist < stopThreshold) || (rayDepth >= end)) {
    //   break;
    // }
    if(sceneDist > 0.) {
      float tmp = sceneDist / float(maxIterations);
      T *= 1. - (tmp * absorption);
      if(T <= .01) {
        break;
      }
      float opacity = 50.;
      float k = opacity * tmp * T;
      vec4 cloudColor = vec4(1.);
      vec4 col1 = cloudColor * k;
      vec4 col2 = vec4(0.);
      color += col1 + col2;
    }
    rayDepth += sceneDist * zStep;
    // rayDepth += sceneDist * stepScale;
  }
  // if (sceneDist >= stopThreshold) {
  //   rayDepth = end;
  // } else {
  //   rayDepth += sceneDist;
  // }
  // return rayDepth;
  RayMarchOutput result;
  result.dist = rayDepth;
  result.color = color;
  return result;

  /*
  const int sampleLightCount = 6;

  for(int i = 0; i < maxIterations; i++) {
    float sceneDist = scene(origin + dir * rayDepth);
    if(sceneDist > 0.) {
      float tmp = sceneDist / float(maxIterations);
      T *= 1. - (tmp * absorption);
      if(T <= .01) {
        break;
      }
      if((sceneDist < stopThreshold) || (rayDepth >= end)) {
        break;
      }
      rayDepth += sceneDist * stepScale;

      #if USE_LIGHT == 1
      float Tl = 1.;
      vec3 lp = p;
      for(int j = 0; j < maxSampleLightCount; j++) {
        float desnsityLight = scene(lp);
        if(sceneDistLight > 0.) {
          float tmpl = sceneDistLight / float(sampleCount);
          Tl *= (tmpl * absorption);
        }
        if(Tl <= .01) {
          break;
        }
        lp += sunDirection * zstepl;
      }
      #endif
    }
  }
  */
}

vec3 lighting(vec3 position, vec3 cameraPos, vec3 lookAt) {
  vec3 sceneColor = vec3(0.);
  vec3 normal = getNormal(position);

  vec3 objColor = vec3(.3);

  vec3 lightPos = vec3(1., 1., 1.);

  // directional light
  float diffuse = max(0., dot(normal, normalize(lightPos)));

  // ambient
  vec3 ambient = vec3(0., .08, .1);

  return diffuse + ambient;
}

void main() {
  vec2 aspect = vec2(iResolution.x / iResolution.y, 1.);
  vec2 uv = (gl_FragCoord.xy * 2.0 - iResolution.xy) / min(iResolution.x, iResolution.y);
  vec2 screenCoord = (2. * gl_FragCoord.xy / iResolution.xy - 1.) * aspect;

  // camera settings
  vec3 lookAt = vec3(0.);
  vec3 cameraPos = vec3(vec2(2. * iMouse.xy / iResolution.xy - 1.) * 1., 0.) + vec3(0., 0., 10.);
  float nearClip = 0.;
  float farClip = 40.;
  float fov = 0.8;

  // camera vectors
  vec3 forward = normalize(lookAt - cameraPos);
  vec3 right = normalize(cross(forward, vec3(0., 1., 0.)));
  vec3 up = normalize(cross(right, forward));

  // raymarch
  vec3 rayOrigin = cameraPos;
  vec3 rayDirection = normalize(forward + fov * screenCoord.x * right + fov * screenCoord.y * up);
  RayMarchOutput result = rayMarching(rayOrigin, rayDirection, nearClip, farClip);
  float dist = result.dist;
  vec4 color = result.color;

  /*
  if(dist >= farClip) {
    vec3 bgColor = vec3(0.);
    gl_FragColor = vec4(bgColor, 1.);
    return;
  }
  vec3 position = rayOrigin + rayDirection * dist;
  vec3 normal = getNormal(position);
  vec3 sceneColor = lighting(position, cameraPos, lookAt);
  */

  vec3 bg = mix(
    vec3(.3, .1, .8),
    vec3(.7, .7, 1.),
    1. - (uv.y + 1.) * .5
  );
  // color.rgb += bg;

  // gl_FragColor = vec4(vec3(fbm(vec3(vec2(screenCoord), 1.))), 1.);
  gl_FragColor = color;
}
