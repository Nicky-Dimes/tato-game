extends Enemy
## Whistle Weed: a plant that takes a breath and then whistles out a gust on
## a steady rhythm. `dir=up` (default), `left` or `right`; `h=5` cells long.
## The gust lifts a bubble or a gliding goose, and shoves a walking one.
## It is not harmful: use the gust, or wait between gusts.

var _clock := 0.0
var _area: Area2D
var _dir := Vector2.UP
var _len := 5
var blowing := false
var _on := 1.6
var _off := 2.0


func _configure() -> void:
	add_art("enemies/whistle_weed")
	touch_hurts = false
	collision_layer = 0
	collision_mask = 0
	match p_str("dir", "up"):
		"left":
			_dir = Vector2.LEFT
		"right":
			_dir = Vector2.RIGHT
		_:
			_dir = Vector2.UP
	_len = maxi(int(p_float("h", 5.0)), 1)
	_on = p_float("on", 1.6)
	_off = p_float("off", 2.0) * Settings.timer_factor()
	_clock = p_float("phase", 0.0)
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = Layers.PLAYER
	var shape := RectangleShape2D.new()
	var length := _len * float(Layers.TILE)
	shape.size = Vector2(56, length) if _dir == Vector2.UP else Vector2(length, 70)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -50) + _dir * length * 0.5
	_area.add_child(cs)
	add_child(_area)
	add_to_group("wind")
	z_index = 3


func contains(point: Vector2) -> bool:
	if not blowing:
		return false
	var length := _len * float(Layers.TILE)
	var centre := global_position + Vector2(0, -50) + _dir * length * 0.5
	var half := Vector2(28, length * 0.5) if _dir == Vector2.UP else Vector2(length * 0.5, 35)
	return absf(point.x - centre.x) < half.x and absf(point.y - centre.y) < half.y


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"honk" and not blowing:
		_clock = 0.0     # startled into whistling right away
		return true
	if tag == &"cold":
		stun(4.0)
		return true
	return false


func _behave(delta: float) -> void:
	if is_stunned():
		blowing = false
		queue_redraw()
		return
	_clock = fmod(_clock + delta, _on + _off)
	var now := _clock < _on
	if now != blowing:
		blowing = now
		if blowing and level.player != null and level.player.global_position.distance_to(global_position) < 760.0:
			AudioService.play("whistle", -6.0)
			Captions.caption("♪ The Whistle Weed blows")
	if sprite != null:
		var inhale := _clock > _on + _off - 0.5
		sprite.scale = Vector2(0.5, 0.56) if inhale else (Vector2(0.54, 0.46) if blowing else Vector2(0.5, 0.5))
	if blowing:
		for body in _area.get_overlapping_bodies():
			if body is Tato:
				_blow(body as Tato, delta)
	if not Settings.flag("reduced_motion"):
		queue_redraw()


func _blow(p: Tato, delta: float) -> void:
	var def: Resource = p.runner.active_def()
	var floaty := def != null and (def.get("tags") as PackedStringArray).has("bubble")
	if _dir == Vector2.UP:
		if floaty:
			p.velocity.y = move_toward(p.velocity.y, -360.0, 1700.0 * delta)
		elif not p.is_on_floor():
			p.velocity.y = move_toward(p.velocity.y, -250.0, 2600.0 * delta)
		else:
			p.velocity.y = -330.0
	else:
		var airborne := floaty or not p.is_on_floor()
		p.velocity.x += _dir.x * (900.0 if airborne else 420.0) * delta


func _draw() -> void:
	if not blowing:
		return
	var length := _len * float(Layers.TILE)
	var col := Color(1, 1, 1, 0.3)
	for i in 4:
		var t := fmod(_clock * 1.6 + i * 0.25, 1.0)
		var along := _dir * length * t
		var side := _dir.orthogonal() * ((i % 2) * 2.0 - 1.0) * 14.0
		var p0 := Vector2(0, -50) + along + side
		draw_line(p0, p0 + _dir * 34.0, col, 5.0, true)
