Shader "Unlit/InverseCullCubeMapNoAlpha"
{
    Properties
    {
        _CubeMap( "Cube Map", Cube ) = "white" {}
        _Threshold("Threshold", Range(0,1)) = 0.5
        _Alpha("Alpha", Range(0,1)) = 1
    }
    SubShader
    {
        Pass 
        {
            Tags { "Queue"="Transparent" "RenderType"="Transparent" "DisableBatching" = "True" }
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
        
            samplerCUBE _CubeMap;
            float _Threshold;
            float _Alpha;
        
            struct v2f 
            {
                float4 pos : SV_Position;
                half3 uv : TEXCOORD0;
            };
        
            v2f vert( appdata_img v )
            {
                v2f o;
                o.pos = UnityObjectToClipPos( v.vertex );
                o.uv = v.vertex.xyz * half3(-1,1,1); // mirror so cubemap projects as expected
                return o;
            }
        
            fixed4 frag( v2f i ) : SV_Target 
            {
                float4 tex = texCUBE(_CubeMap, i.uv);
                tex.a = smoothstep(_Threshold, _Threshold, 0.333 * (tex.r + tex.g + tex.b));
                tex.a *= _Alpha;
                return tex;
            }
            ENDCG
        }
    }
}