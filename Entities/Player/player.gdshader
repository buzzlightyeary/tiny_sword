shader_type canvas_item;

// 窗户发光遮罩图：白色=发光，黑色=不发光
//uniform sampler2D emission_mask : hint_default_black;
//uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.4, 1.0);
//uniform float glow_intensity = 1.5;
//uniform float breath_speed = 2.0;

// 描边
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width = 1.0;
uniform bool enable_outline = false;

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    vec4 final_color = base_color;

    // ---------- 描边 ----------
    if (enable_outline && base_color.a <= 0.0) {
        vec2 size = TEXTURE_PIXEL_SIZE * outline_width;

        float a = 0.0;
        a += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
        a += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
        a += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
        a += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
        a += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
        a += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
        a += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
        a += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;

        if (a > 0.0) {
            final_color = outline_color;
        }
    }

    // ---------- 窗户呼吸发光 ----------
    // 只让原图不透明区域发光，避免透明描边区域也被 emission_mask 影响
    //if (base_color.a > 0.0) {
    //    vec4 mask_color = texture(emission_mask, UV);

    //    if (mask_color.r > 0.1) {
    //        float breath = (sin(TIME * breath_speed) + 1.0) * 0.15 + 0.7;
    //        final_color.rgb += glow_color.rgb * glow_intensity * breath;
    //        final_color.a = base_color.a;
    //    }
    //}

    COLOR = final_color;
}