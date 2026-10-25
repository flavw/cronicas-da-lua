shader_type canvas_item;

uniform float view_aspect = 0.746835;
uniform float source_aspect = 0.75;
uniform float artwork_zoom = 1.0;
uniform vec2 artwork_focus = vec2(0.5, 0.5);
varying vec4 tint;

void vertex() {
 tint = COLOR;
}

void fragment() {
 vec2 visible = vec2(min(1.0, view_aspect / source_aspect), min(1.0, source_aspect / view_aspect)) / artwork_zoom;
 vec2 center = clamp(artwork_focus, visible * 0.5, vec2(1.0) - visible * 0.5);
 vec2 art_uv = center + (UV - vec2(0.5)) * visible;
 COLOR = texture(TEXTURE, art_uv) * tint;
}
