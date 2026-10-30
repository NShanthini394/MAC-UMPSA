shader_type canvas_item;
uniform float outline_width = 8.0;
varying vec4 item_tint;

void vertex() {
    item_tint = COLOR;
}

void fragment() {
    vec4 original = texture(TEXTURE, UV);
    vec2 step_uv = TEXTURE_PIXEL_SIZE * outline_width;
    float edge = 0.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 probe = UV + vec2(float(x), float(y)) * step_uv;
            if (all(greaterThanEqual(probe, vec2(0.0))) && all(lessThanEqual(probe, vec2(1.0)))) {
                edge = max(edge, texture(TEXTURE, probe).a);
            }
        }
    }
    float alpha = max(original.a, edge);
    COLOR = vec4(original.rgb * original.a / max(alpha, 0.001), alpha) * item_tint;
}
