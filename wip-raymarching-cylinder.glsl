
//---------------------------------------------------------------
// ref
// https://speakerdeck.com/gam0022/motutoqi-li-dexie-shi-de-nahui-zuo-rigasitai-reimatinguxiang-kefalsesiedeinguji-shu
//---------------------------------------------------------------

#define EPS 0.0001
#define PI 3.14159265359
#define AO_TYPE 2 // 0 ~ 2

precision mediump float;

const int maxIterations = 64;
const float stepScale = 1.;
const float stopThreshold = .005;

struct Light {
  vec3 position;
  float intensity;
  vec3 color;
};

float sphere(vec3 p, float size) {
  return length(p) - size;
}

float box(vec3 p, vec3 size) {
  vec3 d = abs(p) - size;
  return length(max(d, 0.)) + min(max(d.x, max(d.y, d.z)), 0.);
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

float plane(vec3 p, vec4 n) {
  return dot(p, n.xyz) + n.w;
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

vec3 map(vec3 p) {
  float d = box(p, vec3(1.));
  float s = 1.;
  for(int m = 0; m < 3; m++) {
    vec3 a = mod(p * s, 2.) - 1.;
    s *= 3.;
    vec3 r = abs(1. - 3. * abs(a));
    float da = max(r.x, r.y);
    float db = max(r.y, r.z);
    float dc = max(r.z, r.x);
    float c = (min(da, min(db, dc)) - 1.) / s;
    d = max(d, c);
  }
  return vec3(d, 0., 0.);
}

float tgladFormula(vec3 p) {
  p = mod(p, 2.);
  float mr = .25;
  float mxr = 1.;
  vec4 scale = vec4(vec3(-3.12), 3.12);
  vec4 p0 = vec4(0., 1.59, -1., 0.);
  vec4 z = vec4(p, 1.);
  for(int i = 0; i < 3; i++) {
    z.xyz = clamp(z.xyz, -.94, .94) * 2. - z.xyz;
    z *= scale / clamp(dot(z.xyz, z.xyz), mr, mxr) * 1.;
    z.xyz += p;
  }
  float d5 = (length(max(abs(z.xyz) - vec3(1.2, 49., 1.4), 0.)) - .06) / z.w;
  return d5;
}

float pseudoKleinan(vec3 p) {
  const vec3 cSize = vec3(.92436, .90756, .92436);
  const float size = 1.;
  const vec3 c = vec3(0.);
  float deFactor = 1.;
  const vec3 offset = vec3(0.);
  vec3 ap = p + 1.;
  for(int i = 0; i < 10; i++) {
    ap = p;
    p = 2. * clamp(p, -cSize, cSize) - p;
    float r2 = dot(p, p);
    float k = max(size / r2, 1.);
    p *= k;
    deFactor *= k;
    p += c;
  }
  float r = abs(.5 * abs(p.z - offset.z) / deFactor);
  return r;
}

float scene(vec3 p) {
  // vec3 d = map(p);
  // return d.x;

  // return tgladFormula(p);
  // return pseudoKleinan(p);

  float plBottom = plane(p - vec3(0., -.5, 0.), normalize(vec4(0., 1., 0., 0.)));
  float plTop = plane(p - vec3(0., .5, 0.), normalize(vec4(0., -1., 0., 0.)));
  float b = box2(p.xy, .2);
  float s = sphere(p + vec3(sin(iTime) * 2., 0., 0.), .5);

  // return plTop;
  return smin(plTop, smin(s, plBottom, 16.), 16.);
}

float calcAO(vec3 p, vec3 n) {
  float k = 1.;
  float occ = 0.;
  for(int i = 0; i < 5; i++) {
    float len = .15 * (float(i) + 1.);
    float distance = scene(n * len + p);
    occ += (len - distance) * k;
    k *= .5;
  }
  return clamp(1. - occ, 0., 1.);
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

  vec3 h = vec3(1.);
  for(int i = 0; i < maxIterations; i++) {
    sceneDist = scene(origin + dir * rayDepth);
    // ray hit object
    if(sceneDist < stopThreshold) {
      break;
    }
    // too far
    if(rayDepth >= end) {
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

float getSpecular(vec3 position, vec3 normal, Light light, float diffuse, vec3 cameraPos) {
  vec3 lightDir = light.position - position;
  vec3 ref = reflect(-normalize(lightDir), normal);
  float specular = 0.;
  if(diffuse > 0.) {
    specular = max(0., dot(ref, normalize(cameraPos - normal)));
    float specularPower = 32.;
    specular = pow(specular, specularPower) * light.intensity;
  }
  return specular;
}

vec3 lighting(vec3 position, vec3 cameraPos) {
  vec3 sceneColor = vec3(0.);
  vec3 normal = getNormal(position);

  vec3 objColor = vec3(.8, .4, .4);
  vec3 specularColor = vec3(1., .6, .6);

  Light directionalLight;
  directionalLight.position = vec3(0., 2., 2.);
  directionalLight.intensity = .8;
  directionalLight.color = vec3(.8, .4, .4);

  Light pointLight;
  pointLight.position = vec3(0., 0., 0.);
  pointLight.intensity = .8;
  pointLight.color = vec3(.8, .5, .5);

  Light ambientLight;
  ambientLight.color = vec3(1., .6, .6);
  ambientLight.intensity = .3;

  // directional light
  float dDiffuse = max(0., dot(normal, normalize(directionalLight.position)));
  dDiffuse *= directionalLight.intensity;
  vec3 dDiffuseColor = dDiffuse * directionalLight.color * objColor;
  float dSpecular = getSpecular(position, normal, directionalLight, dDiffuse, cameraPos);
  vec3 dSpecularColor = dSpecular * specularColor;

  // point light
  vec3 pLightDir = pointLight.position - position;
  float pDiffuse = max(0., dot(normal, normalize(pLightDir)));
  vec3 pDiffuseColor = pDiffuse * pointLight.color * objColor;
  float d = distance(pointLight.position, position);
  vec3 k = vec3(.05, .9, .06);
  float attenuation = 1. / (k.x + (k.y * d) + (k.z * d * d));
  pDiffuse *= pointLight.intensity;
  pDiffuse *= attenuation;
  float pSpecular = getSpecular(position, normal, pointLight, pDiffuse, cameraPos);
  pSpecular *= attenuation;
  vec3 pSpecularColor = pSpecular * specularColor;

  // ambient
  vec3 ambientColor = ambientLight.color * ambientLight.intensity * objColor;
  float ao = calcAO(position, normal);

  vec3 diffuse = dDiffuseColor + pDiffuseColor;
  vec3 specular = dSpecularColor + pSpecularColor;
  vec3 ambient = ambientColor;

  // only ao
  #if AO_TYPE == 0
    return vec3(ao);
  #endif
  // not use ao
  #if AO_TYPE == 1
    return objColor * diffuse + specular + ambient;
  #endif
  // use ao
  #if AO_TYPE == 2
    return objColor * diffuse + specular + ambient * ao;
  #endif
}

vec3 fog(vec3 color, float distance, vec3 fogColor, float b) {
  float fogAmount = 1. - exp(-distance * b);
  return mix(color, fogColor, fogAmount);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 aspect = vec2(iResolution.x / iResolution.y, 1.);
  vec2 screenCoord = (2. * fragCoord.xy / iResolution.xy - 1.) * aspect;

  // camera settings
  vec3 lookAt = vec3(0., 0., 0.);
  vec3 cameraPos = vec3(0., 0., 3.);
  float fov = .9;
  float nearClip = 0.;
  float farClip = 10000.;

  // camera vectors
  vec3 forward = normalize(lookAt - cameraPos);
  vec3 right = normalize(cross(forward, vec3(0., 1., 0.)));
  vec3 up = normalize(cross(right, forward));

  // raymarch
  vec3 rayOrigin = cameraPos;
  vec3 rayDirection = normalize(forward + fov * screenCoord.x * right + fov * screenCoord.y * up);
  float dist = rayMarching(rayOrigin, rayDirection, nearClip, farClip);

  if(dist >= farClip) {
    vec3 bgColor = vec3(1.);
    fragColor = vec4(bgColor, 1.);
    return;
  }

  vec3 position = rayOrigin + rayDirection * dist;
  vec3 normal = getNormal(position);

  vec3 sceneColor = lighting(position, cameraPos);

  sceneColor = fog(sceneColor, dist, vec3(0.), .04);

  fragColor = vec4(sceneColor, 1.);
}
