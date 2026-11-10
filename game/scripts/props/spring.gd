extends Prop
## Spring Pad (and the Grassland's Bounce Mushroom: `shroom`). Landing on it
## sends Tato flying. `power=1.3` scales the bounce.

var _sprite: Sprite2D
var _base := Vector2.ONE


func _configure() -> void:
	if p_str("type") == "shroom":
		_sprite = Art.sized("world/grassland_prop5", 58.0)
	else:
		_sprite = Art.sized("items/spring_pad", 52.0)
	_base = _sprite.scale
	add_child(_sprite)
	var touch := add_touch(Vector2(50, 20), Vector2(0, -40))
	touch.body_entered.connect(_on_touch)


func _on_touch(body: Node) -> void:
	if not (body is Tato):
		return
	var player := body as Tato
	if player.velocity.y < -50.0:
		return
	player.bounce(-900.0 * p_float("power", 1.0) / 1.25 if Input.is_action_pressed("jump") else -900.0 * p_float("power", 1.0))
	AudioService.play_varied("boing")
	if not Settings.flag("reduced_motion"):
		var t := create_tween()
		t.tween_property(_sprite, "scale", _base * Vector2(1.2, 0.65), 0.06)
		t.tween_property(_sprite, "scale", _base, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
