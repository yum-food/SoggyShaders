#ifndef PARALLAX_LIGHTING
#define PARALLAX_LIGHTING

#include "AutoLight.cginc"
#include "iq_sdf.cginc"
#include "math.cginc"
#include "motion.cginc"
#include "pbr.cginc"
#include "poi.cginc"

struct appdata
{
  float4 position : POSITION;
  float2 uv : TEXCOORD0;
  float3 normal : NORMAL;
};

float _Curvature_Step;
float _Min_Hit_Dist;
float _Max_Dist;
float _Ray_March_Steps;

sampler2D _Layer0_BaseColor;
sampler2D _Layer1_BaseColor;
sampler2D _Layer2_BaseColor;

sampler2D _Layer0_Normal;
sampler2D _Layer1_Normal;
sampler2D _Layer2_Normal;

sampler2D _Layer0_Metallic;
sampler2D _Layer1_Metallic;
sampler2D _Layer2_Metallic;

sampler2D _Layer0_Roughness;
sampler2D _Layer1_Roughness;
sampler2D _Layer2_Roughness;

float _Layer0_Offset;
float _Layer0_XScale;
float _Layer0_YScale;
float _Layer0_Emission;

float _Layer1_Offset;
float _Layer1_XScale;
float _Layer1_YScale;
float _Layer1_Emission;

float _Layer2_Offset;
float _Layer2_XScale;
float _Layer2_YScale;
float _Layer2_Emission;

void getVertexLightColor(inout v2f i)
{
  #if defined(VERTEXLIGHT_ON)
  float3 light_pos = float3(unity_4LightPosX0.x, unity_4LightPosY0.x,
      unity_4LightPosZ0.x);
  float3 light_float = light_pos - i.worldPos;
  float3 light_dir = normalize(light_float);
  float ndotl = DotClamped(i.normal, light_dir);
  // Light fills an expanding sphere with surface area 4 * pi * r^2.
  // By conservation of energy, this means that at distance r, light intensity
  // is proportional to 1/(r^2).
  float attenuation = 1 / (1 + dot(light_float, light_float) * unity_4LightAtten0.x);
  i.vertexLightColor = unity_LightColor[0].rgb * ndotl * attenuation;

  i.vertexLightColor = Shade4PointLights(
    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
    unity_LightColor[0].rgb,
    unity_LightColor[1].rgb,
    unity_LightColor[2].rgb,
    unity_LightColor[3].rgb,
    unity_4LightAtten0, i.worldPos, i.normal
  );
  #endif
}

v2f vert(appdata v)
{
  v2f o;
  o.position = UnityObjectToClipPos(v.position);
  o.worldPos = mul(unity_ObjectToWorld, v.position);
  o.normal = UnityObjectToWorldNormal(v.normal);
  o.uv.xy = float2(0, 0);
  o.uv.zw = 1.0 - v.uv;
  getVertexLightColor(o);
  return o;
}

float getWorldSpaceDepth(in const float3 worldPos)
{
  float4 clip_pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
  return clip_pos.z / clip_pos.w;
}

float4 getLayerBaseColor(in float2 uv, in int layer)
{
  [forcecase]
  switch (layer) {
    case 0:
      return tex2Dgrad(_Layer0_BaseColor, uv, ddx(uv.x), ddy(uv.y));
    case 1:
      return tex2Dgrad(_Layer1_BaseColor, uv, ddx(uv.x), ddy(uv.y));
    case 2:
      return tex2Dgrad(_Layer2_BaseColor, uv, ddx(uv.x), ddy(uv.y));
    default:
      return 0.0;
  }
}

float3 getLayerNormal(in float2 uv, in int layer)
{
  [forcecase]
  switch (layer) {
    case 0:
      return tex2Dgrad(_Layer0_Normal, uv, ddx(uv.x), ddy(uv.y));
    case 1:
      return tex2Dgrad(_Layer1_Normal, uv, ddx(uv.x), ddy(uv.y));
    case 2:
      return tex2Dgrad(_Layer2_Normal, uv, ddx(uv.x), ddy(uv.y));
    default:
      return 0.0;
  }
}

float getLayerMetallic(in float2 uv, in int layer)
{
  [forcecase]
  switch (layer) {
    case 0:
      return tex2Dgrad(_Layer0_Metallic, uv, ddx(uv.x), ddy(uv.y));
    case 1:
      return tex2Dgrad(_Layer1_Metallic, uv, ddx(uv.x), ddy(uv.y));
    case 2:
      return tex2Dgrad(_Layer2_Metallic, uv, ddx(uv.x), ddy(uv.y));
    default:
      return 0.0;
  }
}

float getLayerRoughness(in float2 uv, in int layer)
{
  [forcecase]
  switch (layer) {
    case 0:
      return tex2Dgrad(_Layer0_Roughness, uv, ddx(uv.x), ddy(uv.y));
    case 1:
      return tex2Dgrad(_Layer1_Roughness, uv, ddx(uv.x), ddy(uv.y));
    case 2:
      return tex2Dgrad(_Layer2_Roughness, uv, ddx(uv.x), ddy(uv.y));
    default:
      return 0.0;
  }
}

float getLayerOffset(in int layer)
{
  [forcecase]
  switch (layer) {
    case 0:
      return _Layer0_Offset;
    case 1:
      return _Layer1_Offset;
    case 2:
      return _Layer2_Offset;
    default:
      return 0.0;
  }
}

float getLayerXScale(in int layer)
{
  [forcecase]
  switch (layer) {
    case 0:
      return _Layer0_XScale;
    case 1:
      return _Layer1_XScale;
    case 2:
      return _Layer2_XScale;
    default:
      return 0.0;
  }
}

float getLayerYScale(in int layer)
{
  [forcecase]
  switch (layer) {
    case 0:
      return _Layer0_YScale;
    case 1:
      return _Layer1_YScale;
    case 2:
      return _Layer2_YScale;
    default:
      return 0.0;
  }
}

float getLayerEmission(in int layer)
{
  [forcecase]
  switch (layer) {
    case 0:
      return _Layer0_Emission;
    case 1:
      return _Layer1_Emission;
    case 2:
      return _Layer2_Emission;
    default:
      return 0.0;
  }
}

float2 getLayerScale(in int layer)
{
  return float2(getLayerXScale(layer), getLayerYScale(layer));
}

float4 effect(inout v2f i, out float depth)
{
  float4 clip_pos = mul(UNITY_MATRIX_VP, float4(i.worldPos, 1.0));
  depth = clip_pos.z / clip_pos.w;

  float3 camera_position = _WorldSpaceCameraPos.xyz;
  float3 view_dir = normalize(_WorldSpaceCameraPos - i.worldPos);

  const float3 ro = i.worldPos;
  const float3 rd = view_dir * -1.0;

  static const float MIN_D = _Min_Hit_Dist;
  static const float MAX_D = _Max_Dist;

  float4 result = float4(1.0, 1.0, 1.0, 0.0);

  float foreground_depth = -100.0;
  bool ray_hit = false;

  float3 object_offset = transpose(unity_ObjectToWorld)[3].xyz;

  float4x4 object_rotate = float4x4(
      unity_ObjectToWorld[0].xyz, 0,
      unity_ObjectToWorld[1].xyz, 0,
      unity_ObjectToWorld[2].xyz, 0,
      0, 0, 0, 1
      );
  float3 object_scale_vec = float3(
      length(float3(unity_ObjectToWorld[0].x, unity_ObjectToWorld[1].x, unity_ObjectToWorld[2].x)),
      length(float3(unity_ObjectToWorld[0].y, unity_ObjectToWorld[1].y, unity_ObjectToWorld[2].y)),
      length(float3(unity_ObjectToWorld[0].z, unity_ObjectToWorld[1].z, unity_ObjectToWorld[2].z))
      );
  float object_scale = min(object_scale_vec.x, min(object_scale_vec.y, object_scale_vec.z));

  for (float layer = 3 - 1; layer >= 0; layer--) {
    bool shade_out = false;
    float3 layer_offset = float3(0.0, 0.0, 1.0) * getLayerOffset(layer) * object_scale;
    float2 layer_scale = getLayerScale(layer);

    float cum_dist = 0.0;
    float3 bbox = float3(1.0, 1.0, 0.0) * 0.2;
    float3 pp;
    for (int ii = 0; ii < _Ray_March_Steps; ii++) {
      pp = ro + rd * cum_dist - object_offset;
      pp = mul(transpose(object_rotate), float4(pp, 1.0)).xyz;
      pp /= object_scale_vec;

      const float3 off = layer_offset;
      pp += off;

      pp.xy /= layer_scale;

      float d0 = distance_from_box(pp / object_scale, bbox) * object_scale;
      if (d0 < MIN_D) {
        foreground_depth = getWorldSpaceDepth(pp);
        shade_out = true;
        ray_hit = true;
        break;
      }
      cum_dist += d0;
      if (cum_dist >= MAX_D) {
        break;
      }
    }
    if (shade_out) {
      float2 uv = pp.xy;
      uv /= (bbox.xy * 2.0) * object_scale;
      uv.x += 0.5;
      uv.y += 0.5;
      // Render textures left-to-right when looking in the mirror.
      if (isInMirror()) {
        uv.x = 1.0 - uv.x;
      }
      uv = clamp(uv, 0.0, 1.0);

      float4 color = getLayerBaseColor(uv, (int) layer);
      if (color.a < 0.9) {
        color.a = 0.0;
      }
      const float3 normal = getLayerNormal(uv, (int) layer);
      const float metallic = getLayerMetallic(uv, (int) layer);
      const float smoothness = 1.0 - getLayerRoughness(uv, (int) layer);

      bool custom_cubemap = true;
      float4 lit_color;

      // Hack: Bright cubemaps cause glare on rough surfaces. To prevent this,
      // switch to unlit shading when shading a perfectly rough material.
      if (smoothness == 0.0) {
        lit_color = color;
      } else {
        lit_color = getLitColor(i, color, pp, normal, metallic, smoothness, custom_cubemap);
      }

      lit_color.rgb += color.rgb * getLayerEmission(layer);

      result.rgb = lerp(result.rgb, lit_color.rgb, lit_color.a);

      float a_remainder = abs(result.a - color.a);
      float a_increment = a_remainder * color.a;
      result.a += a_increment;
    }
  }

  // No ray hit: return default material
  float base_depth = depth;
  float metallic = 1.0;
  float smoothness = 0.5;
  bool custom_cubemap = true;
  float4 bg_color = float4(1.0, 1.0, 1.0, 1.0);
  bg_color = getLitColor(i, bg_color, i.worldPos, i.normal, metallic, smoothness, custom_cubemap);

  result.rgb = lerp(bg_color.rgb, result.rgb, result.a);
  result.a = 1.0;

  return result;
}

fixed4 frag(v2f i, out float depth : SV_DepthLessEqual) : SV_Target
{
  return effect(i, depth);
}

#endif  // PARALLAX_LIGHTING

