class_name Projectile
extends Area2D
## One flying shot: Tato's (fireball, ice shard, bubble, honey, melon slice,
## kernel, tomato) or a creature's (seed, arrow, snowball, candy, spore ...).
## Drawn with a few shapes so hundreds of textures are not needed.

var velocity := Vector2.ZERO
var fall := 0.0             # downward pull (px/s^2)
var life := 1.2
var damage := 1
var element: StringName = &"plain"
var hostile := false            # true = a creature's shot (hurts Tato)
var pierce := 0                 # how many extra targets it passes through
var radius := 12.0
var look := "ball"              # fire | ice | bubble | honey | melon | kernel | tomato | seed | arrow | snow | candy | spore | rock | bolt | cannon | cake
var color := Color.WHITE
var splash := 0.0               # explode with this radius when it ends
var splash_damage := 0
var wobble := 0.0               # bubbles drift from side to side
var bounces := 0                # times it may bounce off the ground
var spin := 0.0
var source: Node = null
var knock := 180.0

var _age := 0.0
var _done := false
var _hit: Dictionary = {}


static func fire(parent: Node, at: Vector2, vel: Vector2, opts: Dictionary = {}) -> Projectile:
	var p := Projectile.new()
	p.velocity = vel
	for key: String in opts.keys():
		p.set(key, opts[key])
	parent.add_child(p)
	p.global_position = at
	return p


func _ready() -> void:
	collision_layer = Layers.EFFECT
	collision_mask = Layers.WORLD | (Layers.PLAYER if hostile else (Layers.ENEMY | Layers.INTERACT | Layers.PROP))
	monitoring = true
	# (must stay monitorable: with it off, this engine version stops the area
	# from noticing solid ground at all)
	monitorable = true
	z_index = 12
	if hostile:
		add_to_group("enemy_shot")
	var shape := CircleShape2D.new()
	shape.radius = radius
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_touch)
	area_entered.connect(_touch)


func _physics_process(delta: float) -> void:
	if _done:
		return
	_age += delta
	velocity.y += fall * delta
	var step := velocity * delta
	if wobble != 0.0:
		step.x += cos(_age * 6.0) * wobble * delta
	position += step
	if spin != 0.0:
		rotation += spin * delta
	elif look in ["arrow", "ice", "bolt", "fire"]:
		rotation = velocity.angle()
	if _age >= life:
		finish()
	queue_redraw()


func _touch(node: Node) -> void:
	if _done or node == source:
		return
	if hostile:
		if node is Tato:
			var player := node as Tato
			if player.is_shielded() and player.runner.current != null:
				reflect(player)
				return
			player.hurt(global_position - velocity.normalized() * 10.0)
			finish()
		elif node is PhysicsBody2D and ((node as PhysicsBody2D).collision_layer & Layers.WORLD) != 0:
			_hit_ground()
		return
	var target := Hit.find_target(node)
	if target != null:
		if _hit.has(target.get_instance_id()):
			return
		_hit[target.get_instance_id()] = true
		var landed: bool = target.call("take_hit", damage, {
			"element": element, "source": source, "position": global_position,
			"dir": velocity.normalized(), "knock": knock,
		})
		if landed:
			if pierce > 0:
				pierce -= 1
			else:
				finish()
		return
	if node is PhysicsBody2D and ((node as PhysicsBody2D).collision_layer & Layers.WORLD) != 0:
		_hit_ground()


func _hit_ground() -> void:
	if bounces > 0 and velocity.y > 0.0:
		bounces -= 1
		velocity.y = -absf(velocity.y) * 0.6
		position.y -= 4.0
		return
	finish()


## A Cocoa Shield turns a creature's shot around.
func reflect(by: Node) -> void:
	hostile = false
	source = by
	velocity = -velocity * 1.2
	_age = 0.0
	set_deferred("collision_mask", Layers.WORLD | Layers.ENEMY | Layers.INTERACT | Layers.PROP)
	remove_from_group("enemy_shot")
	AudioService.play_varied("clink", -4.0)


func finish() -> void:
	if _done:
		return
	_done = true
	var parent := get_parent()
	if splash > 0.0 and parent != null:
		if hostile:
			Fx.pop_ring(parent, global_position, color, splash)
			for p in get_tree().get_nodes_in_group("player"):
				if (p as Node2D).global_position.distance_to(global_position) < splash + 20.0:
					(p as Tato).hurt(global_position)
		else:
			Hit.burst(parent, global_position, splash, maxi(splash_damage, damage), element, source, {"color": color, "knock": 320.0})
		Fx.burst(parent, global_position, "puff", color, 6, {"spread": splash * 0.6, "life": 0.4, "size": 12.0})
		AudioService.play_varied("splat", -3.0)
	elif parent != null:
		Fx.burst(parent, global_position, "sparkle", color, 3, {"spread": 18.0, "life": 0.3, "size": 5.0})
	queue_free()


func _draw() -> void:
	var line := Color("3a1f4d")
	var r := radius
	match look:
		"fire":
			var wave := sin(_age * 22.0)
			for i in 3:
				var tail := r * (1.35 + i * 0.55)
				var height_factor := r * (0.8 - i * 0.17)
				draw_colored_polygon(PackedVector2Array([Vector2(-tail * 1.8, wave * (2.0 + i)), Vector2(-r * 0.24, -height_factor), Vector2(r * 0.55, 0), Vector2(-r * 0.24, height_factor)]), Color("f45135") if i == 0 else Color(1.0, 0.52 + i * 0.08, 0.14, 0.53))
			draw_circle(Vector2(-r * 0.17, 0), r * 1.22, Color(1.0, 0.24, 0.09, 0.2))
			draw_circle(Vector2.ZERO, r, Color("e8442f"))
			draw_circle(Vector2(r * 0.12, -r * 0.06), r * 0.73, Color("ffab2b"))
			draw_circle(Vector2(r * 0.25, -r * 0.14), r * 0.42, Color("fff0a5"))
			for j in 2:
				var fx := -r * (1.9 + j * 0.8) + sin(_age * 18.0 + j) * r * 0.2
				draw_circle(Vector2(fx, sin(_age * 14.0 + j * 3.0) * r * 0.55), r * (0.24 - j * 0.055), Color(1, 0.75, 0.18, 0.8))
		"ice":
			var pts := PackedVector2Array([Vector2(r * 1.5, 0), Vector2(0, -r * 0.7), Vector2(-r * 1.2, 0), Vector2(0, r * 0.7)])
			draw_colored_polygon(pts, Color("a9e9f8"))
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color("35507a"), 2.5, true)
			draw_line(Vector2(-r * 0.5, 0), Vector2(r * 0.8, 0), Color(1, 1, 1, 0.9), 2.0)
		"bubble":
			draw_circle(Vector2.ZERO, r, Color(0.75, 0.6, 1.0, 0.35))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 20, Color(0.9, 0.85, 1.0, 0.95), 2.5, true)
			draw_circle(Vector2(-r * 0.35, -r * 0.35), r * 0.22, Color(1, 1, 1, 0.9))
		"honey":
			draw_circle(Vector2.ZERO, r, line)
			draw_circle(Vector2.ZERO, r - 2.5, Color("f5a623"))
			draw_circle(Vector2(-r * 0.3, -r * 0.3), r * 0.3, Color("ffe08a"))
		"melon":
			var a := PackedVector2Array([Vector2(-r, -r * 0.4), Vector2(r, -r * 0.4), Vector2(0, r)])
			draw_colored_polygon(a, Color("3fae4a"))
			draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.72, -r * 0.4), Vector2(r * 0.72, -r * 0.4), Vector2(0, r * 0.7)]), Color("f25a6e"))
			draw_polyline(PackedVector2Array([a[0], a[1], a[2], a[0]]), line, 2.5, true)
		"kernel":
			for off: Vector2 in [Vector2(-r * 0.4, 0), Vector2(r * 0.4, -r * 0.1), Vector2(0, -r * 0.5), Vector2(0, r * 0.4)]:
				draw_circle(off, r * 0.62, line)
			for off2: Vector2 in [Vector2(-r * 0.4, 0), Vector2(r * 0.4, -r * 0.1), Vector2(0, -r * 0.5), Vector2(0, r * 0.4)]:
				draw_circle(off2, r * 0.48, Color("fff6d0"))
		"tomato":
			draw_circle(Vector2.ZERO, r, line)
			draw_circle(Vector2.ZERO, r - 2.5, Color("e0392e"))
			draw_circle(Vector2(-r * 0.3, -r * 0.3), r * 0.25, Color(1, 1, 1, 0.7))
			draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.5, -r * 0.8), Vector2(0, -r * 1.25), Vector2(r * 0.5, -r * 0.8), Vector2(0, -r * 0.6)]), Color("4fae4a"))
		"arrow":
			draw_line(Vector2(-r * 1.6, 0), Vector2(r, 0), Color("8a5a2a"), 4.0)
			draw_colored_polygon(PackedVector2Array([Vector2(r * 1.6, 0), Vector2(r * 0.6, -r * 0.6), Vector2(r * 0.6, r * 0.6)]), Color("d9dde8"))
		"bolt":
			draw_polyline(PackedVector2Array([Vector2(-r * 1.6, -r * 0.4), Vector2(-r * 0.4, r * 0.4), Vector2(r * 0.2, -r * 0.4), Vector2(r * 1.6, r * 0.3)]), Color("7a4fcf"), 8.0, true)
			draw_polyline(PackedVector2Array([Vector2(-r * 1.6, -r * 0.4), Vector2(-r * 0.4, r * 0.4), Vector2(r * 0.2, -r * 0.4), Vector2(r * 1.6, r * 0.3)]), Color("ffe34d"), 4.0, true)
		_:
			draw_circle(Vector2.ZERO, r, line)
			draw_circle(Vector2.ZERO, r - 2.5, color)
			draw_circle(Vector2(-r * 0.3, -r * 0.3), r * 0.25, Color(1, 1, 1, 0.6))
