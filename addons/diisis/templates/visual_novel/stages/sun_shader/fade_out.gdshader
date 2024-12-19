shader_type canvas_item;

// --- Uniforms --- //
uniform vec4 color: source_color;
uniform vec4 outer_color: source_color;
uniform float width: hint_range(0.0, 10.0, 0.1) = 0.5;
uniform vec2 origin_noise = vec2(0.385, 0.0);
uniform vec2 origin_mask = vec2(0., 0.);
uniform float wait_time: hint_range(0.0, 5.0, 0.1) = 2.5; //technically you dont need that
uniform float speed: hint_range(0.0, 20.2, 0.0001) = 0.1;
uniform float alpha_boost: hint_range(1.0, 5.0, 0.1) = 2.0;
uniform float seconds_per_frame: hint_range(0.0, 0.5, 0.0001) = 0.1;
uniform float steps: hint_range(0.0, 10.0, 0.1) = 4.8;
uniform float magic: hint_range(0.0, 5.0, 0.1);

uniform float debug:hint_range(0.0, 1.0, 0.1);
uniform float color_opacity:hint_range(0.0, 1.0, 0.01) = 1.0;

uniform sampler2D background;
uniform sampler2D noise;
uniform sampler2D mask;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

uniform float fill_amount: hint_range(-1.0, 10.0, 0.001) = -1.0;

uniform float epsilon = 1e-10;

vec3 RGB2HSV(vec3 c){
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 RGBtoHCV(vec3 RGB)
  {
    // Based on work by Sam Hocevar and Emil Persson
    vec4 P = (RGB.g < RGB.b) ? vec4(RGB.bg, -1.0, 2.0/3.0) : vec4(RGB.gb, 0.0, -1.0/3.0);
    vec4 Q = (RGB.r < P.x) ? vec4(P.xyw, RGB.r) : vec4(RGB.r, P.yzx);
    float C = Q.x - min(Q.w, Q.y);
    float H = abs((Q.w - Q.y) / (6. * C + epsilon) + Q.z);
    return vec3(H, C, Q.x);
  }
vec3 RGB2HSL(vec3 RGB){
    vec3 HCV = RGBtoHCV(RGB);
    float L = HCV.z - HCV.y * 0.5;
    float S = HCV.y / (1. - abs(L * 2. - 1.) + epsilon);
    return vec3(HCV.x, S, L);
 }

vec2 get_brightest_point(vec2 uv){
	vec4 bg = texture(background, uv);
	vec3 bg_hsl = RGB2HSL(bg.rgb);
	return vec2(bg_hsl.b);
	//return vec2(dot(bg_hsl.bg, bg_hsl.gg));
	//return vec2(mix(bg_hsv.b, bg_hsv.g, debug));
	//return vec2(bg_hsv.r);
}
vec2 get_darkest_point(vec2 uv){
	vec4 bg = texture(background, uv);
	vec3 bg_hsl = RGB2HSL(bg.rgb);
	return vec2(bg_hsl.b);
	//return vec2(dot(bg_hsl.bg, bg_hsl.gg));
	//return vec2(mix(bg_hsv.b, bg_hsv.g, debug));
	//return vec2(bg_hsv.r);
}

//this fades the image out and in with time.
//used this for testing purposes but maybe you find usage out of this? :3
float fade_with_time(vec2 uv){
	float dist = distance(uv, origin_noise)*texture(noise, uv).r * steps;
	return dist - mod(floor(fill_amount/seconds_per_frame) * speed, wait_time) * magic + 0.5;
}

	//dont let the name of "_width" deceive you.
	//it's more like a "this is how much you should skip from the outer rim until the color sets in"
vec4 outliner(vec2 uv1, vec2 uv2, float _noise, vec4 _color, float _width){
    vec4 color_band = _color;
    float color_dist = get_brightest_point(uv1).x*_noise*steps;
    float mod_color_dist = color_dist - fill_amount + _width;
    color_band.a *= 0.5 - step(0.5, mod_color_dist);
    color_band.a *= alpha_boost;
    return color_band;
}

void fragment() {
	vec2 uv_modded = vec2(SCREEN_UV.x + origin_noise.x, SCREEN_UV.y + origin_noise.y);
	vec2 uv_noise = vec2(UV.x + origin_noise.x, UV.y + origin_noise.y);
	vec4 nooiisee = texture(noise, uv_noise);
	nooiisee += texture(mask, vec2(UV.x + origin_mask.x, UV.y + origin_mask.y));

	vec4 color_band = color;
	vec4 outer_color_band = outer_color;
	vec4 white_body = vec4(1);
	vec4 final_color = vec4(0);

	//you could add as many colors as you'd like by following the pattern here
	//the smaller the last parameter ('width') the more on the outside the color will be
	//so the most important thing would be that
	final_color = outliner(SCREEN_UV, uv_modded, nooiisee.r, color, 0.3);
	vec4 out_color_space = outliner(SCREEN_UV, uv_modded, nooiisee.r, outer_color, 0.3 + width * .5);
	vec4 white_color_space = outliner(SCREEN_UV, uv_modded, nooiisee.r, outer_color, 0.3 + width);

	if(out_color_space.a >= final_color.a){
		final_color.rgb = outer_color.rgb;
	}
	if(final_color.a <= white_color_space.a){
		final_color.rgb = white_body.rgb;
	}

	if(final_color.r <= max(color.r, outer_color.r)){
		final_color.a = color_opacity;
	}

	COLOR = final_color;
	//prevents ugly early bleed through when the shader isn't even supposed to start yet
	//you could remove it if you'd like tho
	/*if(fill_amount <= 1.0){
		COLOR = texture(background, UV);
	}*/
}
