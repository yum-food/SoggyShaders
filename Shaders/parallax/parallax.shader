Shader "yum_food/parallax"
{
  Properties
  {
    _Curvature_Step("Curvature step", float) = .0001
    _Min_Hit_Dist("Min hit distance", float) = .0001
    _Max_Dist("Max ray length", float) = 100.0
    _Ray_March_Steps("Ray march steps", float) = 32
		_Cubemap("Cubemap", Cube) = "" {}

    _Layer0_BaseColor("Layer 0 base color", 2D) = "black" {}
    _Layer0_Normal("Layer 0 normal", 2D) = "bump" {}
    _Layer0_Metallic("Layer 0 metallic", 2D) = "black" {}
    _Layer0_Roughness("Layer 0 roughness", 2D) = "black" {}
    _Layer0_Offset("Layer 0 offset", float) = -0.1
    _Layer0_XScale("Layer 0 X Scale", float) = 1.0
    _Layer0_YScale("Layer 0 Y Scale", float) = 1.0
    _Layer0_Emission("Layer 0 Emission strength", float) = 0.0

    _Layer1_BaseColor("Layer 1 base color", 2D) = "black" {}
    _Layer1_Normal("Layer 1 normal", 2D) = "bump" {}
    _Layer1_Metallic("Layer 1 metallic", 2D) = "black" {}
    _Layer1_Roughness("Layer 1 roughness", 2D) = "black" {}
    _Layer1_Offset("Layer 1 offset", float) = -0.2
    _Layer1_XScale("Layer 1 X Scale", float) = 1.0
    _Layer1_YScale("Layer 1 Y Scale", float) = 1.0
    _Layer1_Emission("Layer 1 Emission strength", float) = 0.0

    _Layer2_BaseColor("Layer 2 base color", 2D) = "black" {}
    _Layer2_Normal("Layer 2 normal", 2D) = "bump" {}
    _Layer2_Metallic("Layer 2 metallic", 2D) = "black" {}
    _Layer2_Roughness("Layer 2 roughness", 2D) = "black" {}
    _Layer2_Offset("Layer 2 offset", float) = -0.3
    _Layer2_XScale("Layer 2 X Scale", float) = 1.0
    _Layer2_YScale("Layer 2 Y Scale", float) = 1.0
    _Layer2_Emission("Layer 2 Emission strength", float) = 0.0

    _Iridescence_Ramp("Iridescence ramp", 2D) = "black" {}
    _Iridescence_Normal("Iridescence normal", 2D) = "bump" {}
    _Iridescence_Offset("Iridescence offset", float) = 0.0
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
      #pragma fragment frag

      #define FORWARD_BASE_PASS

      #define LAYER0_TEXTURES_ON
      #define LAYER1_TEXTURES_ON
      #define LAYER2_TEXTURES_ON
      #define IRIDESCENCE_TEXTURES_ON

      #include "parallax_lighting.cginc"
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
      #pragma fragment frag

      #define LAYER0_TEXTURES_ON
      #define LAYER1_TEXTURES_ON
      #define LAYER2_TEXTURES_ON
      #define IRIDESCENCE_TEXTURES_ON

      #include "parallax_lighting.cginc"
      ENDCG
    }
  }
}

