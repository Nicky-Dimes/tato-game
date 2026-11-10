extends Enemy
## Forkling: a bossy little fork on patrol. Quick, and it turns to charge
## when it sees Tato on its level. A flash of light dazzles it for a while;
## a honk makes it spin round and march the other way.

const WALK := 95.0
const CHARGE := 215.0
var _charge := 0.0


func _configure() -> void:
	add_art("enemies/forkling")
	add_body(15.0, 54.0)
	add_touch(Vector2(34, 50), Vector2(0, -27))
	facing = -1.0 if not p_flag("right") else 1.0


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"light":
		stun(4.5)
		AudioService.play_varied("squeak", -6.0)
		Captions.caption("The Forkling is dazzled")
		return true
	if tag == &"honk":
		facing = -facing
		_charge = 0.0
		return true
	if tag == &"cold":
		stun(3.0)
		return true
	return false


func _behave(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + 1500.0 * delta, 800.0)
	var speed := WALK
	if is_stunned():
		speed = 0.0
		_charge = 0.0
	else:
		var p := level.player
		if p != null and not p.is_stealthy():
			var d := p.global_position - global_position
			if absf(d.y) < 40.0 and absf(d.x) < 300.0 and signf(d.x) == facing:
				_charge = 0.6
		if _charge > 0.0:
			_charge -= delta
			speed = CHARGE
	if is_on_floor() and speed > 0.0 and (wall_ahead(facing) or not ground_ahead(facing)):
		facing = -facing
		_charge = 0.0
	velocity.x = facing * speed
	move_and_slide()
	if sprite and not Settings.flag("reduced_motion"):
		sprite.rotation = sin(Time.get_ticks_msec() * 0.018) * (0.1 if speed > 0.0 else 0.25)
