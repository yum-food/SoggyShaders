Shader "yum_food/avatar_clone"
{
  Properties
  {
    _BaseColor("Base color", 2D) = "white" {}
    _Emission("Emission", 2D) = "black" {}
    _Emission_Strength("Emission strength", float) = 0.0
    _Normal("Normal", 2D) = "bump" {}
    [ToggleUI] _Disable_Normal_Texture("Disable normal texture", float) = 1
    [ToggleUI] _Disable_Normal_Recalc("Disable normal recalculation", float) = 1
    _Metallic("Metallic", 2D) = "black" {}
    _Roughness("Roughness", 2D) = "black" {}
		_Cubemap("Cubemap", Cube) = "" {}

    _Height("Height", 2D) = "black" {}
    [IntRange] _Height_LOD("Height LOD", Range(0, 8)) = 8
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

    [IntRange] _Num_Clones("Number of clones", Range(0, 4)) = 0
    _Clone_dx("Clone 0 dx", float) = 1.0
    _Clone_dy("Clone 0 dy", float) = 0.0
    _Clone_dz("Clone 0 dz", float) = 0.0
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
      Cull Back

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
      #define HEIGHT_AA_LEVEL 2

      #include "avatar_clone_lighting.cginc"
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
      Cull Back

      CGPROGRAM
      #pragma target 5.0

      #pragma multi_compile_fwdadd

      #pragma vertex vert
      #pragma geometry geom
      #pragma fragment frag

      #define HEIGHT_AA_LEVEL 2

      #include "avatar_clone_lighting.cginc"
      ENDCG
    }
  }
}

