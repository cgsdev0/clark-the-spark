shader_type canvas_item;
render_mode unshaded;

uniform float circle_size : hint_range(0.0, 1.05);
uniform float screen_width;
uniform float screen_height;
uniform float falloff : hint_range(0.05, 0.2);

void fragment() {
	float ratio = screen_width / screen_height;
	float dist = distance(vec2(0.5, 0.5), vec2(mix(0.5, UV.x, ratio), UV.y));
	float ramp = 1.0 - clamp(circle_size - 1.05 + falloff, 0.0, falloff) / falloff;
	COLOR.a = min(ramp, step(circle_size, dist));
}