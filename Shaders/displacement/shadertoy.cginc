#ifndef __SHADERTOY_INC
#define __SHADERTOY_INC

#include "AutoLight.cginc"
#include "pema99.cginc"
#include "poi.cginc"

// https://www.shadertoy.com/view/3ttSzr
void effect_crumpled_wave( out float4 fragColor, in float2 uv ){
  for(float i = 1.0; i < 8.0; i++) {
    uv.y += i * 0.1 / i *
      sin(uv.x * i * i + _Time[3] * 0.5) *
      sin(uv.y * i * i + _Time[3] * 0.5);
  }

  float3 col;
  col.r  = uv.y - 0.1;
  col.g = uv.y + 0.3;
  col.b = uv.y + 0.95;

  col = RGBtoHSV(col);

  float x_diff = 0.50 - col.x;
  col.x = 0.80 + x_diff * 0.5;
  col.x += uv.x / 16.0 + .05;

  col.y *= 0.8;
  col.z *= 0.7;  // Darken

  col.x = glsl_mod(col.x, 1.0);
  col = HSVtoRGB(col);

  fragColor = float4(col,1.0);
}

#endif // __SHADERTOY_INC
