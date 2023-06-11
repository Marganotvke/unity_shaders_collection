Shader "Unlit/FCull2CubeRunSelectOpaque"
{
    Properties
    {
        [HDR] _CubeMap( "Cube Map", Cube ) = "grey" {}
        _Exposure("Exposure", Range(0,10)) = 1
        [Space(20)] _UseSecMap("Use Secondary Map", Range(0,1)) = 0
        [HDR] _SecMap("Secondary Map", Cube) = "grey" {}
        _SecExp("Secondary Exposure", Range(0,10)) = 1
    }
    SubShader
    {
        Pass 
        {
            Tags { "RenderType"="Opaque" "Queue"="AlphaTest+51" }
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Front
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #include "UnityCG.cginc"
        
            samplerCUBE _CubeMap;
            samplerCUBE _SecMap;
            half4 _CubeMap_HDR;
            half4 _SecMap_HDR;
            float _Exposure;
            float _SecExp;
            float _UseSecMap;   
        
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
            
            fixed4 frag( v2f i ) : SV_Target
            {
                float3 mainTex_c = DecodeHDR(texCUBE(_CubeMap, i.uv), _CubeMap_HDR);
                float3 secTex_c = DecodeHDR(texCUBE(_SecMap, i.uv), _SecMap_HDR);
                mainTex_c = mainTex_c * float3(0.5,0.5,0.5) * unity_ColorSpaceDouble.rgb;
                mainTex_c *= _Exposure;
                secTex_c = secTex_c * float3(0.5,0.5,0.5) * unity_ColorSpaceDouble.rgb;
                secTex_c *= _SecExp;
                float3 tex_c = mainTex_c+secTex_c*(_UseSecMap==1.0);
                return float4(tex_c, 1);
            }
            ENDCG
        }
    }
}