extends Enemy
## Pudding Pod: a wobbly pudding that just sits there. Warm it and it
## swells into a big, bouncy platform for a while; chill it and it sets
## firm (a small solid step). Harmless.

var form := "soft"     # soft | puffed | firm
var _timer := 0.0
var _step: StaticBody2D
var _step_shape: RectangleShape2D
var _step_cs: CollisionShape2D
var _bounce: Area2D


func _configure() -> void:
	add_art("enemies/pudding_pod")
	touch_hurts = false
	collision_layer = Layers.ENEMY
	collision_mask = 0
	var sense := Area2D.new()
	sense.collision_layer = Layers.ENEMY
	sense.collision_mask = 0
	var sh := RectangleShape2D.new()
	sh.size = Vector2(64, 56)
	var scs := CollisionShape2D.new()
	scs.shape = sh
	scs.position = Vector2(0, -28)
	sense.add_child(scs)
	add_child(sense)
	_step = StaticBody2D.new()
	_step.collision_layer = 0
	_step.collision_mask = 0
	_step_shape = RectangleShape2D.new()
	_step_shape.size = Vector2(60, 44)
	_step_cs = CollisionShape2D.new()
	_step_cs.shape = _step_shape
	_step_cs.position = Vector2(0, -22)
	_step.add_child(_step_cs)
	add_child(_step)
	_bounce = Area2D.new()
	_bounce.collision_layer = 0
	_bounce.collision_mask = Layers.PLAYER
	var bs := RectangleShape2D.new()
	bs.size = Vector2(120, 22)
	var bcs := CollisionShape2D.new()
	bcs.shape = bs
	bcs.position = Vector2(0, -150)
	_bounce.add_child(bcs)
	_bounce.monitoring = false
	_bounce.body_entered.connect(_on_bounce)
	add_child(_bounce)


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"heat":
		_become("puffed", 8.0)
		return true
	if tag == &"cold":
		_become("firm", 10.0)
		return true
	if tag == &"honk":
		sprite.scale = Vector2(sprite.scale.x * 1.1, sprite.scale.y * 0.9)
		return true
	return false


func _become(new_form: String, seconds: float) -> void:
	form = new_form
	_timer = seconds * Settings.timer_factor()
	var t := create_tween()
	match form:
		"puffed":
			t.tween_property(sprite, "scale", Vector2(1.05, 1.25), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_step.collision_layer = Layers.WORLD
			_step_shape.size = Vector2(124, 136)
			_step_cs.position = Vector2(0, -68)
			_bounce.set_deferred("monitoring", true)
			sprite.modulate = Color(1.0, 0.95, 0.9)
			AudioService.play("puff")
			Captions.caption("The pudding swells up, big and bouncy")
		"firm":
			t.tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.15)
			_step.collision_layer = Layers.WORLD
			_step_shape.size = Vector2(60, 44)
			_step_cs.position = Vector2(0, -22)
			_bounce.set_deferred("monitoring", false)
			sprite.modulate = Color(0.8, 0.93, 1.0)
			AudioService.play("freeze", -5.0)
			Captions.caption("The pudding sets firm")
		_:
			t.tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.3)
			_step.collision_layer = 0
			_bounce.set_deferred("monitoring", false)
			sprite.modulate = Color.WHITE


func _on_bounce(body: Node) -> void:
	if body is Tato and form == "puffed" and (body as Tato).velocity.y >= -40.0:
		var p := body as Tato
		p.velocity.y = -900.0
		p.flaps_left = Tato.MAX_FLAPS
		p.visual.squash(Vector2(0.78, 1.28))
		AudioService.play_varied("boing")


func _behave(delta: float) -> void:
	if form != "soft":
		_timer -= delta
		if _timer < 1.4:
			sprite.modulate.a = 0.6 + 0.4 * absf(sin(_timer * 10.0))
		if _timer <= 0.0:
			var p := level.player
			var clear := p == null or absf(p.global_position.x - global_position.x) > 90.0 or p.global_position.y < global_position.y - 170.0
			if clear:
				_become("soft", 0.0)
				sprite.modulate.a = 1.0
	elif not Settings.flag("reduced_motion"):
		var wob := sin(Time.get_ticks_msec() * 0.005 + cell.x)
		sprite.scale = Vector2(0.5 + wob * 0.025, 0.5 - wob * 0.025)


func reset_puzzle() -> void:
	super.reset_puzzle()
	_become("soft", 0.0)
