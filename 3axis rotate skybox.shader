Shader "Custom/3axis rotate skybox cubemap exp" {
Properties {
    _Tint ("Tint Color", Color) = (.5, .5, .5, .5)
    [Gamma] _Exposure ("Exposure", Range(0, 8)) = 1.0
     _RotationX ("RotationX", Range(0, 360)) = 0
     _RotationY ("RotationY", Range(0, 360)) = 0
     _RotationZ ("RotationZ", Range(0, 360)) = 0
    //  _RotationAxis("Rotation axis", Vector) = (0, 1, 0)
    [NoScaleOffset] _Tex ("Cubemap   (HDR)", Cube) = "grey" {}
}

SubShader {
    Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
    Cull Off ZWrite Off

    Pass {

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma target 2.0

        #include "UnityCG.cginc"

        samplerCUBE _Tex;
        half4 _Tex_HDR;
        half4 _Tint;
        half _Exposure;
        float _RotationX;
        float _RotationY;
        float _RotationZ;

        // float3 RotateAroundYInDegrees (float3 vertex, float degrees)
        // {
        //     float alpha = degrees * UNITY_PI / 180.0;
        //     float sina, cosa;
        //     sincos(alpha, sina, cosa);
        //     float2x2 m = float2x2(cosa, -sina, sina, cosa);
        //     return float3(mul(m, vertex.xz), vertex.y).xzy;
        // }

        float4x4 rotationMatrix(float3 axis, float angle)
        {
            axis = normalize(axis);
            float s = sin(angle);
            float c = cos(angle);
            float oc = 1.0 - c;
            
            return float4x4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                            oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                            oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                            0.0,                                0.0,                                0.0,                                1.0);
        }

        struct appdata_t {
            float4 vertex : POSITION;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct v2f {
            float4 vertex : SV_POSITION;
            float3 texcoord : TEXCOORD0;
            UNITY_VERTEX_OUTPUT_STEREO
        };

        v2f vert (appdata_t v)
        {
            v2f o;
            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
            float3 rotated = mul( rotationMatrix( normalize(float3(0,1,0).xyz), _RotationY * UNITY_PI / 180.0), v.vertex).xyz;
            rotated = mul( rotationMatrix( normalize(float3(1,0,0).xyz), _RotationX * UNITY_PI / 180.0), rotated).xyz;
            rotated = mul( rotationMatrix( normalize(float3(0,0,1).xyz), _RotationZ * UNITY_PI / 180.0), rotated).xyz;
            o.vertex = UnityObjectToClipPos(rotated);
            o.texcoord = v.vertex.xyz;
            return o;
        }

        fixed4 frag (v2f i) : SV_Target
        {
            half4 tex = texCUBE (_Tex, i.texcoord);
            half3 c = DecodeHDR (tex, _Tex_HDR);
            c = c * _Tint.rgb * unity_ColorSpaceDouble.rgb;
            c *= _Exposure;
            return half4(c, 1);
        }
        ENDCG
    }
}
Fallback Off
}


 