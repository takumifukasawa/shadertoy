
#define EPS 0.0001
#define PI 3.14159265359

precision mediump float;

const int maxIterations = 64;
const float stepScale = 1.;
const float stopThreshold = .005;

float sphere(vec3 p, float size) {
  return length(p) - size;
}

float tube2(vec2 p, float size) {
  return length(p) - size;
}

float box2(vec2 p, float size) {
  return length(max(abs(p) - size, 0.));
}

float cylindar(vec3 p, vec3 c) {
  return length(p.xz - c.xy) - c.z;
}

float displacement(vec3 p, vec3 power) {
  return sin(power.x * p.x) * sin(power.y * p.y) * sin(power.z * p.z);
}

vec3 repeat(vec3 p, float c) {
  return mod(p, c) - c * .5;
}

float smin(float a, float b, float k) {
  float res = exp(-k * a) + exp(-k * b);
  return -log(res) / k;
}

float scene(vec3 p) {
  vec3 _pb = repeat(p, 4.);
  float b1 = box2(_pb.xy, .3);
  float b2 = box2(_pb.yz, .3);
  float b3 = box2(_pb.xz, .3);

  vec3 _pt = repeat(p, .2);
  float t1 = tube2(_pt.xy, .02);
  float t2 = tube2(_pt.yz, .02);
  float t3 = tube2(_pt.xz, .02);

  float c = 0.;
  c = smin(b1, b2, 3.);
  c = smin(c, b3, 3.);

  return c;
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

vec3 lighting(vec3 position, vec3 cameraPos) {
  vec3 sceneColor = vec3(0.);
  vec3 normal = getNormal(position);

  vec3 objColor = vec3(.2, .2, .8);

  vec3 lightPos = vec3(0., 0., 0.);

  vec3 ambient = vec3(0., 0., .1);

  vec3 lightDir = lightPos - position;

  // directional light
  // float diffuse = max(0., dot(normal, normalize(lightPos)));

  // point light
  float diffuse = max(0., dot(normal, normalize(lightDir)));
  float d = distance(lightPos, position);
  vec3 k = vec3(.06, .08, .09);
  float attenuation = 1. / (k.x + (k.y * d) + (k.z * d * d));

  vec3 ref = reflect(-normalize(lightDir), normal);
  float specular = max(0., dot(ref, normalize(cameraPos - normal)));
  float specularPower = 16.;
  specular = pow(specular, specularPower);

  diffuse *= attenuation;
  specular *= attenuation;

  return objColor * vec3(diffuse) + specular + ambient;
}

vec3 fog(vec3 color, float distance, vec3 fogColor, float b) {
  float fogAmount = 1. - exp(-distance * b);
  return mix(color, fogColor, fogAmount);
}

// void mainImage(out vec4 fragColor, in vec2 fragCoord )
void main() {
  vec2 aspect = vec2(iResolution.x / iResolution.y, 1.);
  vec2 screenCoord = (2. * gl_FragCoord.xy / iResolution.xy - 1.) * aspect;

  // camera settings
  vec3 lookAt = vec3(0., 0., 0.);
  vec3 cameraPos = vec3(cos(iTime / 3.) * 4., sin(iTime / 3.) * 4., 4.);
  float fov = .9;
  float nearClip = 0.;
  float farClip = 80.;

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

  vec3 sceneColor = lighting(position, cameraPos);
  sceneColor = fog(sceneColor, dist, vec3(0.), .04);

  gl_FragColor = vec4(sceneColor, 1.);
}
