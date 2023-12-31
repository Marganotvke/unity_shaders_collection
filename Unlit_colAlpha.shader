// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)
// Modified

// Unlit shader. Simplest possible colored shader.
// - no lighting
// - no lightmap support
// - no texture

Shader "Unlit/ColorAlpha" {
Properties {
    _Color ("Main Color", Color) = (1,1,1,1)
    _Alpha ("Alpha", Range(0,1)) = 1
}

SubShader {
    Tags { "Queue"="Transparent" "RenderType"="Transparent" "DisableBatching" = "True" }
    LOD 100
    Blend SrcAlpha OneMinusSrcAlpha
    Cull Back

    Pass {
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            float _Alpha;

            struct appdata_t {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                UNITY_FOG_COORDS(0)
                UNITY_VERTEX_OUTPUT_STEREO
            };

            fixed4 _Color;

            v2f vert (appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : COLOR
            {
                fixed4 col = _Color;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return float4(col.rgb, _Alpha);
            }
        ENDCG
    }
}

}