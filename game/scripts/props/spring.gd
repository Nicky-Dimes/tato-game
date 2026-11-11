extends Prop
## Broad 144px landing target, with a reliable, stronger held-jump bounce.
var _sprite: Sprite2D
var _base := Vector2.ONE
var _mushroom := false
var _cooldown := 0.0

func _configure() -> void:
	_mushroom = p_str("type") == "shroom"
	_sprite = PlayArt.standing("mushroom" if _mushroom else "spring", 144)
	_base = _sprite.scale
	add_child(_sprite)
	var touch := add_touch(Vector2(152, 74), Vector2(0, -38))
	touch.body_entered.connect(_on_touch)

func _physics_process(delta: float) -> void:
	_cooldown = maxf(0, _cooldown - delta)

func _on_touch(body: Node) -> void:
	if not (body is Tato) or _cooldown > 0:
		return
	var player := body as Tato
	if player.velocity.y < -50:
		return
	_cooldown = 0.18
	player.bounce((-1280.0 if Input.is_action_pressed("jump") else -1120.0) * p_float("power", 1.0))
	AudioService.play_varied("boing")
	PlayArt.impact(level, global_position + Vector2(0, -35))
	Fx.puff(level, global_position + Vector2(0, -24), Color(1, 1, 1, 0.7), 5)
	if not Settings.flag("reduced_motion"):
		var tween := create_tween()
		tween.tween_property(_sprite, "scale", _base * Vector2(1.12, 0.76), 0.06)
		tween.tween_property(_sprite, "scale", _base, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
