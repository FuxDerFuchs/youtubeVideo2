shader_type spatial;

uniform sampler2D screen_texture : source_color, hint_screen_texture, filter_nearest;
uniform sampler2D normal_texture : source_color, hint_normal_roughness_texture, filter_nearest;
uniform sampler2D depth_texture : source_color, hint_depth_texture, filter_nearest;
render_mode unshaded; //so light doesn't affect the shader

uniform float depth_treshold = 0.05;

void vertex() {
	//attach mesh to camera / Position = location in camera coordinates, vertext = location in object coordinates
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float get_depth(vec2 screen_uv, mat4 inv_projection_matrix) {
	float depth = texture(depth_texture, screen_uv).x;
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, depth);
	vec4 view = inv_projection_matrix * vec4(ndc, 1.0);
	view.xyz /= -view.w;
	return view.z;
}

vec3 get_normal(vec2 screen_uv)
{
	return texture(normal_texture, screen_uv).rgb * 2.0 - 1.0;
}

void fragment() {
    vec3 original = texture(screen_texture, SCREEN_UV).rgb;
    vec3 normal = get_normal(SCREEN_UV);
    float depth = get_depth(SCREEN_UV, INV_PROJECTION_MATRIX);

    vec2 texel_size = 1.0 / VIEWPORT_SIZE.xy;
    vec2 uvs[8];
    uvs[0] = vec2(SCREEN_UV.x, SCREEN_UV.y + texel_size.y);
    uvs[1] = vec2(SCREEN_UV.x, SCREEN_UV.y - texel_size.y);
    uvs[2] = vec2(SCREEN_UV.x + texel_size.x, SCREEN_UV.y);
    uvs[3] = vec2(SCREEN_UV.x - texel_size.x, SCREEN_UV.y);
    uvs[4] = vec2(SCREEN_UV.x + texel_size.x * 2.0, SCREEN_UV.y);
    uvs[5] = vec2(SCREEN_UV.x - texel_size.x * 2.0, SCREEN_UV.y);
    uvs[6] = vec2(SCREEN_UV.x, SCREEN_UV.y + texel_size.y * 2.0);
    uvs[7] = vec2(SCREEN_UV.x, SCREEN_UV.y - texel_size.y * 2.0);

    float depth_diff = 0.0;
    float normal_sum = 0.0;
    for (int i = 0; i < 8; i++) {
        float d = get_depth(uvs[i], INV_PROJECTION_MATRIX);
        depth_diff += abs(depth - d);

        vec3 n = get_normal(uvs[i]);
        vec3 normal_diff = normal - n;
        normal_sum += dot(normal_diff, normal_diff);
    }

    depth_diff *= 0.125; // Durchschnitt über 8 Texel
    float depth_edge = smoothstep(depth_treshold * 0.5, depth_treshold * 1.5, depth_diff);

    float outline = depth_edge + normal_sum;
    outline = clamp(outline, 0.0, 1.0);

    ALBEDO =  mix(original, vec3(0.0), outline);
}