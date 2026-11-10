extends "res://scripts/food/abilities/melon.gd"
## Sticky Bowling (Honeycomb + Watermelon): a sticky melon ball that rolls
## up walls, across ceilings and around corners, clinging to whatever
## surface it is on. Jump pops it off the surface.

const SPEED := 330.0

var normal := Vector2.UP      # which way is "up" for the ball right now
var _travel := 1.0            # +1 clockwise around surfaces (rightwards on a floor)
var _air := 0.0


func ring_art() -> String:
	return "fx/sticky_ring"


func _extra_start() -> void:
	normal = Vector2.UP
	_travel = player.facing


func move(delta: float) -> void:
	var p := player
	if p.move_x != 0.0:
		# left / right always mean "along the surface" relative to the screen
		# when on a floor; on walls and ceilings the ball keeps its heading
		if normal.y < -0.5:
			_travel = signf(p.move_x)
		elif normal.y > 0.5:
			_travel = -signf(p.move_x)
	if p.move_y != 0.0 and absf(normal.x) > 0.5:
		# on a wall: up / down steer
		_travel = signf(p.move_y) * signf(normal.x) * -1.0 if normal.x > 0.0 else signf(p.move_y) * 1.0
	var moving := p.move_x != 0.0 or p.move_y != 0.0 or _air > 0.0
	var tangent := Vector2(-normal.y, normal.x) * _travel
	var speed := SPEED if moving else 0.0
	if _air > 0.0:
		# popped off the surface: ordinary ball flight until something is hit
		_air -= delta
		p.velocity.y = minf(p.velocity.y + Tato.FALL_GRAVITY * delta, Tato.MAX_FALL)
		p.velocity.x = move_toward(p.velocity.x, p.move_x * SPEED, 500.0 * delta)
		p.up_direction = Vector2.UP
		p.move_and_slide()
		if p.get_slide_collision_count() > 0:
			normal = p.get_slide_collision(0).get_normal()
			_air = 0.0
		_finish_move(p)
		return
	p.up_direction = normal
	p.velocity = tangent * speed - normal * 220.0
	var before := p.velocity
	p.move_and_slide()
	if p.get_slide_collision_count() > 0:
		# concave corner or curved track: adopt the new surface
		var best := normal
		var best_dot := -2.0
		for i in p.get_slide_collision_count():
			var n := p.get_slide_collision(i).get_normal()
			var facing_travel := -n.dot(tangent)
			if facing_travel > best_dot:
				best_dot = facing_travel
				best = n
			var into := -before.dot(n)
			if into > 170.0:
				var target := EffectPulse.find_receiver(p.get_slide_collision(i).get_collider() as Node)
				if target != null:
					target.call("on_effect", &"impact", {"source": p, "position": p.get_slide_collision(i).get_position(), "speed": into, "big": false, "tags": tags()})
		normal = best
	elif moving:
		# ran out of surface (a convex corner): wrap around it
		normal = tangent
		p.global_position += -Vector2(-normal.y, normal.x) * _travel * 0.0
	if p.take_jump_press():
		p.velocity = normal * 420.0 + Vector2(0, -160.0)
		normal = Vector2.UP
		_air = 0.5
		AudioService.play_varied("jump", -5.0)
	_finish_move(p)


func _finish_move(p: Tato) -> void:
	p.in_water = false
	var tangent := Vector2(-normal.y, normal.x) * _travel
	p.visual.spin_speed = (p.velocity.dot(tangent) if _air <= 0.0 else p.velocity.x) / radius
	if _ring != null:
		_ring.rotation = p.visual.body.rotation
	_bowl(p, p.velocity)


func stop() -> void:
	player.up_direction = Vector2.UP
	super.stop()
