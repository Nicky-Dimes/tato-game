extends Enemy
## Syrup Slime: a slow, sticky blob that oozes back and forth and blocks the
## way. Cold freezes it into a harmless block you can stand on; warmth melts
## it into a flat puddle you can walk across. It always reforms.

const SPEED := 34.0
var form := "blob"     # blob | ice | puddle
var _timer := 0.0
var _ice_body: StaticBody2D


func _configure() -> void:
	add_art("enemies/syrup_slime")
	add_body(24.0, 48.0)
	add_touch(Vector2(54, 44), Vector2(0, -24))
	_ice_body = StaticBody2D.new()
	_ice_body.collision_layer = 0
	_ice_body.collision_mask = 0
	_ice_body.add_to_group("ice")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(60, 52)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -26)
	_ice_body.add_child(cs)
	add_child(_ice_body)


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"cold":
		_become("ice", 8.0)
		return true
	if tag == &"heat":
		_become("puddle", 6.0)
		return true
	if tag == &"honk" and form == "blob":
		sprite.scale = Vector2(0.56, 0.44)
		create_tween().tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		return true
	return false


func _become(new_form: String, seconds: float) -> void:
	form = new_form
	_timer = seconds * Settings.timer_factor()
	touch_hurts = form == "blob"
	_ice_body.collision_layer = Layers.WORLD if form == "ice" else 0
	match form:
		"ice":
			sprite.modulate = Color(0.7, 0.92, 1.0)
			sprite.scale = Vector2(0.5, 0.5)
			AudioService.play("freeze", -4.0)
			Captions.caption("The slime freezes solid")
		"puddle":
			sprite.modulate = Color(1, 1, 1, 0.8)
			sprite.scale = Vector2(0.72, 0.14)
			AudioService.play("melt", -4.0)
			Captions.caption("The slime melts into a puddle")
		_:
			sprite.modulate = Color.WHITE
			sprite.scale = Vector2(0.5, 0.5)


func _behave(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + 1500.0 * delta, 800.0)
	if form != "blob":
		velocity.x = 0.0
		_timer -= delta
		if _timer < 1.2:
			sprite.modulate.a = 0.6 + 0.4 * absf(sin(_timer * 10.0))
		if _timer <= 0.0 and _clear_above():
			_become("blob", 0.0)
	else:
		if is_on_floor() and (wall_ahead(facing, 32.0) or not ground_ahead(facing, 30.0)):
			facing = -facing
		velocity.x = facing * SPEED
		if not Settings.flag("reduced_motion"):
			var wob := sin(Time.get_ticks_msec() * 0.006)
			sprite.scale = Vector2(0.5 + wob * 0.03, 0.5 - wob * 0.03)
	move_and_slide()


func _clear_above() -> bool:
	if level == null or level.player == null:
		return true
	var d := level.player.global_position - global_position
	return absf(d.x) > 64.0 or d.y > 20.0 or d.y < -90.0


func reset_puzzle() -> void:
	super.reset_puzzle()
	_become("blob", 0.0)
