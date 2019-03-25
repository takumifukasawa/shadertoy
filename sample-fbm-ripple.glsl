// https://codepen.io/shubniggurath/pen/XZJozp?editors=1000

    const float NOISE_SIZE = 3.; // The size of the noise. Essentially the multiplier for the noise UV. Smaller = bigger
    const float INTENSITY = 20.; // The intensity of the displacement
    const float REFLECTION_INTENSITY = 4.; // The intensity of the rellowish reflections.
    const int octaves = 2; // the number of octaves to generate in the FBM noise
    const float seed = 43758.5453123; // A random seed :)
  
    /*
      Underwater Sun
      Liam Egan - 2018
      ----------------------

      A basic rippling pattern distorted by a very light amount of FBM noise.
      
      Many many thanks to Inigo Quilez, Patricio Gonzalez Vivo, 
      Gary Warne, and many many others.
      "Nanos gigantum humeris insidentes"

    */
  
    vec2 random2(vec2 st, float seed){
        st = vec2( dot(st,vec2(127.1,311.7)),
                  dot(st,vec2(269.5,183.3)) );
        return -1.0 + 2.0*fract(sin(st)*seed);
    }
  
    // Value Noise by Inigo Quilez - iq/2013
    // https://www.shadertoy.com/view/lsf3WH
    float noise(vec2 st, float seed) {
        vec2 i = floor(st);
        vec2 f = fract(st);

        vec2 u = f*f*(3.0-2.0*f);

        return mix( mix( dot( random2(i + vec2(0.0,0.0), seed ), f - vec2(0.0,0.0) ), 
                         dot( random2(i + vec2(1.0,0.0), seed ), f - vec2(1.0,0.0) ), u.x),
                    mix( dot( random2(i + vec2(0.0,1.0), seed ), f - vec2(0.0,1.0) ), 
                         dot( random2(i + vec2(1.0,1.0), seed ), f - vec2(1.0,1.0) ), u.x), u.y);
    }
  
    float fbm1(in vec2 _st, float seed) {
      float v = 0.0;
      float a = 0.5;
      vec2 shift = vec2(100.0);
      // Rotate to reduce axial bias
      mat2 rot = mat2(cos(0.5), sin(0.5),
                      -sin(0.5), cos(0.50));
      for (int i = 0; i < octaves; ++i) {
          v += a * noise(_st, seed);
          _st = rot * _st * 2.0 + shift;
          a *= 0.4;
      }
      return v + .4;
    }
  
    float pattern(vec2 uv, float seed, float time, inout vec2 q, inout vec2 r) {

      q = vec2( fbm1( uv + vec2(0.0,0.0), seed ),
                     fbm1( uv + vec2(5.2,1.3), seed ) );

      r = vec2( fbm1( uv + 4.0*q + vec2(1.7 - time / 2.,9.2), seed ),
                     fbm1( uv + 4.0*q + vec2(8.3 - time / 2.,2.8), seed ) );

      float rtn = fbm1( uv + 4.0*r, seed );

      return rtn;
    }

    mat2 rotate(float angle) {
      return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    }

    void main() {
      vec2 uv = (gl_FragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;

      // Generate our displacement map
      vec2 _uv = uv * NOISE_SIZE;
      vec2 q = vec2(0.);
      vec2 r = vec2(0.);
      float pattern = pattern(_uv, seed, iTime/2., q, r);

      uv += (.5 - pattern) / INTENSITY; // modulate the main UV coordinates by the pattern
      // uv -= .5 / INTENSITY; // This just recenters the UV coords after the distortion

      float len = length(uv) + .01;

      float field = len+0.05*(-1.0*iTime / 5.); // The distance field from the middle to the edge

      float ripple;
      ripple = sin(field*80.0) * .5 * r.x * pattern + 1.; // The ripple pattern
      ripple += smoothstep(0.2,.0,len); // Adding a core gradient to the sun. Essentially this is just a smoothed version of the distance field
      ripple *= smoothstep(0.3,.9,clamp(1. - len * 1.5,0.0,1.0)); // Vignette the sun, making it smaller than infinity
      ripple -= fract(ripple * 8.) / 100.; // Adds a nice sort of reflective element

      vec3 colour = vec3(.2, .3, .4); // the basic colour
      colour += ripple * length(r) * vec3(1., 1., .8); // ripple times sun colour
      colour += (1. - pattern * REFLECTION_INTENSITY * .5) * smoothstep(0.0,.7,clamp(1. - len * 1.5,0.0,1.0)) * vec3(-.2, -.1, 0.); // vignette and reflection
      colour += (1. - pattern * REFLECTION_INTENSITY * 2.) * smoothstep(0.5,.9,clamp(1. - len * 1.5,0.0,1.0)) * vec3(-.2, -.1, 0.); // vignette and reflection 2 - this is essentially a more intense, but reduced radius version of the previous one.

      // gl_FragColor = vec4(vec3(ripple), 1.);
      gl_FragColor = vec4(colour, 1.);
    }

