extends Enemy
## Crumb Mite: a walking crumb that follows a simple back-and-forth trail.
## A honk scatters it (it scurries away, dizzy, and is harmless for a bit).

const SPEED := 70.0
var _scatter := 0.0


func _configure() -> void:
	add_art("enemies/crumb_mite")
	add_body(16.0, 32.0)
	add_touch(Vector2(36, 30), Vector2(0, -16))
	facing = -1.0 if not p_flag("right") else 1.0


func on_effect(tag: StringName, info: Dictionary) -> bool:
	if tag == &"honk" or tag == &"resonance":
		var from: Vector2 = info.get("position", global_position)
		facing = signf(global_position.x - from.x)
		if facing == 0.0:
			facing = 1.0
		_scatter = 0.6
		velocity.y = -260.0
		stun(2.6)
		AudioService.play_varied("squeak", -6.0)
		return true
	if tag == &"cold":
		stun(4.0)
		return true
	return false


func _behave(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + 1500.0 * delta, 800.0)
	var speed := SPEED
	if _scatter > 0.0:
		_scatter -= delta
		speed = 230.0
	elif is_stunned():
		speed = 0.0
	if is_on_floor() and speed > 0.0 and (wall_ahead(facing) or not ground_ahead(facing)):
		facing = -facing
	velocity.x = facing * speed
	move_and_slide()
	if sprite and speed > 0.0 and not Settings.flag("reduced_motion"):
		sprite.rotation = sin(Time.get_ticks_msec() * 0.02) * 0.08
