extends AbilityStrategy
## Pop Bounce: every landing pops Tato back into the air. Hold jump for a
## bigger bounce, hold down to stop bouncing. Landings pop sealed pods and
## fragile things underneath.

const BOUNCE := -770.0
const BIG_BOUNCE := -880.0

var cold := false


func kind() -> String:
	return KIND_TOGGLE


func start() -> void:
	player.bouncy = true
	player.landed.connect(_on_landed)
	player.visual.tint = Color(1.0, 0.98, 0.85)
	AudioService.voice("honk_pop")
	player.honk_pose(0.2)
	player.honked.emit(def.get("id"))
	if player.is_on_floor():
		_bounce(260.0)


func _on_landed(impact: float) -> void:
	_bounce(impact)


func _bounce(impact: float) -> void:
	var p := player
	var at := p.global_position
	pulse(at + Vector2(0, 6), PackedStringArray(["pop", "impact"]), 58.0, {"life": 0.12, "style": "none", "info": {"speed": impact, "from_above": true}})
	_landing_extra(at)
	if p.move_y > 0.5:
		p.visual.squash(Vector2(1.2, 0.8))
		return
	var held := Input.is_action_pressed("jump") or Input.is_action_pressed("flap")
	p.velocity.y = BIG_BOUNCE if held else BOUNCE
	p.flaps_left = Tato.MAX_FLAPS
	p.visual.squash(Vector2(0.76, 1.3))
	AudioService.play_varied("pop", -2.0, 0.12)
	Fx.burst(world(), at, "puff", Color(1.0, 0.97, 0.8, 0.9), 5, {"spread": 30.0, "life": 0.35, "size": 9.0})
	p.noise = maxf(p.noise, 0.7)


func _landing_extra(_at: Vector2) -> void:
	pass


func stop() -> void:
	player.bouncy = false
	if player.landed.is_connected(_on_landed):
		player.landed.disconnect(_on_landed)
	player.visual.tint = Color.WHITE


func anim() -> String:
	return "puffed" if not player.is_on_floor() else ""
