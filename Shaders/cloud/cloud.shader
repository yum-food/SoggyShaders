Shader "yum_food/cloud"
{
  Properties
  {
    _Ball_Height("Ball height", float) = 0.15
    _Ball_Scale("Ball scale", float) = 1.0
    _Cloud_Y_Off("cloud Y offset", float) = -.3
    _Cloud_Opacity("cloud opacity", float) = 0.25
    _Cloud_W("cloud FBM W=", float) = 0.35
    _Cloud_Scale("cloud scale", float) = 2
    _Sphere_Scale("Sphere scale", float) = 1
    _Global_Scale("Global scale", float) = 1
    _Orientation("Orientation (axis and angle in radians)", Vector) = (1, 0, 0, 0)
    _Offset("Offset (meters)", Vector) = (0, 0, 0, 0)

    [MaterialToggle] _Enable_Matcap("Enable matcap", float) = 1
    _Matcap("Matcap", 2D) = "black" {}
    _Matcap_Str("Matcap strength", float) = 1.0
    _Matcap_Mode("Matcap mode: 1 add, 2 mul, 3 replace, 4 sub", Range(1,4)) = 1

    [MaterialToggle] _Enable_Custom_Cubemap("Enable custom cubemap", float) = 0
		_Custom_Cubemap("Custom cubemap", Cube) = "" {}
  }
  SubShader
  {
    Pass {
      Tags {
        "RenderType"="Opaque"
        "Queue"="AlphaTest+499"
        "LightMode" = "ForwardBase"
      }
      Blend SrcAlpha OneMinusSrcAlpha
      Cull Back
      ZTest LEqual

      CGPROGRAM
      #pragma target 5.0

      #pragma multi_compile _ VERTEXLIGHT_ON

      #pragma vertex vert
      #pragma fragment frag

      #define FORWARD_BASE_PASS

      #include "cloud_lighting.cginc"
      ENDCG
    }
    Pass {
      Tags {
        "RenderType" = "Opaque"
        "LightMode" = "ForwardAdd"
        "Queue"="AlphaTest+499"
      }
      Blend One One
      Cull Back
      ZTest LEqual

      CGPROGRAM
      #pragma target 5.0

      #pragma multi_compile_fwdadd

      #pragma vertex vert
      #pragma fragment frag

      #include "cloud_lighting.cginc"
      ENDCG
    }
  }
  //CustomEditor "TaSTTShaderGUI"
}
