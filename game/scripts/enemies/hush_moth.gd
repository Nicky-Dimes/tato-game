extends Enemy
## Hush Moth: hovers and listens. Loud things (honks, running, heavy
## landings) make it swoop at Tato. Moonmint feet are silent to it, and a
## hush-honk lulls it to sleep. Quiet Ink hides Tato from it completely.

var _phase := 0.0
var _chase := 0.0
var _asleep := 0.0
var _hear := 300.0


func _configure() -> void:
	position = LevelData.cell_center(cell)
	home = position
	_hear = p_float("r", 4.5) * Layers.TILE
	sprite = Art.centered("enemies/hush_moth")
	add_child(sprite)
	collision_mask = 0
	add_touch(Vector2(44, 40), Vector2.ZERO)
	var sense := Area2D.new()
	sense.collision_layer = Layers.ENEMY
	sense.collision_mask = 0
	var sh := CircleShape2D.new()
	sh.radius = 26.0
	var cs := CollisionShape2D.new()
	cs.shape = sh
	sense.add_child(cs)
	add_child(sense)
	add_to_group("listener")


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"quiet":
		_asleep = 9.0 * Settings.timer_factor()
		_chase = 0.0
		touch_hurts = false
		sprite.modulate = Color(0.7, 0.75, 1.0)
		Captions.caption("The Hush Moth nods off")
		return true
	if tag == &"light":
		stun(3.0)
		return true
	return false


func _behave(delta: float) -> void:
	_phase += delta
	if _asleep > 0.0:
		_asleep -= delta
		position = position.lerp(home + Vector2(0, 14), clampf(delta * 2.0, 0.0, 1.0))
		if _asleep <= 0.0:
			touch_hurts = true
			sprite.modulate = Color.WHITE
		return
	var p := level.player
	if is_stunned() or p == null:
		return
	var d := p.global_position + Vector2(0, -30) - global_position
	if not p.is_quiet() and not p.is_stealthy() and p.noise > 0.42 and d.length() < _hear:
		if _chase <= 0.0:
			AudioService.play("alarm", -4.0)
			Captions.caption("! The Hush Moth heard that")
			Fx.float_text(level, global_position + Vector2(0, -50), "!", UITheme.RED)
		_chase = 2.4
	if _chase > 0.0:
		_chase -= delta
		position += d.normalized() * 190.0 * delta
		facing = signf(d.x)
	else:
		var rest := home + Vector2(sin(_phase * 0.8) * 46.0, sin(_phase * 1.7) * 14.0)
		position = position.lerp(rest, clampf(delta * 1.6, 0.0, 1.0))
	if not Settings.flag("reduced_motion"):
		sprite.scale = Vector2(0.5, 0.5 + sin(_phase * 16.0) * 0.04)


func _draw() -> void:
	if _asleep <= 0.0:
		draw_arc(Vector2.ZERO, _hear, 0.0, TAU, 48, Color(1, 1, 1, 0.1), 3.0, true)


func reset_puzzle() -> void:
	super.reset_puzzle()
	_chase = 0.0
	_asleep = 0.0
	touch_hurts = true
	sprite.modulate = Color.WHITE
