Shader "NedMakesGames/MyLit" {
    // Properties are options set per material, exposed by the material inspector
    Properties{
        [Header(Surface options)] // Creates a text header
        // [MainTexture] and [MainColor] allow Material.mainTexture and Material.color to use the correct properties
        [MainTexture] _ColorMap("Color", 2D) = "white" {}
        [MainColor] _ColorTint("Tint", Color) = (1, 1, 1, 1)
        _LightColor("Light Color", Color) = (1, 0.8, 0.5, 1)
        _ShadowColor("Shadow Color", Color) = (0.2, 0.3, 0.6, 1)
        //_ShadowThreshold("Shadow Threshold", Range(0, 1)) = 0.5
        _MidColor("Midtone Color", Color) = (0.6, 0.65, 0.8, 1)
        _MidThreshold("Mid Threshold", Range(0, 1)) = 0.3
        _LightThreshold("Light Threshold", Range(0, 1)) = 0.7
        _RimColor("Rim Color", Color) = (0.2, 0.8, 1, 1)
        _RimPower("Rim Power", Range(1, 10)) = 3
        _RimIntensity("Rim Intensity", Range(0, 2)) = 1
    }
        // Subshaders allow for different behaviour and options for different pipelines and platforms
            SubShader{
            // These tags are shared by all passes in this sub shader
            Tags{"RenderPipeline" = "UniversalPipeline"}

            // Shaders can have several passes which are used to render different data about the material
            // Each pass has it's own vertex and fragment function and shader variant keywords
            Pass {
                Name "ForwardLit" // For debugging
                Tags{"LightMode" = "UniversalForward"} // Pass specific tags. 
                // "UniversalForward" tells Unity this is the main lighting pass of this shader

                HLSLPROGRAM // Begin HLSL code
                // Register our programmable stage functions
                #pragma vertex Vertex
                #pragma fragment Fragment 

                // Include our code file
                #include "MyLitForwardLitPass.hlsl"
                ENDHLSL
            }
        }
}