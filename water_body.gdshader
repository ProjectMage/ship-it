shader_type canvas_item;

uniform vec4 tint: source_color = vec4(1.0);


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 color = texture(TEXTURE, SCREEN_UV);

	color = mix(color, tint, 0.3);
	color = mix(vec4(0.5), color, 1.4);

	COLOR = color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
