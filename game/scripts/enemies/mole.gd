extends Enemy
## Mole Digger: hides under its mound until Tato comes near, pops up, lobs a
## clod of dirt, and ducks back down. It can only be bopped while it is up.

var _up := 0.0
var _down := 1.0


func _configure() -> void:
	armored = true
	touch_hurts = false
	sprite.scale = Vector2(_base_scale, _base_scale * 0.45)


func _behave(delta: float) -> void:
	_fall(delta)
	move_and_slide()
	var d := to_player()
	if _up > 0.0:
		_up -= delta
		facing = signf(d.x) if d.x != 0.0 else facing
		shoot_at_player(delta * 3.0)
		if _up <= 0.0:
			_set_up(false)
			_down = 1.4
	else:
		_down -= delta
		if _down <= 0.0 and d.length() < float(stat("range", 360.0)) and absf(d.y) < 200.0:
			_set_up(true)
			_up = 1.8
			shot_timer = 0.5


func _set_up(value: bool) -> void:
	armored = not value
	touch_hurts = value
	var target := Vector2(_base_scale, _base_scale * (1.0 if value else 0.45))
	create_tween().tween_property(sprite, "scale", target, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if value:
		AudioService.play_varied("dig", -6.0)
		Fx.puff(level, global_position, Color(0.75, 0.6, 0.45, 0.9), 4)
