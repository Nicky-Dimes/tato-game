extends AbilityStrategy
## Drumbeat Honk: Tato draws a deep breath (he slows right down while he
## does) and then lets out a BOOM that shakes heavy bells, resonance plates
## and big machines. The charge finishes by itself, so a tap is enough.

const CHARGE_TIME := 0.85
var _fired := false
var _glow := 0.0


func kind() -> String:
	return KIND_CHARGE


func start() -> void:
	player.speed_scale = 0.25
	AudioService.play("charge")
	Captions.caption("Tato takes a deeeep breath...")


func tick(delta: float) -> void:
	_glow -= delta
	if _glow <= 0.0:
		_glow = 0.14
		var t := clampf(elapsed / CHARGE_TIME, 0.0, 1.0)
		Fx.pop_ring(world(), player.global_position + Vector2(0, -36), Color(0.7, 0.5, 1.0, 0.5 + 0.4 * t), 30.0 + 40.0 * (1.0 - t))
	if elapsed >= CHARGE_TIME * (0.8 if Settings.flag("cozy_mode") else 1.0) and not _fired:
		_fire()


func _fire() -> void:
	_fired = true
	player.honk_pose(0.4)
	player.noise = 1.0
	AudioService.voice("honk_boom")
	AudioService.play("boom")
	var origin := player.global_position + Vector2(0, -36)
	pulse(origin, PackedStringArray(["resonance", "honk"]), 340.0, {
		"life": 0.5, "style": "ring", "color": Color(0.75, 0.55, 1.0, 0.95), "info": {"big": true},
	})
	Fx.pop_ring(world(), origin, Color(1.0, 0.9, 0.4), 120.0)
	if player.level != null:
		player.level.shake(9.0)
	player.honked.emit(&"TRUFFLE")
	finish()


func stop() -> void:
	player.speed_scale = 1.0


func anim() -> String:
	return "charge" if not _fired else "honk"
