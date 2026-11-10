extends AbilityStrategy
## Dash Attack: a burst of speed straight ahead. Bowls through creatures and
## crates; nothing can hurt Tato while he is dashing.

const SPEED := 820.0
var _dir := 1.0
var _hit: Dictionary = {}
var _trail := 0.0


func kind() -> String:
	return KIND_TOGGLE


func blocks_hurt() -> bool:
	return true


func overrides_movement() -> bool:
	return true


func start() -> void:
	_dir = player.facing
	player.sliding = false
	AudioService.voice("honk_zing")
	AudioService.play_varied("dash", -3.0)
	player.honked.emit(&"GARLIC_DASH")
	player.visual.squash(Vector2(1.35, 0.72))


func move(delta: float) -> void:
	var p := player
	p.velocity = Vector2(_dir * SPEED, 0.0)
	p.move_and_slide()
	p.in_water = false
	Hit.burst(p.get_parent(), p.global_position + Vector2(_dir * 26.0, -32.0), 44.0, damage(), element(), p, {"silent": true, "knock": 420.0})
	_trail -= delta
	if _trail <= 0.0:
		_trail = 0.03
		Fx.burst(world(), p.global_position + Vector2(-_dir * 20.0, -30.0), "puff", Color(1, 1, 1, 0.6), 1, {"spread": 6.0, "life": 0.25, "size": 14.0})
	if p.is_on_wall():
		finish()


func stop() -> void:
	player.velocity.x = _dir * Tato.RUN_SPEED
	player.invuln = maxf(player.invuln, 0.25)


func anim() -> String:
	return "run"
