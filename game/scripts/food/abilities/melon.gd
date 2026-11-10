extends AbilityStrategy
## Melon Roll: Tato curls into a heavy melon ball. Rolls fast, speeds up
## downhill, smashes fragile crates, presses big buttons, shrugs off
## brambles and bowls creatures over. Too round for one-tile gaps.

var radius := 33.0
var top_speed := 440.0
var big := false
var _ring: Sprite2D
var _was_floor := false


func kind() -> String:
	return KIND_TOGGLE


func can_start() -> bool:
	if not player.ball_fits(radius):
		Fx.float_text(player.get_parent(), player.global_position + Vector2(0, -90), "Not enough room!", UITheme.CREAM)
		return false
	return true


func ring_art() -> String:
	return "fx/melon_ring"


func start() -> void:
	player.set_ball_shape(radius)
	player.sliding = false
	player.crouching = false
	_ring = Art.centered(ring_art())
	_ring.position = Vector2(0, -radius)
	_ring.scale = Vector2.ONE * (radius / 66.0)
	player.visual.front.add_child(_ring)
	player.visual.pivot_height = radius
	player.visual.body_scale = radius / 46.0
	AudioService.voice("honk_melon")
	AudioService.play("roll_start")
	player.honked.emit(def.get("id"))
	_extra_start()


func _extra_start() -> void:
	pass


func overrides_movement() -> bool:
	return true


func blocks_hurt() -> bool:
	return true


func move(delta: float) -> void:
	var p := player
	var on_floor := p.is_on_floor()
	if p.move_x != 0.0:
		p.facing = signf(p.move_x)
	var accel := 950.0 if on_floor else 520.0
	if p.move_x != 0.0:
		p.velocity.x = move_toward(p.velocity.x, p.move_x * top_speed, accel * delta)
	else:
		p.velocity.x = move_toward(p.velocity.x, 0.0, (240.0 if on_floor else 60.0) * delta)
	if on_floor:
		var n := p.get_floor_normal()
		p.velocity.x += n.x * Tato.GRAVITY * 0.9 * delta
		p.flaps_left = 0
		if p.take_jump_press():
			p.velocity.y = Tato.JUMP_VELOCITY * 0.84
			AudioService.play_varied("jump", -5.0, 0.05)
	else:
		p.velocity.y = minf(p.velocity.y + Tato.FALL_GRAVITY * delta, Tato.MAX_FALL)
		p.take_jump_press()
	p.velocity.x = clampf(p.velocity.x, -top_speed * 1.25, top_speed * 1.25)
	var before := p.velocity
	p.move_and_slide()
	p.in_water = false
	# things we rolled into feel the bump
	for i in p.get_slide_collision_count():
		var col := p.get_slide_collision(i)
		var n2 := col.get_normal()
		var into := -before.dot(n2)
		if into > 170.0:
			var target := EffectPulse.find_receiver(col.get_collider() as Node)
			if target != null:
				target.call("on_effect", &"impact", {"source": p, "position": col.get_position(), "speed": into, "big": big, "tags": tags()})
			if absf(n2.x) > 0.7 and into > 260.0:
				p.velocity.x = n2.x * 120.0
				p.level.shake(3.0) if p.level != null else null
				AudioService.play_varied("thud", -5.0)
	if p.is_on_floor() and not _was_floor and before.y > 320.0:
		AudioService.play_varied("thud", -6.0)
		Fx.puff(world(), p.global_position, Color(1, 1, 1, 0.7), 4)
		if p.level != null:
			p.level.shake(2.5)
	_was_floor = p.is_on_floor()
	p.visual.spin_speed = p.velocity.x / radius
	if _ring != null:
		_ring.rotation = p.visual.body.rotation
	_bowl(p, before)
	_extra_move(delta)


func _extra_move(_delta: float) -> void:
	pass


## Creatures in the way get bowled over (stunned), never hurt.
func _bowl(p: Tato, vel: Vector2) -> void:
	if vel.length() < 140.0:
		return
	for e in p.get_tree().get_nodes_in_group("enemy"):
		var en := e as Node2D
		if en != null and en.global_position.distance_to(p.global_position + Vector2(0, -radius)) < radius + 34.0 and en.has_method("stun"):
			if not en.call("is_stunned"):
				en.call("stun", 3.0)
				AudioService.play_varied("bonk", -6.0)


func stop() -> void:
	if _ring != null and is_instance_valid(_ring):
		_ring.queue_free()
	player.visual.reset_powers()
	player.set_ball_shape(0.0)
	player.flaps_left = Tato.MAX_FLAPS
	Fx.puff(world(), player.global_position + Vector2(0, -20), Color(1, 1, 1, 0.8), 5)
	AudioService.play_varied("pop", -5.0)


func anim() -> String:
	return "roll"
