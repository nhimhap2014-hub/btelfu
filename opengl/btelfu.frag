#version 430

in vec2 uv;
out vec4 outColor;

uniform sampler2D prevFrame;
uniform sampler2D cpuFrame;
uniform sampler2D motionVector;

uniform vec2 resolution;
uniform float alpha;
uniform int phases;

void main() {
    vec2 mv = texture(motionVector, uv).xy;
    vec2 prev_uv = uv - mv;
    vec3 predicted = texture(prevFrame, prev_uv).rgb;

    vec3 current = texture(cpuFrame, uv).rgb;
    vec3 frameGen = mix(predicted, current, 0.05);

    vec3 enhanced = frameGen * 1.5 - frameGen * 0.25;

    vec3 blur = vec3(0.0);
    int kSize = 5;
    for (int i = 0; i < kSize; i++) {
        float offset = (float(i) - kSize/2) / resolution.x;
        blur += texture(cpuFrame, uv + vec2(offset, 0.0)).rgb;
    }
    blur /= float(kSize);

    float n = fract(sin(dot(uv*resolution, vec2(12.9898,78.233))) * 43758.5453 + float(phases));
    vec3 noisy = clamp(blur + n*0.02, 0.0, 1.0);

    vec3 taa = mix(predicted, noisy, alpha);

    vec3 fusion = vec3(0.0);
    for (int p = 0; p < phases; p++) {
        float shiftX = float((p%3)-1) / resolution.x;
        float shiftY = float((p%3)-1) / resolution.y;
        vec3 phase = texture(cpuFrame, uv + vec2(shiftX, shiftY)).rgb;
        phase += fract(sin(float(p)*12.9898 + 1.0) * 43758.5453) * 0.01;
        fusion += phase / float(phases);
    }

    outColor = vec4(fusion, 1.0);
}
