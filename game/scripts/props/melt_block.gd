extends Prop
## A block that warmth melts away: wax ("wax") or a chunk of ice ("iceblock").
## `regrow=<seconds>` makes it come back after a while.

var melted := false
var _body: StaticBody2D
var _sprite: Sprite2D
var _regrow := 0.0
var _timer := 0.0


func _configure() -> void:
	var is_ice := p_str("type") == "iceblock"
	_sprite = Art.standing("props/iceblock" if is_ice else "props/wax")
	add_child(_sprite)
	_body = add_solid(Vector2(64, 64), Vector2(0, -32), Layers.WORLD | Layers.INTERACT)
	if is_ice:
		_body.add_to_group("ice")
	_regrow = p_float("regrow", 0.0)
	add_to_group("resettable")


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"heat" and not melted:
		melt()
		return true
	if tag == &"cold" and melted and p_str("type") == "iceblock":
		_restore()
		return true
	return false


func melt() -> void:
	melted = true
	_timer = _regrow * Settings.timer_factor()
	_body.collision_layer = 0
	AudioService.play("melt")
	Captions.caption("It melts away")
	var t := create_tween()
	t.tween_property(_sprite, "scale", Vector2(0.56, 0.08), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.35)
	Fx.puff(level, global_position + Vector2(0, -30), Color(1, 1, 1, 0.7), 4)


func _physics_process(delta: float) -> void:
	if melted and _regrow > 0.0:
		_timer -= delta
		if _timer <= 0.0 and _clear_of_player():
			_restore()


func _clear_of_player() -> bool:
	if level == null or level.player == null:
		return true
	var d := level.player.global_position - global_position
	return absf(d.x) > 56.0 or d.y < -70.0 or d.y > 60.0


func _restore() -> void:
	melted = false
	_body.collision_layer = Layers.WORLD | Layers.INTERACT
	_sprite.scale = Vector2(0.5, 0.5)
	_sprite.modulate.a = 1.0


func reset_puzzle() -> void:
	if melted and _clear_of_player():
		_restore()
