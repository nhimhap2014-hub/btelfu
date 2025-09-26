#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct Uniforms {
    float2 resolution;
    float alpha;      // TAA alpha
    int phases;       // HTFP
};

// Textures
texture2d<float, access::sample> prevFrame [[texture(0)]];
texture2d<float, access::sample> cpuFrame [[texture(1)]];
texture2d<float, access::sample> motionVector [[texture(2)]];

// Linear sampler for high-quality upscaling
sampler highQualitySampler(filter::linear,
                           mip_filter::linear,
                           address::clamp_to_edge,
                           max_anisotropy: 8);

fragment float4 frameShader(VertexOut in [[stage_in]],
                            constant Uniforms& uni [[buffer(0)]]) {
    float2 uv = in.uv;

    // ===== Frame Generation via Motion Vector =====
    float2 mv = motionVector.sample(highQualitySampler, uv).xy;
    float2 prev_uv = uv - mv;
    float3 predicted = prevFrame.sample(highQualitySampler, prev_uv).rgb;

    // Fallback cho pixel mới
    float3 current = cpuFrame.sample(highQualitySampler, uv).rgb;
    float3 frameGen = mix(predicted, current, 0.05); // weight nhỏ nếu mới xuất hiện

    // ===== Enhancement (Sharpen) =====
    float3 enhanced = frameGen * 1.5 - frameGen * 0.25;

    // ===== Motion Blur (basic) =====
    float3 blur = float3(0.0);
    int kSize = 5;
    for (int i=0;i<kSize;i++) {
        float offset = (float(i) - kSize/2.0) / uni.resolution.x;
        blur += cpuFrame.sample(highQualitySampler, uv + float2(offset,0.0)).rgb;
    }
    blur /= kSize;

    // ===== Procedural Noise =====
    float n = fract(sin(dot(uv*uni.resolution, float2(12.9898,78.233))) * 43758.5453 + float(uni.phases));
    float3 noisy = clamp(blur + n*0.02, 0.0, 1.0);

    // ===== Temporal AA =====
    float3 taa = mix(predicted, noisy, uni.alpha);

    // ===== HTFP =====
    float3 fusion = float3(0.0);
    for (int p=0;p<uni.phases;p++) {
        float shiftX = float((p%3)-1)/uni.resolution.x;
        float shiftY = float((p%3)-1)/uni.resolution.y;
        float3 phase = cpuFrame.sample(highQualitySampler, uv + float2(shiftX, shiftY)).rgb;
        phase += fract(sin(float(p)*12.9898 + 1.0) * 43758.5453)*0.01;
        fusion += phase/float(uni.phases);
    }

    float3 finalColor = fusion;

    return float4(finalColor, 1.0);
}
