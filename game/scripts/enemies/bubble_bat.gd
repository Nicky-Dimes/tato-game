extends Enemy
## Bubble Bat: drifts back and forth on the breeze inside its bubble.
## A honk shoves it away. Push it into brambles and its bubble pops; it
## floats off dizzy and comes back a little later.

var _base := Vector2.ZERO
var _phase := 0.0
var _range := 160.0
var _push := Vector2.ZERO
var _popped := 0.0


func _configure() -> void:
	position = LevelData.cell_center(cell)
	home = position
	_base = position
	_range = p_float("range", 3.0) * Layers.TILE * 0.5
	_phase = p_float("phase", 0.0)
	sprite = Art.centered("enemies/bubble_bat")
	add_child(sprite)
	collision_mask = 0
	add_touch(Vector2(48, 44), Vector2.ZERO)
	var sense := Area2D.new()
	sense.collision_layer = Layers.ENEMY
	sense.collision_mask = 0
	var sh := CircleShape2D.new()
	sh.radius = 28.0
	var cs := CollisionShape2D.new()
	cs.shape = sh
	sense.add_child(cs)
	add_child(sense)


func on_effect(tag: StringName, info: Dictionary) -> bool:
	if tag == &"honk" or tag == &"resonance":
		var from: Vector2 = info.get("position", global_position)
		_push = (global_position - from).normalized() * 420.0
		AudioService.play_varied("squeak", -8.0)
		return true
	if tag == &"cold":
		stun(3.0)
		return true
	return false


func _behave(delta: float) -> void:
	if _popped > 0.0:
		_popped -= delta
		if _popped <= 0.0:
			sprite.visible = true
			touch_hurts = true
			position = home
			_base = home
		return
	_phase += delta
	_push = _push.move_toward(Vector2.ZERO, 500.0 * delta)
	_base += _push * delta
	# drift home again after being shoved
	if _push.length() < 5.0:
		_base = _base.lerp(home, clampf(delta * 0.6, 0.0, 1.0))
	if not is_stunned():
		position = _base + Vector2(sin(_phase * 0.9) * _range, sin(_phase * 2.1) * 18.0)
		facing = signf(cos(_phase * 0.9))
	for hz in get_tree().get_nodes_in_group("hazard"):
		var n := hz as Node2D
		if n != null and n.global_position.distance_to(global_position) < 44.0:
			_pop()
			break


func _pop() -> void:
	_popped = 7.0 * Settings.timer_factor()
	sprite.visible = false
	touch_hurts = false
	AudioService.play_varied("pop")
	Fx.pop_ring(level, global_position, Color(0.7, 0.9, 1.0), 44.0)
	Captions.caption("Pop! The Bubble Bat drifts off")


func reset_puzzle() -> void:
	super.reset_puzzle()
	_base = home
	_push = Vector2.ZERO
	_popped = 0.0
	sprite.visible = true
	touch_hurts = true
