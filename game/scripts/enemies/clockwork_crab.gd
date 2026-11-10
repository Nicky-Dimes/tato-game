extends Enemy
## Clockwork Crab: a helpful (if single-minded) kitchen machine that carries
## a tray back and forth. Ride the tray! A honk makes it turn around, and a
## whiff of warm pepper makes it hurry. It never hurts anybody.

const WALK := 70.0
var _tray: AnimatableBody2D
var _hurry := 0.0
var _last := Vector2.ZERO


func _configure() -> void:
	add_art("enemies/clockwork_crab")
	add_body(22.0, 44.0)
	touch_hurts = false
	facing = 1.0 if not p_flag("left") else -1.0
	_tray = AnimatableBody2D.new()
	_tray.top_level = true
	_tray.collision_layer = Layers.ONEWAY
	_tray.collision_mask = 0
	_tray.sync_to_physics = false
	_tray.add_to_group("safe_ground_moving")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(96, 14)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.one_way_collision = true
	cs.one_way_collision_margin = 6.0
	_tray.add_child(cs)
	add_child(_tray)
	var sense := Area2D.new()
	sense.collision_layer = Layers.ENEMY
	sense.collision_mask = 0
	var sh := RectangleShape2D.new()
	sh.size = Vector2(80, 60)
	var scs := CollisionShape2D.new()
	scs.shape = sh
	scs.position = Vector2(0, -30)
	sense.add_child(scs)
	add_child(sense)


func _ready() -> void:
	_tray.global_position = global_position + Vector2(0, -62)


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"honk":
		facing = -facing
		AudioService.play("lever", -6.0)
		Captions.caption("The Clockwork Crab turns around")
		return true
	if tag == &"heat":
		_hurry = 4.0
		return true
	if tag == &"cold" or tag == &"resonance":
		stun(4.0)
		return true
	return false


func _behave(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + 1500.0 * delta, 800.0)
	var speed := WALK
	if _hurry > 0.0:
		_hurry -= delta
		speed = WALK * 2.2
	if is_stunned():
		speed = 0.0
	if is_on_floor() and speed > 0.0 and (wall_ahead(facing, 34.0) or not ground_ahead(facing, 30.0)):
		facing = -facing
	velocity.x = facing * speed
	move_and_slide()
	_tray.global_position = global_position + Vector2(0, -62)
	if sprite and speed > 0.0 and not Settings.flag("reduced_motion"):
		sprite.position.y = absf(sin(Time.get_ticks_msec() * 0.012)) * -3.0


func reset_puzzle() -> void:
	super.reset_puzzle()
	_hurry = 0.0
