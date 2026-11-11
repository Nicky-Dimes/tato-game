class_name PlayArt
extends RefCounted
## v0.4 gameplay props and animated attacks, separate from the character atlases.
static var _props: Dictionary = {}
static var _fx: Dictionary = {}
static var _layout: Dictionary = {}

static func prop(name: String) -> Texture2D:
	if _props.has(name):
		return _props[name]
	if _layout.is_empty():
		_layout = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/playful_layout.json"))
	if not _layout.has(name):
		return null
	var region: Array = _layout[name]
	var texture := AtlasTexture.new()
	texture.atlas = load("res://assets/production/" + (str(region[4]) if region.size() > 4 else "play_props.png"))
	texture.region = Rect2(region[0], region[1], region[2], region[3])
	texture.filter_clip = true
	_props[name] = texture
	return texture

static func standing(name: String, width: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = prop(name)
	sprite.centered = false
	sprite.offset = Vector2(-sprite.texture.get_width() * 0.5, -sprite.texture.get_height())
	sprite.scale = Vector2.ONE * width / sprite.texture.get_width()
	return sprite

static func platform(parent: Node, width: float, position: Vector2, style: String = "island") -> NinePatchRect:
	var panel := NinePatchRect.new()
	panel.texture = prop(style)
	panel.position = position
	panel.size = Vector2(width, 60)
	panel.patch_margin_left = 28
	panel.patch_margin_right = 28
	panel.patch_margin_top = 14
	panel.patch_margin_bottom = 18
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

static func frame(kind: String, frame_index: int) -> Texture2D:
	var row := ["fire", "bubble", "ice", "impact"].find(kind)
	if row < 0:
		return null
	var key := kind + str(frame_index % 4)
	if _fx.has(key):
		return _fx[key]
	var atlas := load("res://assets/production/combat_fx.png") as Texture2D
	var size := Vector2(atlas.get_width() / 4.0, atlas.get_height() / 4.0)
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(Vector2(frame_index % 4, row) * size, size)
	texture.filter_clip = true
	_fx[key] = texture
	return texture

static func impact(parent: Node, at: Vector2) -> void:
	if Game.headless_test or parent == null:
		return
	var burst := Impact.new()
	parent.add_child(burst)
	burst.global_position = at

class Impact:
	extends Node2D
	var age := 0.0
	func _ready() -> void:
		z_index = 14
	func _process(delta: float) -> void:
		age += delta
		if age > 0.30:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var texture := PlayArt.frame("impact", mini(int(age * 14), 3))
		draw_texture_rect(texture, Rect2(-56, -56, 112, 112), false)
