#ifndef __PBR_INC
#define __PBR_INC

#include "UnityPBSLighting.cginc"

UNITY_DECLARE_TEXCUBE(_Cubemap);

struct v2f
{
  float4 clipPos : SV_POSITION;
  float2 uv : TEXCOORD0;
  float3 normal : TEXCOORD1;
  float3 worldPos : TEXCOORD2;

  float3 objPos : TEXCOORD3;

  #if defined(VERTEXLIGHT_ON)
  float3 vertexLightColor : TEXCOORD3;
  #endif
};

UnityLight GetLight(v2f i, float3 worldPos, float3 normal)
{
  UNITY_LIGHT_ATTENUATION(attenuation, 0, worldPos);
  float3 light_color = _LightColor0.rgb * attenuation;

  UnityLight light;
  light.color = light_color;
  #if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
  light.dir = normalize(_WorldSpaceLightPos0.xyz - worldPos);
  #else
  light.dir = _WorldSpaceLightPos0.xyz;
  #endif
  light.ndotl = DotClamped(normal, light.dir);

  return light;
}

UnityIndirect GetIndirect(v2f i, float3 view_dir, float3 normal,
    float smoothness, bool custom_cubemap) {
  UnityIndirect indirect;
  indirect.diffuse = 0;
  indirect.specular = 0;

  #if defined(VERTEXLIGHT_ON)
  indirect.diffuse = i.vertexLightColor;
  #endif

  #if defined(FORWARD_BASE_PASS)
  indirect.diffuse += max(0, ShadeSH9(float4(normal, 1)));
  float3 reflect_dir = reflect(-view_dir, normal);
  // There's a nonlinear relationship between mipmap level and roughness.
  float roughness = 1 - smoothness;
  roughness *= 1.7 - .7 * roughness;
  if (custom_cubemap) {
    float3 env_sample = UNITY_SAMPLE_TEXCUBE_LOD(
        _Cubemap,
        reflect_dir,
        roughness * UNITY_SPECCUBE_LOD_STEPS);
    indirect.specular = env_sample;
  } else {
    float3 env_sample = UNITY_SAMPLE_TEXCUBE_LOD(
        unity_SpecCube0,
        reflect_dir,
        roughness * UNITY_SPECCUBE_LOD_STEPS);
    indirect.specular = env_sample;
  }
  #endif

  return indirect;
}

float4 getLitColor(v2f i, float4 albedo, float3 worldPos, float3 normal,
    float metallic, float smoothness,
    bool custom_cubemap)
{
  float3 specular_tint;
  float one_minus_reflectivity;
  albedo.rgb = DiffuseAndSpecularFromMetallic(
    albedo, metallic, specular_tint, one_minus_reflectivity);

  float3 view_dir = normalize(_WorldSpaceCameraPos - i.worldPos);

  float3 pbr = UNITY_BRDF_PBS(albedo, specular_tint,
      one_minus_reflectivity, smoothness,
      view_dir, normal,
      GetLight(i, worldPos, normal),
      GetIndirect(i, view_dir, normal, smoothness, custom_cubemap)).rgb;

  return float4(saturate(pbr), albedo.a);
}

#endif  // __PBR_INC
