﻿Shader "Custom/PrintingShader"
{
    Properties
    {
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_CapTex("Cap", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
		_SlicingPlane("Slicing Plane", Vector) = (0, 0, 0, 0)
		[Toggle(USE_RING)] _UseGlowingRing("Use Glowing Ring", Float) = 0
		_GlowingRingColor("Glowing Ring Color", Color) = (1, 1, 1, 1)
		_GlowingRingThickness("Glowing Ring Thickness", Float) = 0
		_GlowingRingIntensity("Glowing Ring Intensity", Float) = 1
		[Toggle(USE_HOLOGRAM)] _UseHologram("Use Hologram", Float) = 0
		_HologramColor("Hologram Color", Color) = (1, 1, 1, 1)
		_HologramIntensity("Hologram Intensity", Float) = 1
		_HologramTex("Hologram Texture", 2D) = "white" {}

		[Toggle(USE_OUTLINE)] _UseOutline("Use Outline", Float) = 0
		_OutlineColor("Outline Color", Color) = (1, 1, 1, 1)
		_OutlineThickness("Outline Thickness", Range(1.0, 10.0)) = 1.01
		_OutlineIntensity("Outline Intensity", Float) = 1
    }

    SubShader
	{
		/*UsePass "Custom/HologramShader/Hologram_Pass"
		UsePass "Custom/SlicerShader/Slicer_Stencil_FirstPass"
		UsePass "Custom/SlicerShader/Slicer_Stencil_SecondPass"*/


		UsePass "Custom/OutlineShader/Outline_FirstPass"
		UsePass "Custom/OutlineShader/Outline_SecondPass"
		UsePass "Custom/OutlineShader/Outline_FinalPass"

		Tags{ "Queue" = "Transparent+1" }
		Cull Off

		CGPROGRAM

		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows vertex:vert alpha:blend
		#pragma shader_feature USE_RING

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		uniform float4 _SlicingPlane;
		uniform float4 _GlowingRingColor;
		uniform float _GlowingRingThickness;
		uniform float _GlowingRingIntensity;

		sampler2D _MainTex;

		struct Input
		{
			float2 uv_MainTex;

			float3 fragWorldPos : TEXCOORD0;
		};

		void vert(inout appdata_full v, out Input o) 
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.fragWorldPos = mul(UNITY_MATRIX_M, v.vertex);
		}

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		void Slice(float4 plane, float3 fragPos)
		{
			float distance = dot(fragPos.xyz, plane.xyz) + plane.w;

			if (distance > 0)
			{
				discard;
			}
		}

		float DrawEmissionRing(float4 plane, float3 fragPos, float4 glowingRingColor, float glowingRingThickness)
		{
			float distance1 = dot(fragPos.xyz, plane.xyz) + plane.w + glowingRingThickness;

			if (distance1 > 0)
			{
				return 1;
			}

			return 0;
		}

		void surf(Input IN, inout SurfaceOutputStandard o)
		{
			// Albedo comes from a texture tinted by color
			Slice(_SlicingPlane, IN.fragWorldPos);
#if USE_RING
			float em = DrawEmissionRing(_SlicingPlane, IN.fragWorldPos, _GlowingRingColor, _GlowingRingThickness);

			if (em > 0)
			{
				fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
				o.Albedo = _GlowingRingColor.rgb * _GlowingRingIntensity;

				o.Alpha = c.a;
			}
			else
			{
				o.Emission = (0, 0, 0, 0);
				fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
				o.Albedo = c.rgb;
				o.Metallic = _Metallic;
				o.Smoothness = _Glossiness;
				o.Alpha = c.a;
			}
#else
			o.Emission = (0, 0, 0, 0);
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
#endif

		}
		ENDCG


	}
	FallBack "Diffuse"
}