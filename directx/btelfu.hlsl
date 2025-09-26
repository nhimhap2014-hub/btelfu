// frameShader.hlsl
cbuffer Uniforms : register(b0)
{
    float2 resolution;
    float alpha;
    int phases;
};

Texture2D prevFrame : register(t0);
Texture2D cpuFrame : register(t1);
Texture2D motionVector : register(t2);
SamplerState linearSampler : register(s0);

struct PSInput
{
    float2 uv : TEXCOORD0;
};

float3 proceduralNoise(float2 uv, int phases)
{
    float n = frac(sin(dot(uv*resolution, float2(12.9898,78.233))) * 43758.5453 + float(phases));
    return float3(n * 0.02, n * 0.02, n * 0.02);
}

float4 main(PSInput input) : SV_Target
{
    float2 uv = input.uv;

    // ===== Frame Generation via Motion Vector =====
    float2 mv = motionVector.Sample(linearSampler, uv).xy;
    float2 prev_uv = uv - mv;
    float3 predicted = prevFrame.Sample(linearSampler, prev_uv).rgb;

    float3 current = cpuFrame.Sample(linearSampler, uv).rgb;
    float3 frameGen = lerp(predicted, current, 0.05);

    float3 enhanced = frameGen * 1.5 - frameGen * 0.25;

    float3 blur = float3(0.0, 0.0, 0.0);
    int kSize = 5;
    [unroll]
    for(int i=0; i<kSize; i++)
    {
        float offset = (float(i)-kSize/2)/resolution.x;
        blur += cpuFrame.Sample(linearSampler, uv + float2(offset,0.0)).rgb;
    }
    blur /= kSize;

    float3 noisy = clamp(blur + proceduralNoise(uv, phases), 0.0, 1.0);
    float3 taa = lerp(predicted, noisy, alpha);

    float3 fusion = float3(0.0, 0.0, 0.0);
    [unroll]
    for(int p=0; p<phases; p++)
    {
        float shiftX = float((p%3)-1)/resolution.x;
        float shiftY = float((p%3)-1)/resolution.y;
        float3 phase = cpuFrame.Sample(linearSampler, uv + float2(shiftX, shiftY)).rgb;
        phase += frac(sin(float(p)*12.9898 + 1.0) * 43758.5453)*0.01;
        fusion += phase / float(phases);
    }

    return float4(fusion, 1.0);
}
