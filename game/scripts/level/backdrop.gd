class_name Backdrop
extends Node2D
## Four independent depth planes: sky, clouds, distant scenery and low foliage.
## All scenery stays behind the world; no screen-space foreground hides hazards.
const SKIES := {
	"grassland": [Color("63bffc"), Color("dcf7e8")],
	"nest": [Color("8fd0f5"), Color("fff0d9")],
	"orchard": [Color("7cccf6"), Color("fff1c9")],
	"candy": [Color("b9a2f2"), Color("ffe1f0")],
	"icy": [Color("8fb9ee"), Color("e6f3ff")],
	"windy": [Color("68c6f4"), Color("e2f8df")],
	"castle": [Color("777ab9"), Color("ffd6c8")],
}
var theme := "grassland"
var _planes: Array[Sprite2D] = []

func setup(theme_name: String, _level_size: Vector2) -> void:
	theme = theme_name
	z_index = -50
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	add_child(sky_layer)
	var colors: Array = SKIES.get(theme, SKIES["grassland"])
	var grad := Gradient.new()
	grad.set_color(0, colors[0])
	grad.set_color(1, colors[1])
	var texture := GradientTexture2D.new()
	texture.gradient = grad
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2(0, 1)
	texture.width = 4
	texture.height = 128
	var sky := TextureRect.new()
	sky.texture = texture
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky_layer.add_child(sky)
	var clouds := Parallax2D.new()
	clouds.scroll_scale = Vector2(0.04, 0.0)
	clouds.repeat_size = Vector2(1800, 0)
	clouds.repeat_times = 3
	if not Settings.flag("reduced_motion"):
		clouds.autoscroll = Vector2(-5, 0)
	clouds.add_child(CloudBand.new())
	add_child(clouds)
	_add_plane("far", 0.12, 1.0)
	_add_plane("mid", 0.32, 1.20)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _add_plane(plane: String, scroll: float, art_scale: float) -> void:
	var texture := ProductionArt.landscape(theme, plane)
	var parallax := Parallax2D.new()
	parallax.scroll_scale = Vector2(scroll, 0)
	parallax.repeat_size = Vector2(texture.get_width() * art_scale, 0)
	parallax.repeat_times = 4
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.scale = Vector2.ONE * art_scale
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/production/parallax.gdshader")
	material.set_shader_parameter("region", ProductionArt.region_for(theme) if texture is AtlasTexture else Vector4(0, 0, 1, 1))
	sprite.material = material
	parallax.add_child(sprite)
	add_child(parallax)
	_planes.append(sprite)

func _layout() -> void:
	var height := get_viewport().get_visible_rect().size.y
	for i in _planes.size():
		var sprite := _planes[i]
		sprite.position.y = height - sprite.texture.get_height() * sprite.scale.y + (-140 if i == 0 else -80)

class CloudBand:
	extends Node2D
	func _draw() -> void:
		for i in 7:
			var origin := Vector2(i * 270 + 40, 130 + (i % 3) * 42)
			var color := Color(1.0, 0.99, 0.98, 1.0)
			for j in 4:
				draw_circle(origin + Vector2(j * 20, -sin(j * 1.0) * 15), 24 + (j % 2) * 10, color)
