shader_type spatial;

uniform vec3 base_color: source_color;
uniform vec3 glow_color: source_color;
global uniform vec3 spherePos2;
global uniform vec3 spherePos3;
uniform float sphereRadius: hint_range(0, 1);
uniform float glow_strength: hint_range(0, 1);
uniform float pulse_strength: hint_range(0, 1);
uniform float pulse_speed: hint_range(1, 10);

varying vec3 wVex;

float sdSphere(vec3 p, float s){
    return length(p)-s;
}

void vertex() {
	wVex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float pulse = sin(TIME * pulse_speed) * pulse_strength;
	float s = sdSphere(wVex - spherePos3, sphereRadius + pulse);
	s = min(s, sdSphere(wVex - spherePos2, sphereRadius + pulse));
	float sdf = pow(s, 4);
	float ratio = 1.0 - clamp(sdf, 0.0, 1.0);
	vec3 alb = mix(base_color, glow_color, ratio);
	ALBEDO = alb;
	// ALBEDO = vec3(sdf);
	EMISSION = alb * ratio * glow_strength;
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
