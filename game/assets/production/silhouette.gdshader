shader_type canvas_item;
render_mode unshaded;
uniform sampler2D silhouette_mask : filter_nearest;
uniform vec4 atlas_region = vec4(0.0, 0.0, 1.0, 1.0);
void fragment() {
    vec4 source = texture(TEXTURE, UV) * COLOR;
    vec2 mask_uv = (UV - atlas_region.xy) / atlas_region.zw;
    source.a *= texture(silhouette_mask, clamp(mask_uv, vec2(0.0), vec2(1.0))).r;
    COLOR = source;
}
