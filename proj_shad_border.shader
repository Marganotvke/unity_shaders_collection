// https://forum.unity.com/threads/projector-project-to-back-faces-problem.150837/
// https://forum.unity.com/threads/add-one-pixel-border-to-a-rendertexture-result-in-shader.389121/

Shader "Projector/LightAdvanced2Border" {
	Properties {
		_ShadowTex ("Cookie", 2D) = "" {}
		// _FalloffTex ("FallOff", 2D) = "" {}
		_IntenceVal("Intensity", Range(1, 100)) = 1
		_ProjectorDir ("_ProjectorDir", Vector) = (0,0,0,0)
		_AngleLimit("Angle Limit", Float) = .9
	}
	
	Subshader {
		Tags {"Queue"="Transparent"}
		Pass {
			ZWrite Off
			ColorMask RGB
			Blend DstColor One
			Offset -1, -1
	
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#include "UnityCG.cginc"

			struct appdata_v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 uvShadow : TEXCOORD0;
				float4 uvFalloff : TEXCOORD1;
				UNITY_FOG_COORDS(2)
				float4 pos : SV_POSITION;
				half projAngle : TEXCOORD2;
			};
			
			float4x4 unity_Projector;
			float4x4 unity_ProjectorClip;  
			fixed4 _ProjectorDir;

			inline half angleBetween(half3 vector1, half3 vector2)
			{
				return acos(dot(vector1, vector2) / (length(vector1) * length(vector2)));
			}
			
			v2f vert (appdata_v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uvShadow = mul (unity_Projector, v.vertex);
				float3 worldNormal = mul(unity_ObjectToWorld, float4(v.normal, 0.0)).xyz;
				o.uvFalloff = mul (unity_ProjectorClip, v.vertex);
				o.uvFalloff.a *= max(0, sign(-dot(_ProjectorDir, worldNormal)));
				o.projAngle = abs(angleBetween(half3(0,0,-1), mul(unity_Projector, v.normal)));
				UNITY_TRANSFER_FOG(o,o.pos);
				return o;
			}
			
			fixed _IntenceVal;
			sampler2D _ShadowTex;
			sampler2D _FalloffTex;
			half _AngleLimit;
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 texS = tex2Dproj (_ShadowTex, UNITY_PROJ_COORD(i.uvShadow));
				texS.rgb *=  _IntenceVal;
				float2 uv = i.uvShadow.xy / i.uvShadow.w;
				float2 uvmasks = min(uv, 1.0 - uv);
				float mask = min(uvmasks.x, uvmasks.y);
				texS.rgb = mask < 0.0 ? float3(0.0, 0.0, 0.0) : texS.rgb;
				texS.a = 1.0-texS.a;

				// tesF = tex2Dproj (_FalloffTex, UNITY_PROJ_COORD(i.uvFalloff));
				// fixed4 res = texS * texF.a* ceil(abs(i.uvFalloff.a))* step(-_AngleLimit, -i.projAngle);
				fixed4 res = texS * step(-_AngleLimit, -i.projAngle) * ceil(abs(i.uvFalloff.a));

				UNITY_APPLY_FOG_COLOR(i.fogCoord, res, fixed4(0,0,0,0));
				return res;
			}
			ENDCG
		}
	}
}