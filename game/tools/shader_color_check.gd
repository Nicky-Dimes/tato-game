extends Node2D
## GPU regression: applying the silhouette shader must preserve original RGBA.
func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.size = Vector2(1280, 720)
	add_child(bg)
	var source := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	source.fill(Color(0.8, 0.6, 0.4, 0.75))
	var texture := ImageTexture.create_from_image(source)
	var mask := Image.create(8, 8, false, Image.FORMAT_L8)
	mask.fill(Color.WHITE)
	for i in 2:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.position = Vector2(100 + i * 250, 200)
		sprite.scale = Vector2.ONE * 15
		if i == 1:
			var material := ShaderMaterial.new()
			material.shader = load("res://assets/production/silhouette.gdshader")
			material.set_shader_parameter("silhouette_mask", ImageTexture.create_from_image(mask))
			sprite.material = material
		add_child(sprite)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var frame := get_viewport().get_texture().get_image()
	var original := frame.get_pixel(150, 250)
	var masked := frame.get_pixel(400, 250)
	var difference := absf(original.r - masked.r) + absf(original.g - masked.g) + absf(original.b - masked.b)
	print("SHADER COLOR: original=", original, " masked=", masked, " delta=", difference)
	get_tree().quit(0 if difference < 0.015 else 1)
