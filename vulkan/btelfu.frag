#version 450

layout(location = 0) in vec2 uv;
layout(location = 0) out vec4 outColor;

layout(binding = 0) uniform sampler2D prevFrame;
layout(binding = 1) uniform sampler2D cpuFrame;
layout(binding = 2) uniform sampler2D motionVector;

layout(push_constant) uniform Uniforms {
    vec2 resolution;
    float alpha;
    int phases;
} uni;

void main() {
    vec2 mv = texture(motionVector, uv).xy;
    vec2 prev_uv = uv - mv;
    vec3 predicted = texture(prevFrame, prev_uv).rgb;

    vec3 current = texture(cpuFrame, uv).rgb;
    vec3 frameGen = mix(predicted, current, 0.05);

    vec3 enhanced = frameGen * 1.5 - frameGen * 0.25;

    vec3 blur = vec3(0.0);
    int kSize = 5;
    for (int i=0; i<kSize; i++) {
        float offset = (float(i)-kSize/2)/uni.resolution.x;
        blur += texture(cpuFrame, uv + vec2(offset,0.0)).rgb;
    }
    blur /= float(kSize);

    float n = fract(sin(dot(uv*uni.resolution, vec2(12.9898,78.233))) * 43758.5453 + float(uni.phases));
    vec3 noisy = clamp(blur + n*0.02, 0.0, 1.0);

    vec3 taa = mix(predicted, noisy, uni.alpha);

    vec3 fusion = vec3(0.0);
    for (int p=0; p<uni.phases; p++) {
        float shiftX = float((p%3)-1)/uni.resolution.x;
        float shiftY = float((p%3)-1)/uni.resolution.y;
        vec3 phase = texture(cpuFrame, uv + vec2(shiftX, shiftY)).rgb;
        phase += fract(sin(float(p)*12.9898 + 1.0) * 43758.5453) * 0.01;
        fusion += phase / float(uni.phases);
    }

    vec3 finalColor = fusion;
    outColor = vec4(finalColor, 1.0);
}
