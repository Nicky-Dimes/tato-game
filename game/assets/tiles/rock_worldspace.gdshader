shader_type canvas_item;
render_mode unshaded;
uniform sampler2D rock_texture : source_color, repeat_enable, filter_linear;
uniform sampler2D rock_mask : filter_linear;
uniform float rock_strength : hint_range(0.0, 1.0) = 0.94;
uniform float rock_world_span = 320.0;
uniform vec4 rock_region = vec4(0.0, 0.0, 1.0, 1.0);
varying vec2 rock_world_uv;
varying vec4 vertex_tint;
void vertex() {
    vertex_tint = COLOR;
    rock_world_uv = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy / rock_world_span;
}
vec3 sample_rock(vec2 p) {
    vec2 inset = vec2(0.0005);
    vec2 uv = clamp(rock_region.xy + p * rock_region.zw, rock_region.xy + inset, rock_region.xy + rock_region.zw - inset);
    return texture(rock_texture, uv).rgb;
}
vec3 wrapped_rock(vec2 p) {
    vec2 q = fract(p) * 0.8 + 0.2;
    vec2 blend = smoothstep(vec2(0.8), vec2(1.0), q);
    return mix(mix(sample_rock(q), sample_rock(q - vec2(0.8, 0.0)), blend.x),
               mix(sample_rock(q - vec2(0.0, 0.8)), sample_rock(q - vec2(0.8)), blend.x), blend.y);
}
void fragment() {
    vec4 original_color = texture(TEXTURE, UV) * vertex_tint;
    float material_area = texture(rock_mask, UV).r * rock_strength;
    vec3 painted_stone = wrapped_rock(rock_world_uv);
    painted_stone *= 0.94 + 0.06 * sin(rock_world_uv.x * 1.7 + rock_world_uv.y * 0.8);
    COLOR = vec4(mix(original_color.rgb, painted_stone, material_area), original_color.a);
}
