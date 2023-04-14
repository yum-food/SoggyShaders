#ifndef DISPLACEMENT_LIGHTING
#define DISPLACEMENT_LIGHTING

#include "AutoLight.cginc"
#include "iq_sdf.cginc"
#include "math.cginc"
#include "motion.cginc"
#include "pbr.cginc"
#include "poi.cginc"
#include "shadertoy.cginc"

sampler2D _BaseColor;
sampler2D _Normal;
sampler2D _Metallic;
sampler2D _Roughness;

sampler2D _Height;
float _Height_LOD;
float _Height_Exponent;
float _Height_Scale;
float _Height_Speed_X;
float _Height_Speed_Y;
float _Height_AA_Sample_Scale;

sampler2D _Height_Mask;
float _Height_Mask_Exponent;

float _Center_Out_Speed;
float _Center_Out_Sharpness;
float _Center_Out_Min_Radius;
float _Center_Out_Max_Radius;

struct appdata
{
  float4 position : POSITION;
  float2 uv : TEXCOORD0;
  float3 normal : NORMAL;
};

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

  o.objPos = v.position;
  o.clipPos = UnityObjectToClipPos(v.position);
  o.worldPos = mul(unity_ObjectToWorld, v.position);

  o.normal = UnityObjectToWorldNormal(v.normal);
  o.uv = 1.0 - v.uv;

  getVertexLightColor(o);

  return o;
}

void displace(inout v2f vert)
{
  float3 object_offset = transpose(unity_ObjectToWorld)[3].xyz;
  float4x4 object_rotate = float4x4(
      unity_ObjectToWorld[0].xyz, 0,
      unity_ObjectToWorld[1].xyz, 0,
      unity_ObjectToWorld[2].xyz, 0,
      0, 0, 0, 1
      );

  // Manipulate vertex in world space.
  float3 pp = 0;

  float2 traveling_uv = vert.uv;
  traveling_uv.x += _Time[0] * _Height_Speed_X;
  traveling_uv.y += _Time[0] * _Height_Speed_Y;
  traveling_uv = glsl_mod(traveling_uv, 1.0);

  const float duv = _Height_AA_Sample_Scale;

  float z0 = tex2Dlod(_Height, float4(traveling_uv.x, traveling_uv.y, _Height_LOD, 0));
  #if OFFSET_AA_LEVEL >= 1
  float z1 = tex2Dlod(_Height, float4(traveling_uv.x + duv, traveling_uv.y + duv, _Height_LOD, 0));
  float z2 = tex2Dlod(_Height, float4(traveling_uv.x + duv, traveling_uv.y - duv, _Height_LOD, 0));
  float z3 = tex2Dlod(_Height, float4(traveling_uv.x - duv, traveling_uv.y - duv, _Height_LOD, 0));
  float z4 = tex2Dlod(_Height, float4(traveling_uv.x - duv, traveling_uv.y + duv, _Height_LOD, 0));
  #endif
  #if OFFSET_AA_LEVEL >= 2
  float z5 = tex2Dlod(_Height, float4(traveling_uv.x + duv, traveling_uv.y, _Height_LOD, 0));
  float z6 = tex2Dlod(_Height, float4(traveling_uv.x - duv, traveling_uv.y, _Height_LOD, 0));
  float z7 = tex2Dlod(_Height, float4(traveling_uv.x, traveling_uv.y + duv, _Height_LOD, 0));
  float z8 = tex2Dlod(_Height, float4(traveling_uv.x, traveling_uv.y - duv, _Height_LOD, 0));
  #endif

  #if OFFSET_AA_LEVEL == 0
  pp.z += z0;
  #elif OFFSET_AA_LEVEL == 1
  pp.z += (z0 + z1 + z2 + z3 + z4) / 5.0;
  #elif OFFSET_AA_LEVEL == 2
  pp.z += (z0 + z1 + z2 + z3 + z4 + z5 + z6 + z7 + z8) / 9.0;
  #endif

  pp.z = pow(pp.z, _Height_Exponent);
  pp.z *= _Height_Scale;

  {
    float mask = tex2Dlod(_Height_Mask, float4(vert.uv, _Height_LOD, 0));
    mask = pow(mask, _Height_Mask_Exponent);
    pp.z *= mask;
  }
  
  // 0 at middle, 1 or -1 at edges
  if (_Center_Out_Speed > 0.0) {
    float2 middle_out_uv = vert.uv * 2.0 - 1.0;

    float center_dist2 = length2(middle_out_uv);
    float ring_radius = fmod(_Time[1] * _Center_Out_Speed,
        _Center_Out_Max_Radius - _Center_Out_Min_Radius)
        + _Center_Out_Min_Radius;

    // How far am I from the desired ring?
    float ring_dist = dabs(center_dist2 - ring_radius, _Center_Out_Sharpness);
    float ring_scale = exp(-1.0 * ring_dist);

    float middle_out_height = ring_scale;
    pp.z *= middle_out_height;
  }

  pp = mul(object_rotate, float4(pp, 1.0)).xyz;

  vert.worldPos += pp;
  vert.objPos = mul(unity_WorldToObject, float4(vert.worldPos, 1.0));
  vert.clipPos = UnityObjectToClipPos(vert.objPos);
}

// maxvertexcount == the number of vertices we create
[maxvertexcount(3)]
void geom(triangle v2f tri_in[3],
  uint pid: SV_PrimitiveID,
  inout TriangleStream<v2f> tri_out)
{
  float dx = 0.5;

  v2f cur = tri_in[0];
  displace(cur);
  tri_out.Append(cur);

  cur = tri_in[1];
  displace(cur);
  tri_out.Append(cur);

  cur = tri_in[2];
  displace(cur);
  tri_out.Append(cur);

  tri_out.RestartStrip();
}

float getWorldSpaceDepth(in const float3 worldPos)
{
  float4 clip_pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
  return clip_pos.z / clip_pos.w;
}

float4 effect(inout v2f i, out float depth)
{
  depth = -1000.0;

  float4 albedo = tex2D(_BaseColor, i.uv);
  float3 normal = tex2D(_Normal, i.uv);
  float metallic = tex2D(_Metallic, i.uv);
  float roughness = tex2D(_Roughness, i.uv);
  if (albedo.a > 0) {
    depth = getWorldSpaceDepth(i.worldPos);
  }
  return getLitColor(i, albedo, i.worldPos, normal, metallic, 1.0 - roughness,
      /*custom_cubemap=*/true);

  return 1;
}

fixed4 frag(v2f i, out float depth : SV_DepthLessEqual) : SV_Target
{
  return effect(i, depth);
}

#endif  // DISPLACEMENT_LIGHTING

