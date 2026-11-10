extends AbilityStrategy
## Steam Lift (Pepper + Bubbleberry): a hot bubble that shoots straight up,
## carrying Tato. Great for tall shafts. Also puffs warm steam around the
## launch spot (lights braziers, lifts light lids).

const RISE := -430.0
var _bubble: Sprite2D
var _puff_clock := 0.0


func kind() -> String:
	return KIND_TOGGLE


func start() -> void:
	_bubble = Art.centered("fx/bubble")
	_bubble.modulate = Color(1.0, 0.82, 0.7)
	_bubble.position = Vector2(0, -38)
	_bubble.scale = Vector2(0.56, 0.56)
	player.visual.front.add_child(_bubble)
	player.velocity.y = RISE * 0.6
	player.sliding = false
	AudioService.voice("honk_fire")
	AudioService.play("steam")
	pulse(player.global_position + Vector2(0, -30), PackedStringArray(["heat", "lift", "honk"]), 150.0, {
		"life": 0.3, "style": "ring", "color": Color(1.0, 0.7, 0.5, 0.9),
	})
	player.honked.emit(&"STEAM_LIFT")


func overrides_movement() -> bool:
	return true


func move(delta: float) -> void:
	var p := player
	if p.move_x != 0.0:
		p.facing = signf(p.move_x)
	p.velocity.x = move_toward(p.velocity.x, p.move_x * 120.0, 500.0 * delta)
	p.velocity.y = move_toward(p.velocity.y, RISE, 1500.0 * delta)
	p.move_and_slide()
	p.in_water = false
	_puff_clock -= delta
	if _puff_clock <= 0.0:
		_puff_clock = 0.09
		Fx.burst(world(), p.global_position + Vector2(randf_range(-14, 14), 4), "puff", Color(1, 1, 1, 0.7), 1, {"spread": 10.0, "life": 0.4, "size": 9.0, "rise": -30.0})
	if p.take_jump_press() or (p.is_on_ceiling() and elapsed > 0.25):
		finish()


func stop() -> void:
	if _bubble != null and is_instance_valid(_bubble):
		_bubble.queue_free()
	player.velocity.y = maxf(player.velocity.y, -260.0)
	Fx.pop_ring(world(), player.global_position + Vector2(0, -38), Color(1.0, 0.8, 0.6), 60.0)
	AudioService.play_varied("pop", -2.0)
	player.flaps_left = Tato.MAX_FLAPS


func anim() -> String:
	return "float"
