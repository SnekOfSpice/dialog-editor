shader_type canvas_item;

uniform vec3 outline_c: source_color;
uniform float progress: hint_range(0.0, 1.0);

void fragment() {
  COLOR = mix(COLOR, vec4(outline_c,  COLOR.a), (progress - COLOR.a) * progress * UV.y);
}