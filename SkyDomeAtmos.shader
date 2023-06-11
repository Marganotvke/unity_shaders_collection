// Heavily inspired by the default skybox shader and some other people's atmospheric shader.

Shader "Custom/SkyDomeAtmos" {
    Properties {
        [Space(20)][Header(Atmosphere)]
        // Atmosphere simulation parameters
        _AtmosphereThickness ("Atmosphere Thickness", float) = 1
        _AtmosphereDensity ("Atmosphere Density", float) = 0.5
        _AtmosphereInsideRadius ("Inside Radius", float) = 0.0
        _AtmosphereOutsideRadius ("Outside Radius", float) = 1.0
        _AtmosphereColor ("Atmosphere Color", Color) = (1, 1, 1, 1)
        _AtmosphereScattering ("Atmosphere Scattering", Range(0.0, 1.0)) = 1.0
        _AtmosphereG ("Atmosphere G", Range(-1.0, 1.0)) = 0.22
    }

    CGINCLUDE
    #include "UnityCG.cginc"

    float _AtmosphereThickness;
    float _AtmosphereDensity;
    float _AtmosphereInsideRadius;
    float _AtmosphereOutsideRadius;
    float4 _AtmosphereColor;
    float _AtmosphereScattering;
    float _AlphaThres;
    float _AtmosphereG;

    float3 ApplyAtmosphere(float3 rayDir, float3 worldNormal) {
    // Calculate atmosphere scattering color
        float3 scatteringColor = _AtmosphereColor.rgb;
        float3 extinctionColor = exp(-_AtmosphereDensity * (_AtmosphereOutsideRadius - _AtmosphereInsideRadius));
        float3 transmittanceColor = exp(-_AtmosphereDensity * (_AtmosphereOutsideRadius - _AtmosphereInsideRadius));
        float3 opticalDepth = (extinctionColor + scatteringColor) * (_AtmosphereOutsideRadius - _AtmosphereInsideRadius);
        float3 singleScatteringColor = scatteringColor * _AtmosphereScattering;
        float3 rayleighColor = singleScatteringColor * (_AtmosphereThickness * (1.0 - _AtmosphereScattering));
        float3 mieColor = singleScatteringColor * _AtmosphereThickness * _AtmosphereScattering;
        float3 phaseFunction = (1.0 - _AtmosphereG * _AtmosphereG) / (4.0 * UNITY_PI * pow(1.0 + _AtmosphereG * _AtmosphereG - 2.0 * _AtmosphereG * dot(rayDir, worldNormal), 1.5));

        // Calculate the angle between the ray direction and the surface normal
        float cosTheta = dot(rayDir, worldNormal);

        // Adjust the optical depth based on the angle between the ray direction and the surface normal
        float3 adjustedOpticalDepth = opticalDepth * pow(transmittanceColor, cosTheta);

        float3 scatteringTerm = adjustedOpticalDepth * (rayleighColor * phaseFunction.x + mieColor * phaseFunction.y);

        // Combine sky and atmosphere color
        return scatteringTerm;
    }
    ENDCG

    SubShader {
        Pass
        {
            Tags { "RenderType"="Transparent" "Queue"="Transparent"}
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Front
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.0
            #include "UnityCG.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 uv : TEXCOORD0;
            };
            
            v2f vert (appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.vertex.xyz * half3(-1, 1, 1);
                return o;
            }

            fixed4 frag(v2f i): SV_Target
            {
                float3 rayDir = normalize(i.uv);
                float3 finalC = ApplyAtmosphere(rayDir, normalize(i.uv*float3(1,-1,1)));
                return float4(finalC, dot(finalC.rgb,float3(0.299, 0.587, 0.114)));
            }
            ENDCG
        }
    }
}