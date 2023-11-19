#ifndef GRASS_LIGHTING
#define GRASS_LIGHTING

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
sampler2D _Wind_Speed;

bool _Disable_Normal_Texture;

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
  o.uv = v.uv;

  getVertexLightColor(o);

  return o;
}

// maxvertexcount == the number of vertices we create
[maxvertexcount(48)]
void geom(triangle v2f tri_in[3],
  uint pid: SV_PrimitiveID,
  inout TriangleStream<v2f> tri_out)
{
  // Generate copies.
  for (int x = 0; x < 4; x++)
  for (int y = 0; y < 4; y++) {
    float xoff = (x - 1) * 10;
    float yoff = (y - 1) * 10;
    v2f v0 = tri_in[0];
    v2f v1 = tri_in[1];
    v2f v2 = tri_in[2];

    v0.worldPos += float3(xoff, 0, yoff);
    v1.worldPos += float3(xoff, 0, yoff);
    v2.worldPos += float3(xoff, 0, yoff);

    // Apply wind using a noise texture.
    for (int i = 0; i < 3; i++)
    {
      float3 vertex_pos;
      [forcecase] switch (i) {
        case 0:
          vertex_pos = v0.worldPos;
          break;
        case 1:
          vertex_pos = v1.worldPos;
          break;
        case 2:
          vertex_pos = v2.worldPos;
          break;
        default:
          vertex_pos = 0;
          break;
      }
      float3 wind_point = vertex_pos;
      wind_point *= .02;
      wind_point.x -= _Time[0]/2;
      float3 dx = float3(.02, 0, 0);

      float w0 = tex2Dlod(_Wind_Speed, float4(wind_point.x, wind_point.z, 0, 0));
      float w1 = tex2Dlod(_Wind_Speed, float4(wind_point.x + dx.x, wind_point.z, 0, 0));
      float w2 = tex2Dlod(_Wind_Speed, float4(wind_point.x, wind_point.z + dx.x, 0, 0));

      float2 wind_speed = float2(w1 - w0, w2 - w0);
      wind_speed *= 4;
      wind_speed *= vertex_pos.y;

      switch (i) {
        case 0:
          v0.worldPos += float3(wind_speed.x, 0, wind_speed.y);
          break;
        case 1:
          v1.worldPos += float3(wind_speed.x, 0, wind_speed.y);
          break;
        case 2:
          v2.worldPos += float3(wind_speed.x, 0, wind_speed.y);
          break;
      }
    }

    v0.objPos = mul(unity_WorldToObject, v0.worldPos);
    v1.objPos = mul(unity_WorldToObject, v1.worldPos);
    v2.objPos = mul(unity_WorldToObject, v2.worldPos);

    v0.clipPos = UnityObjectToClipPos(v0.objPos);
    v1.clipPos = UnityObjectToClipPos(v1.objPos);
    v2.clipPos = UnityObjectToClipPos(v2.objPos);

    tri_out.Append(v0);
    tri_out.Append(v1);
    tri_out.Append(v2);
    tri_out.RestartStrip();
  }
}

float getWorldSpaceDepth(in const float3 worldPos)
{
  float4 clip_pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
  return clip_pos.z / clip_pos.w;
}

float4 effect(inout v2f i, out float depth)
{
  depth = getWorldSpaceDepth(i.worldPos);

  //float4 albedo = tex2D(_BaseColor, i.uv);
  float4 albedo;
  {
    float3 green = HSVtoRGB(float3(.333, .60, .70));
    float3 brown = HSVtoRGB(float3(.113, .59, .65));
    float uv_t0 = .85;
    float uv_t1 = .50;
    float uv_phase = (i.uv.y - uv_t0) / (uv_t1 - uv_t0);
    uv_phase = clamp(uv_phase, 0, 1);
    float3 c = lerp(brown, green, uv_phase);
    albedo = float4(c, 1.0);
  }
  albedo *= 0.8;

  float3 normal = i.normal;
  // Rotate the normals a little to make the blades of grass appear more
  // rounded.
  {
    float3 nt = mul(unity_WorldToObject, float4(normal, 1.0)).xyz;
    float theta = 1.2;
    theta = (i.uv.x - 0.5) * 2 * theta;
    float2x2 rot = float2x2(
        cos(theta), -sin(theta),
        sin(theta), cos(theta));
    nt.xz = mul(rot, nt.xz);
    normal = mul(unity_ObjectToWorld, float4(nt, 1.0)).xyz;
  }

  float metallic = 0.5;
  float roughness = 0.2;

  return getLitColor(i, albedo, i.worldPos, normal, metallic, 1.0 - roughness,
      /*custom_cubemap=*/true);
}

fixed4 frag(v2f i, out float depth : SV_DepthLessEqual) : SV_Target
{
  return effect(i, depth);
}

#endif  // GRASS_LIGHTING

