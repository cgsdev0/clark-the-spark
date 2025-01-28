shader_type spatial;
render_mode unshaded;

void vertex() {
	VERTEX *= 1.01;
	// Called for every vertex the material is visible on.
}

void fragment() {
	float f = sin(UV.y * 120.0 + TIME * 5.0);
	if (f < 0.5) discard;
	float fac = (f - 0.5) / 0.5;
	vec3 col = mix(vec3(1.0), vec3(0.5, 1.0, 1.0), 1.0 - fac);
	EMISSION = col;
	ALBEDO = col;
	ALPHA = fac;
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
