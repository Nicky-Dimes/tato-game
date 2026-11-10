extends Enemy
## Flying creatures. `pattern` in the stats picks how they move:
##   patrol  back and forth, dipping toward Tato            (Bee Buzzer)
##   swoop   hovers, then dives in an arc                    (Crow Swooper)
##   shy     creeps closer only while Tato looks away        (Ghost Poof)
##   wave    big lazy waves                                  (Pie Bat)
##   bob     hangs from balloons; popped, it walks instead   (Balloon Jelly)

var _phase := 0.0
var _anchor := Vector2.ZERO
var _swoop := 0.0
var _swoop_from := Vector2.ZERO
var _swoop_to := Vector2.ZERO
var _cool := 1.0
var _grounded := false
var _range := 150.0


func _configure() -> void:
	collision_mask = 0
	position += Vector2(0, -float(params.get("up", 1.5)) * Layers.TILE)
	home = position
	_anchor = position
	_phase = randf_range(0.0, TAU)
	_range = float(params.get("range", 3.0)) * Layers.TILE * 0.5


func _on_hit(_info: Dictionary) -> void:
	if str(stat("pattern")) == "bob" and not _grounded and hp > 0:
		# balloons popped: down it comes, and now it is a walker
		_grounded = true
		collision_mask = Layers.WORLD | Layers.ONEWAY
		AudioService.play_varied("pop", -3.0)
		Fx.pop_ring(level, global_position + Vector2(0, -height), Color(1.0, 0.7, 0.8), 40.0)


func _behave(delta: float) -> void:
	_phase += delta
	var speed := float(stat("speed", 90.0))
	var d := to_player() + Vector2(0, -30)
	match str(stat("pattern", "patrol")):
		"patrol":
			var target := _anchor + Vector2(sin(_phase * 0.9) * _range, sin(_phase * 2.3) * 16.0)
			if absf(d.x) < 150.0 and d.y > 0.0 and d.y < 220.0:
				target.y += minf(d.y, 120.0)
			position = position.lerp(target, clampf(delta * 3.0, 0.0, 1.0))
			facing = signf(cos(_phase * 0.9))
		"wave":
			position = _anchor + Vector2(sin(_phase * 0.7) * _range * 1.4, sin(_phase * 1.9) * 70.0)
			facing = signf(cos(_phase * 0.7))
		"swoop":
			if _swoop > 0.0:
				_swoop -= delta / 1.3
				var t := 1.0 - _swoop
				# a U-shaped dive: down to Tato's height and back up
				var mid := (_swoop_from + _swoop_to) * 0.5
				mid.y = _swoop_to.y
				var a := _swoop_from.lerp(mid, t)
				var b := mid.lerp(Vector2(_swoop_to.x, _swoop_from.y), t)
				position = a.lerp(b, t)
				if _swoop <= 0.0:
					_anchor = position
					_cool = 1.6
			else:
				position = _anchor + Vector2(sin(_phase * 1.2) * 30.0, sin(_phase * 2.6) * 10.0)
				facing = signf(d.x) if d.x != 0.0 else facing
				_cool -= delta
				if _cool <= 0.0 and absf(d.x) < 380.0 and d.y > 40.0 and d.y < 420.0:
					_swoop = 1.0
					_swoop_from = position
					_swoop_to = position + Vector2(d.x * 2.0, d.y)
					AudioService.play_varied("swoop", -6.0)
		"shy":
			var p := player()
			var looking := p != null and signf(global_position.x - p.global_position.x) == p.facing
			if looking:
				sprite.modulate.a = 0.45
				touch_hurts = false
			else:
				touch_hurts = true
				if d.length() < 520.0:
					position += d.normalized() * speed * delta
			position.y += sin(_phase * 3.0) * 0.4
			facing = signf(d.x) if d.x != 0.0 else facing
		"bob":
			if _grounded:
				_fall(delta)
				if is_on_floor() and (wall_ahead(facing) or not ground_ahead(facing)):
					facing = -facing
				velocity.x = facing * speed
				move_and_slide()
			else:
				position = _anchor + Vector2(sin(_phase * 0.6) * 40.0, sin(_phase * 1.1) * 90.0)
	if not Settings.flag("reduced_motion") and not _grounded:
		sprite.scale = Vector2(_base_scale, _base_scale * (1.0 + sin(_phase * 12.0) * 0.04))


func reset_puzzle() -> void:
	super.reset_puzzle()
	if not dead:
		_anchor = home
		_swoop = 0.0
