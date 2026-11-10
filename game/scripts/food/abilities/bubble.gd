extends AbilityStrategy
## Bubble Float: Tato drifts gently upward inside a bubble. Steer left and
## right, hold up to rise a little faster, down to sink. Warm rising air
## carries the bubble much higher. Brambles (or jumping) pop it.

const DRIFT := 175.0
var _bubble: Sprite2D


func kind() -> String:
	return KIND_TOGGLE


func start() -> void:
	_bubble = Art.centered("fx/bubble")
	_bubble.position = Vector2(0, -38)
	_bubble.scale = Vector2(0.1, 0.1)
	player.visual.front.add_child(_bubble)
	var t := _bubble.create_tween()
	t.tween_property(_bubble, "scale", Vector2(0.5, 0.5), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	player.velocity.y = minf(player.velocity.y, -90.0)
	player.sliding = false
	AudioService.voice("honk_bubble")
	AudioService.play("bubble_up")
	player.honked.emit(&"BUBBLE")


func overrides_movement() -> bool:
	return true


func move(delta: float) -> void:
	var p := player
	if p.move_x != 0.0:
		p.facing = signf(p.move_x)
	p.velocity.x = move_toward(p.velocity.x, p.move_x * DRIFT, 620.0 * delta)
	var rise := -72.0
	if p.move_y < -0.5:
		rise = -125.0
	elif p.move_y > 0.5:
		rise = 55.0
	p.velocity.y = move_toward(p.velocity.y, rise, 720.0 * delta)
	p.move_and_slide()
	p.in_water = false
	if p.take_jump_press():
		p.velocity.y = -300.0
		finish()
		return
	if _bubble != null and time_left < 1.2:
		# wobble as a warning before it pops by itself
		_bubble.modulate.a = 0.55 + 0.45 * absf(sin(time_left * 12.0))


func stop() -> void:
	if _bubble != null and is_instance_valid(_bubble):
		_bubble.queue_free()
	Fx.pop_ring(world(), player.global_position + Vector2(0, -38), Color(0.7, 0.9, 1.0), 54.0)
	AudioService.play_varied("pop", -2.0)
	player.flaps_left = Tato.MAX_FLAPS


func anim() -> String:
	return "float"
