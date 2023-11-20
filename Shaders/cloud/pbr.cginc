#ifndef __PBR_INC__
#define __PBR_INC__

#include "AutoLight.cginc"
#include "eyes_data.cginc"
#include "UnityPBSLighting.cginc"

float _Enable_Custom_Cubemap;
UNITY_DECLARE_TEXCUBE(_Custom_Cubemap);

sampler2D _Matcap;
float _Matcap_Str;
float _Enable_Matcap;
float _Matcap_Mode;

UnityIndirect GetIndirect(v2f i, float3 view_dir, float smoothness) {
  UnityIndirect indirect;
  indirect.diffuse = 0;
  indirect.specular = 0;

  #if defined(VERTEXLIGHT_ON)
  indirect.diffuse = i.vertexLightColor;
  #endif

  #if defined(FORWARD_BASE_PASS)
  indirect.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
  float3 reflect_dir = reflect(-view_dir, i.normal);
  // There's a nonlinear relationship between mipmap level and roughness.
  float roughness = 1 - smoothness;
  roughness *= 1.7 - .7 * roughness;
  float3 env_sample;
  if (_Enable_Custom_Cubemap) {
    env_sample = UNITY_SAMPLE_TEXCUBE_LOD(
        _Custom_Cubemap,
        reflect_dir,
        roughness * UNITY_SPECCUBE_LOD_STEPS);
  } else {
    env_sample = UNITY_SAMPLE_TEXCUBE_LOD(
        unity_SpecCube0,
        reflect_dir,
        roughness * UNITY_SPECCUBE_LOD_STEPS);
  }
  if (_Enable_Matcap) {
    // identity: (a, b, c) and (c, c, -(a +b)) are perpendicular to each other
    float3 ortho_1 = normalize(float3(view_dir.z, view_dir.z, -(view_dir.y + view_dir.x)));
    float3 ortho_2 = cross(view_dir, ortho_1);
    float2 matcap_uv = (float2(dot(i.normal, ortho_1), dot(i.normal, ortho_2)) + 1) * .43;
    float iddx = ddx(i.uv.x);
    float iddy = ddy(i.uv.y);
    float3 matcap = tex2Dgrad(_Matcap, matcap_uv, iddx, iddy) * _Matcap_Str;

    int mode = round(_Matcap_Mode);
    switch (mode) {
      case 1:
        indirect.specular = clamp(env_sample + matcap, 0, 1);
        break;
      case 2:
        indirect.specular = clamp(env_sample * matcap, 0, 1);
        break;
      case 3:
        indirect.specular = clamp(matcap, 0, 1);
        break;
      case 4:
        indirect.specular = clamp(env_sample - matcap, 0, 1);
        break;
    }
  } else {
    indirect.specular = env_sample;
  }
  #endif

  return indirect;
}

UnityLight GetLight(v2f i)
{
  UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos.xyz);
  float3 light_color = _LightColor0.rgb * attenuation;

  UnityLight light;
  light.color = light_color;
  #if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
  light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
  #else
  light.dir = _WorldSpaceLightPos0.xyz;
  #endif
  light.ndotl = DotClamped(i.normal, light.dir);

  return light;
}

void initNormal(inout v2f i)
{
  i.normal = normalize(i.normal);
}

float4 light(inout v2f i,
    float4 albedo,
    float metallic,
    float smoothness)
{
  initNormal(i);

  float3 specular_tint;
  float one_minus_reflectivity;
  albedo.rgb = DiffuseAndSpecularFromMetallic(
    albedo, metallic, specular_tint, one_minus_reflectivity);

  float3 view_dir = normalize(_WorldSpaceCameraPos - i.worldPos);
  float3 pbr = UNITY_BRDF_PBS(albedo,
      specular_tint,
      one_minus_reflectivity,
      smoothness,
      i.normal,
      view_dir,
      GetLight(i),
      GetIndirect(i, view_dir, smoothness)).rgb;

  return float4(saturate(pbr), albedo.a);
}

float getWorldSpaceDepth(in float4 world_pos)
{
  float4 clip_pos = mul(UNITY_MATRIX_VP, world_pos);
  return LinearEyeDepth(clip_pos.z / clip_pos.w);
}

sampler2D _CameraDepthTexture;

// Return depth buffer at coordinate, on [0, 1].
float getDepthBufferAt(in float4 world_pos)
{
  float4 clip_pos = mul(UNITY_MATRIX_VP, world_pos);
  float4 uv = ComputeGrabScreenPos(clip_pos);
  return LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv.xy / uv.w));
}

#endif  // __PBR_INC__

