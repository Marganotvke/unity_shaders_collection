Shader "Unlit/F-CullDoubleCubeMap"
{
    Properties
    {
        [HDR] _CubeMap( "Cube Map", Cube ) = "grey" {}
        _Exposure("Exposure", Range(0,10)) = 1
        [Space(20)] [Toggle(_enable_sec)] _Secondary("Enable Secondary Texture", Int) = 0
        [HDR] _SecMap("Secondary Map", Cube) = "grey" {}
        _SecExp("Secondary Exposure", Range(0,10)) = 1
        [Space(20)] _Alpha("Global Alpha", Range(0,1)) = 1
    }
    SubShader
    {
        Pass 
        {
            Tags { "Queue"="Transparent" "RenderType"="Transparent" "DisableBatching" = "True" }
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Front
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma shader_feature _enable_sec
            #include "UnityCG.cginc"
        
            samplerCUBE _CubeMap;
            samplerCUBE _SecMap;
            half4 _CubeMap_HDR;
            half4 _SecMap_HDR;
            float _Alpha;
            float _Exposure;
            float _SecExp;
        
            struct v2f 
            {
                float4 pos : SV_Position;
                half3 uv : TEXCOORD0;
            };
        
            v2f vert( appdata_img v )
            {
                v2f o;
                o.pos = UnityObjectToClipPos( v.vertex );
                o.uv = v.vertex.xyz; // mirror so cubemap projects as expected
                return o;
            }
            
            #ifdef _enable_sec
            fixed4 frag( v2f i ) : SV_Target
            {
                float3 mainTex_c = DecodeHDR(texCUBE(_CubeMap, i.uv), _CubeMap_HDR);
                float3 secTex_c = DecodeHDR(texCUBE(_SecMap, i.uv), _SecMap_HDR);
                mainTex_c = mainTex_c * float3(0.5,0.5,0.5) * unity_ColorSpaceDouble.rgb;
                mainTex_c *= _Exposure;
                secTex_c = secTex_c * float3(0.5,0.5,0.5) * unity_ColorSpaceDouble.rgb;
                secTex_c *= _SecExp;
                float3 tex_c = mainTex_c+secTex_c;
                return float4(tex_c, _Alpha);
            }
            #else
            fixed4 frag( v2f i ) : SV_Target 
            {
                float4 tex = texCUBE(_CubeMap, i.uv);
                float3 tex_c = DecodeHDR(tex, _CubeMap_HDR);
                tex_c = tex_c * float3(0.5,0.5,0.5) * unity_ColorSpaceDouble.rgb;
                tex_c *= _Exposure;
                return float4(tex_c, _Alpha);
            }
            #endif
            ENDCG
        }
    }
}