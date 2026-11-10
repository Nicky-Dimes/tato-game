extends Prop
## A springy mushroom cap. Landing on it bounces Tato high.
## `power=1.3` scales the bounce.

var _sprite: Sprite2D


func _configure() -> void:
	_sprite = Art.standing("props/bounce")
	add_child(_sprite)
	var touch := add_touch(Vector2(54, 20), Vector2(0, -34))
	touch.body_entered.connect(_on_touch)


func _on_touch(body: Node) -> void:
	if not (body is Tato):
		return
	var player := body as Tato
	if player.velocity.y < -50.0:
		return
	player.velocity.y = -880.0 * p_float("power", 1.0)
	player.flaps_left = Tato.MAX_FLAPS
	player.visual.squash(Vector2(0.78, 1.28))
	AudioService.play_varied("boing")
	if not Settings.flag("reduced_motion"):
		var t := create_tween()
		t.tween_property(_sprite, "scale", Vector2(0.6, 0.34), 0.06)
		t.tween_property(_sprite, "scale", Vector2(0.5, 0.5), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
