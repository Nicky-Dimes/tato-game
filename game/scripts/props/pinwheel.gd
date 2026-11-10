extends Prop
## A pinwheel. A warm Fire Honk sets it spinning for a while, and while it
## spins its link is on. `t=6` seconds (default 6).

var spinning := false
var _timer := 0.0
var _wheel: Sprite2D
var _speed := 0.0


func _configure() -> void:
	add_child(Art.standing("props/pinwheel_post"))
	_wheel = Art.centered("props/pinwheel")
	_wheel.position = Vector2(0, -98)
	add_child(_wheel)
	add_sense(Vector2(80, 120), Vector2(0, -70))
	add_to_group("resettable")


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag != &"heat":
		if tag == &"honk":
			_speed = maxf(_speed, 3.0)
		return false
	_timer = p_float("t", 6.0) * Settings.timer_factor()
	if not spinning:
		spinning = true
		AudioService.play("whirl")
		Captions.caption("Warm air spins the pinwheel")
		level.trigger(p_str("opens"), true, self)
	return true


func _physics_process(delta: float) -> void:
	if spinning:
		_speed = move_toward(_speed, 14.0, delta * 30.0)
		_timer -= delta
		if _timer <= 0.0:
			spinning = false
			level.trigger(p_str("opens"), false, self)
			Captions.caption("The pinwheel slows down")
	else:
		_speed = move_toward(_speed, 0.0, delta * 5.0)
	if _speed > 0.01 and not Settings.flag("reduced_motion"):
		_wheel.rotation += _speed * delta


func reset_puzzle() -> void:
	if spinning:
		spinning = false
		_timer = 0.0
		level.trigger(p_str("opens"), false, self)
