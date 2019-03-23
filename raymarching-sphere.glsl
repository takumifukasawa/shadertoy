
#define EPS 0.0001
#define PI 3.14159265359

precision highp float;

const int maxIterations = 64;
const float stepScale = 1.;
const float stopThreshold = .005;

float sphere(vec3 p, float size) {
  return length(p) - size;
}

float scene(vec3 p) {
  return sphere(p, .9);
}

vec3 getNormal(vec3 p) {
  const float e = EPS;
  return normalize(vec3(
    scene(p + vec3(e,   0.0, 0.0)) - scene(p + vec3(-e,  0.0, 0.0)),
    scene(p + vec3(0.0,   e, 0.0)) - scene(p + vec3(0.0,  -e, 0.0)),
    scene(p + vec3(0.0, 0.0,   e)) - scene(p + vec3(0.0, 0.0,  -e))
  ));
}

float rayMarching(vec3 origin, vec3 dir, float start, float end) {
  float sceneDist = 0.;
  float rayDepth = start;
  for(int i = 0; i < maxIterations; i++) {
    sceneDist = scene(origin + dir * rayDepth);
    if((sceneDist < stopThreshold) || (rayDepth >= end)) {
      break;
    }
    rayDepth += sceneDist * stepScale;
  }
  if (sceneDist >= stopThreshold) {
    rayDepth = end;
  } else {
    rayDepth += sceneDist;
  }
  return rayDepth;
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
  vec2 screenCoord = (2. * gl_FragCoord.xy / iResolution.xy - 1.) * aspect;

  // camera settings
  vec3 lookAt = vec3(0.);
  vec3 cameraPos = vec3(vec2(2. * iMouse.xy / iResolution.xy - 1.) * 3., 2.) + vec3(0., 0., 2.);
  float nearClip = 0.;
  float farClip = 80.;
  float fov = 0.5;

  // camera vectors
  vec3 forward = normalize(lookAt - cameraPos);
  vec3 right = normalize(cross(forward, vec3(0., 1., 0.)));
  vec3 up = normalize(cross(right, forward));

  // raymarch
  vec3 rayOrigin = cameraPos;
  vec3 rayDirection = normalize(forward + fov * screenCoord.x * right + fov * screenCoord.y * up);
  float dist = rayMarching(rayOrigin, rayDirection, nearClip, farClip);

  if(dist >= farClip) {
    vec3 bgColor = vec3(0.);
    gl_FragColor = vec4(bgColor, 1.);
    return;
  }

  vec3 position = rayOrigin + rayDirection * dist;
  vec3 normal = getNormal(position);

  vec3 sceneColor = lighting(position, cameraPos, lookAt);

  gl_FragColor = vec4(sceneColor, 1.);
}
