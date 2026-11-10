extends Prop
## A chime that rings when honked at. `opens=<id>` switches that link.
##   mode=once   (default) stays on forever
##   mode=toggle each honk flips it
##   mode=timed  stays on for t seconds (t=5), then needs another honk
## `tag=resonance` makes it a heavy bell that only a Drumbeat Honk can ring.

var on := false
var _timer := 0.0
var _sprite: Sprite2D
var _mode := "once"
var _tag := &"honk"
var _start_on := false


func _configure() -> void:
	_mode = p_str("mode", "once")
	_tag = StringName(p_str("tag", "honk"))
	var art := "props/bell" if _tag == &"resonance" else "props/chime"
	position = LevelData.cell_center(cell) + Vector2(0, -8)
	_sprite = Art.centered(art)
	add_child(_sprite)
	add_sense(Vector2(60, 70))
	add_to_group("resettable")
	_start_on = p_flag("on")
	if _start_on:
		_switch(true, false)


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag != _tag:
		if tag == &"honk" and _tag == &"resonance":
			_wobble(0.08)
			Captions.caption("The big bell barely hums. It needs a deeper sound.")
		return false
	match _mode:
		"toggle":
			_switch(not on)
		"timed":
			_timer = p_float("t", 5.0) * Settings.timer_factor()
			_switch(true)
		_:
			_switch(true)
	_wobble(0.4)
	AudioService.play("bell" if _tag == &"resonance" else "chime")
	Captions.caption("♪ The chime rings" if _tag != &"resonance" else "♪ BONG! The great bell rings")
	return true


func _physics_process(delta: float) -> void:
	if _mode == "timed" and on:
		_timer -= delta
		if _timer < 1.5:
			_sprite.modulate.a = 0.6 + 0.4 * absf(sin(_timer * 10.0))
		if _timer <= 0.0:
			_switch(false)
			Captions.caption("The chime falls quiet")


func _switch(value: bool, announce: bool = true) -> void:
	if on == value and announce:
		if value:
			Fx.pop_ring(level, global_position, Color(1, 0.9, 0.4), 50.0)
		return
	on = value
	_sprite.modulate = Color(1.0, 0.95, 0.55) if on else Color.WHITE
	_sprite.modulate.a = 1.0
	if announce:
		Fx.pop_ring(level, global_position, Color(1, 0.9, 0.4), 60.0)
	level.trigger(p_str("opens"), on, self)


func _wobble(amount: float) -> void:
	if Settings.flag("reduced_motion"):
		return
	var t := create_tween()
	t.tween_property(_sprite, "rotation", amount, 0.07)
	t.tween_property(_sprite, "rotation", -amount * 0.7, 0.12)
	t.tween_property(_sprite, "rotation", amount * 0.4, 0.12)
	t.tween_property(_sprite, "rotation", 0.0, 0.14)


func reset_puzzle() -> void:
	if _mode != "once":
		_switch(_start_on, false)
