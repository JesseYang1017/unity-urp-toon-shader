#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// Textures
TEXTURE2D(_ColorMap); SAMPLER(sampler_ColorMap); // RGB = albedo, A = alpha

float4 _ColorMap_ST; // Automatically set by Unity. Used in TRANSFORM_TEX to apply UV tiling.
float4 _ColorTint;
float4 _LightColor;
float4 _ShadowColor;
//float _ShadowThreshold;
float4 _MidColor;
float _MidThreshold;
float _LightThreshold;
float4 _RimColor;
float _RimPower;
float _RimIntensity;

// This attributes struct receives data about the mesh we're currently rendering.
// Data is automatically placed in fields according to their semantics.
struct Attributes {
    float3 positionOS : POSITION; // Vertex position in object space
    float2 uv : TEXCOORD0;        // Material texture UV coordinates
    float3 normalOS : NORMAL;     // Vertex normal in object space
};

// This struct is output by the vertex function and input to the fragment function.
// Note that fields will be interpolated during rasterization.
struct Interpolators {
    float4 positionCS : SV_POSITION; // Vertex position in clip space
    float2 uv : TEXCOORD0;           // Texture UV coordinates
    float3 normalWS : TEXCOORD1;     // Normal in world space
    float3 positionWS : TEXCOORD2;   // Position in world space
};

/*
References:
struct VertexPositionInputs
{
    float3 positionWS;
    float3 positionVS;
    float4 positionCS;
    float4 positionNDC;
};
*/

// The vertex function runs once per vertex.
// It outputs the vertex position in clip space,
// along with the data required by the fragment shader.
Interpolators Vertex(Attributes input) {
    Interpolators output;

    VertexPositionInputs posnInputs =
        GetVertexPositionInputs(input.positionOS);

    output.positionCS = posnInputs.positionCS;

    output.normalWS =
        TransformObjectToWorldNormal(input.normalOS);

    output.uv = TRANSFORM_TEX(input.uv, _ColorMap);

    output.positionWS = posnInputs.positionWS;

    return output;
}

// The fragment function runs once per fragment.
// It calculates and outputs the final fragment color.
float4 Fragment(Interpolators input) : SV_TARGET
{
    // 1. Get the interpolated world-space normal.
    float3 normalWS = normalize(input.normalWS);

    // 2. Get the main directional light.
    Light mainLight = GetMainLight();

    // 3. Get the light direction in world space.
    float3 lightDirWS = normalize(mainLight.direction);

    // 4. Calculate Lambertian diffuse lighting.
    float NdotL = saturate(dot(normalWS, lightDirWS));

    // Calculate the direction from the surface toward the camera.
    float3 viewDirWS = normalize(
        GetWorldSpaceViewDir(input.positionWS)
    );

    // Sample the base color texture using the fragment's UV coordinates.
    float4 colorSample = SAMPLE_TEXTURE2D(
        _ColorMap,
        sampler_ColorMap,
        input.uv
    );

    // Calculate the cosine of the angle between the surface normal and view direction.
    float NdotV = saturate(dot(normalWS, viewDirWS));

    // Rim lighting becomes stronger at grazing angles
    // and weaker when the surface faces the camera.
    float rim = pow(1.0 - NdotV, _RimPower);

    // Determine the lighting bands based on NdotL thresholds.
    float shadowStep = step(_MidThreshold, NdotL);
    float lightStep  = step(_LightThreshold, NdotL);

    // Select between shadow and midtone colors.
    float3 toonColor = lerp(
        _ShadowColor.rgb,
        _MidColor.rgb,
        shadowStep
    );

    // Select the highlight color when the light threshold is reached.
    toonColor = lerp(
        toonColor,
        _LightColor.rgb,
        lightStep
    );

    // Combine the texture color, tint, and toon lighting.
    float3 finalColor =
        colorSample.rgb *
        _ColorTint.rgb *
        toonColor;

    // Calculate the rim lighting contribution.
    float3 rimColor =
        _RimColor.rgb * rim * _RimIntensity;

    // Add rim lighting to the final surface color.
    finalColor += rimColor;

    return float4(finalColor, 1.0);
}