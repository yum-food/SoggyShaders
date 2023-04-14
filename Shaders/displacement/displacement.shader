Shader "yum_food/displacement"
{
  Properties
  {
    _BaseColor("Base color", 2D) = "white" {}
    _Normal("Normal", 2D) = "bump" {}
    _Metallic("Metallic", 2D) = "black" {}
    _Roughness("Roughness", 2D) = "black" {}
		_Cubemap("Cubemap", Cube) = "" {}

    _Height("Height", 2D) = "black" {}
    _Height_LOD("Height LOD", float) = 8.0
    _Height_Scale("Height scale", float) = 1.0
    _Height_Exponent("Height exponent", float) = 1.0
    _Height_Speed_X("Height speed (X axis)", float) = 0.0
    _Height_Speed_Y("Height speed (Y axis)", float) = 0.0
    _Height_AA_Sample_Scale("Height anti-alias UV scale", float) = 0.001

    _Height_Mask("Height mask", 2D) = "white" {}
    _Height_Mask_Exponent("Height mask exponent", float) = 1.0

    _Center_Out_Speed("Center out speed", float) = 0.0
    _Center_Out_Sharpness("Center out sharpness", float) = 4.0
    _Center_Out_Min_Radius("Center out min radius", float) = -1.0
    _Center_Out_Max_Radius("Center out max radius", float) = 2.7
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
      ZWrite On
      ZTest LEqual
      Cull Off

      CGPROGRAM
      #pragma target 5.0

      #pragma multi_compile _ VERTEXLIGHT_ON

      #pragma vertex vert
      #pragma geometry geom
      #pragma fragment frag

      #define FORWARD_BASE_PASS

      // Three anti-aliasing levels.
      // 0: no anti-aliasing
      // 1: sample 4 neighbors (diagonals)
      // 2: sample 8 neighbors (diagonals + cartesian)
      #define OFFSET_AA_LEVEL 2

      #include "displacement_lighting.cginc"
      ENDCG
    }
    Pass {
      Tags {
        "RenderType" = "Opaque"
        "LightMode" = "ForwardAdd"
        "Queue"="AlphaTest+499"
      }
      Blend One One
      ZWrite On
      ZTest LEqual
      Cull Off

      CGPROGRAM
      #pragma target 5.0

      #pragma multi_compile_fwdadd

      #pragma vertex vert
      #pragma geometry geom
      #pragma fragment frag

      #define OFFSET_AA_LEVEL 2

      #include "displacement_lighting.cginc"
      ENDCG
    }
  }
}

