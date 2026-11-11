shader_type canvas_item;
render_mode unshaded;
uniform vec4 region = vec4(0.0, 0.0, 0.333333, 0.5);
// Blend the two independently painted edges rather than mirror the landscape.
void fragment() {
	vec2 p = (UV - region.xy) / region.zw;
	float u = p.x * 0.9 + 0.1;
	vec2 inset = TEXTURE_PIXEL_SIZE * 0.5;
	vec2 lo = region.xy + inset;
	vec2 hi = region.xy + region.zw - inset;
	vec4 a = texture(TEXTURE, clamp(region.xy + vec2(u, p.y) * region.zw, lo, hi));
	vec4 b = texture(TEXTURE, clamp(region.xy + vec2(u - 0.9, p.y) * region.zw, lo, hi));
	COLOR = mix(a, b, smoothstep(0.9, 1.0, u)) * COLOR;
}
