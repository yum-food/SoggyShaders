#ifndef CLOUD_LIGHTING
#define CLOUD_LIGHTING

#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"
#include "iq_sdf.cginc"
#include "math.cginc"
#include "Motion.cginc"
#include "pbr.cginc"
#include "pema99.cginc"

#define MY_COORD_SCALE 100
#define MY_COORD_SCALE_INV 1.0 / MY_COORD_SCALE
#define OBJ_SPACE_TO_MINE \
  float4x4( \
      MY_COORD_SCALE, 0, 0, 0, \
      0, MY_COORD_SCALE, 0, 0, \
      0, 0, MY_COORD_SCALE, 0, \
      0, 0, 0, MY_COORD_SCALE \
      )
#define WORLD_SPACE_TO_MINE \
  mul(unity_WorldToObject, OBJ_SPACE_TO_MINE)
#define MY_SPACE_TO_OBJ \
  float4x4( \
      MY_COORD_SCALE_INV, 0, 0, 0, \
      0, MY_COORD_SCALE_INV, 0, 0, \
      0, 0, MY_COORD_SCALE_INV, 0, \
      0, 0, 0, MY_COORD_SCALE_INV \
      )
#define MY_SPACE_TO_WORLD \
  mul(MY_SPACE_TO_OBJ, unity_ObjectToWorld)

#define MINIMUM_HIT_DISTANCE .00002 * MY_COORD_SCALE
#define MAXIMUM_TRACE_DISTANCE 20 * MY_COORD_SCALE

float _Ball_Height;
float _Ball_Scale;
float _Cloud_Y_Off;
float _Cloud_Opacity;
float _Cloud_W;
float _Cloud_Scale;
float _Sphere_Scale;
float _Global_Scale;
float4 _Orientation;
float3 _Offset;

// Return the density of the mist at position `p`.
float mist_map(float3 p)
{
  float scale = MY_COORD_SCALE * _Global_Scale;
  float dist_fade = max(length(p / scale) - .8, 0) * 12;
  dist_fade = 1 / (1 + dist_fade);

  p.x += _Time[0] * scale * .1;
  float noise = clamp(fbm(p * _Cloud_Scale / scale, /*n_octaves=*/5, _Cloud_W), 0, 1);
  noise *= noise;

  // On [0,1]
  float y_fade = p.y / scale + .5;
  y_fade -= _Cloud_Y_Off;
  y_fade = max(0, y_fade);
  y_fade = 1 - y_fade;
  noise *= y_fade;

  return clamp(noise * dist_fade, 0, 1);
}

float3 mist_march(float3 ro, float3 rd, out float density)
{
  float3 current_position;
#define CLOUD_MARCH_ITER 7
  float scale = MY_COORD_SCALE * _Global_Scale;
  float step_sz = (float(scale) / CLOUD_MARCH_ITER);
  float total_distance = (CLOUD_MARCH_ITER - 1) * step_sz;

  // Dither starting point to avoid color banding
  total_distance += step_sz * rand3(ro.xyz);

  float mist_v = 0;
  for (int i = CLOUD_MARCH_ITER - 1; (i >= 0); --i)
  {
    current_position = ro + total_distance * rd;

    float4 cur_world_pos = mul(MY_SPACE_TO_WORLD, float4(current_position, MY_COORD_SCALE));
    float d0 = getWorldSpaceDepth(cur_world_pos);
    float d1 = getDepthBufferAt(cur_world_pos);
    //bool use_result = (d0 < d1);
    bool use_result = true;
    {
      float3 axis = _Orientation.xyz;
      float theta = _Orientation.w;

      Quaternion q = Quaternion(axis * cos(theta/2), sin(theta/2));
      current_position = qrot(current_position, q);
    }

    float cur_v = mist_map(current_position) * _Cloud_Opacity;
    float new_mist = cur_v + mist_v * (1 - cur_v);
    mist_v = lerp(mist_v, new_mist, use_result);

    total_distance -= step_sz;
  }

  density = mist_v;

  return current_position;
}

float4 mist_ray_march(float3 ro, float3 rd, inout v2f v2f_i)
{
  float density;
  float3 final_pos = mist_march(ro, rd, density);

  // Mist scatters light. The denser it is, the more it scatters it.
  float r0 = rand3(v2f_i.worldPos + float3(_Time[0], 0, 0));
  float r1 = rand3(v2f_i.worldPos + float3(0, _Time[0], 0));
  float r2 = rand3(v2f_i.worldPos + float3(0, 0, _Time[0]));
  v2f_i.normal = normalize(v2f_i.normal + density * normalize(float3(r0, r1, r2)));

  density = pow(density, 2) * 2;
  density = smoothstep_quintic(density);
  return float4(1, 1, 1, density);
}

float4 ray_march(inout v2f v2f_i)
{
  float4 ray_march_color;
  {
    float3 camera_position = mul(WORLD_SPACE_TO_MINE, float4(_WorldSpaceCameraPos, 1.0)).xyz;
    float3 ro = camera_position;
    float3 mesh_position = mul(WORLD_SPACE_TO_MINE, v2f_i.worldPos).xyz;
    float3 rd = normalize(mesh_position - ro);
    ro = mesh_position;

    float4 mist_color = mist_ray_march(ro, rd, v2f_i);
    ray_march_color = clamp(mist_color, 0, 1);
  }

  return ray_march_color;
}

void getVertexLightColor(inout v2f i)
{
  #if defined(VERTEXLIGHT_ON)
  float3 light_pos = float3(unity_4LightPosX0.x, unity_4LightPosY0.x,
      unity_4LightPosZ0.x);
  float3 light_vec = light_pos - i.worldPos;
  float3 light_dir = normalize(light_vec);
  float ndotl = DotClamped(i.normal, light_dir);
  // Light fills an expanding sphere with surface area 4 * pi * r^2.
  // By conservation of energy, this means that at distance r, light intensity
  // is proportional to 1/(r^2).
  float attenuation = 1 / (1 + dot(light_vec, light_vec) * unity_4LightAtten0.x);
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

  o.uv = v.uv;
  getVertexLightColor(o);

  return o;
}

fixed4 frag(v2f i) : SV_Target
{
  float4 mist_unlit = ray_march(i);

  float4 mist_lit = light(
      i,
      mist_unlit,
      /*metallic=*/0,
      /*smoothness=*/0.7);
  float emission_str = 1.0;
  float4 mist_color = mist_lit + float4((mist_unlit * emission_str).xyz, 0);

  return mist_color;
}

#endif  // CLOUD_LIGHTING
