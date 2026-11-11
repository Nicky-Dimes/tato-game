extends Enemy
## Ground creatures. The stats switch on their tricks:
## hop (Mushroom Hopper, Candy Imp), lunge (Apple Chomper), roll (Hedgehog),
## shell (Turtle Tank), scuttle (Crab), guard (Onion Knight), pound (Rock
## Golem), zap (Shock Slime), shot (archers, goblins, puffins, imps).

var _hop_timer := 0.0
var _burst := 0.0          # lunge / roll / scuttle time left
var _rest := 0.0
var _shell := 0.0
var _special := 2.0
var _warn := 0.0
var _rush_warning := 0.0


func _configure() -> void:
	_hop_timer = randf_range(0.3, 1.1)
	_special = float(stat("pound", stat("zap", 2.5)))
	if bool(stat("hot", false)):
		touch_hurts = true


func _blocks(info: Dictionary) -> bool:
	if _shell > 0.0:
		return true
	if bool(stat("guard", false)):
		var element: StringName = info.get("element", &"plain")
		if element in [&"blast", &"stomp", &"shock", &"burst", &"dash", &"star"]:
			return false
		var dir: Vector2 = info.get("dir", Vector2.ZERO)
		# a shot flying against the way the knight faces hits the shield
		return dir.x != 0.0 and signf(dir.x) == -facing
	return false


func _on_hit(_info: Dictionary) -> void:
	if bool(stat("shell", false)) and hp > 0:
		_shell = 1.3
		armored = false


func _behave(delta: float) -> void:
	_fall(delta)
	var on_floor := is_on_floor()
	var speed := float(stat("speed", 50.0))
	var d := to_player()
	var sees := absf(d.y) < 70.0 and absf(d.x) < 330.0

	if _shell > 0.0:
		_shell -= delta
		speed = 0.0
		sprite.scale = Vector2(_base_scale * 1.1, _base_scale * 0.7)
		if _shell <= 0.0:
			sprite.scale = Vector2(_base_scale, _base_scale)
	elif stat("shot") != null and speed <= 0.0:
		# stands its ground and shoots
		if absf(d.x) < float(stat("range", 400.0)):
			facing = signf(d.x) if d.x != 0.0 else facing
	else:
		# tricks that add a burst of speed
		if _rest > 0.0:
			_rest -= delta
			speed = 0.0 if bool(stat("scuttle", false)) else speed
		elif _burst > 0.0:
			_burst -= delta
			speed = float(stat("lunge", stat("roll", speed * 2.4)))
			if _burst <= 0.0:
				_rest = 0.7
				sprite.rotation = 0.0
			elif stat("roll") != null and not Settings.flag("reduced_motion"):
				sprite.rotation += facing * 14.0 * delta
		elif _rush_warning > 0.0:
			_rush_warning = maxf(0.0, _rush_warning - delta)
			speed = 0.0
			if _rush_warning <= 0.0:
				_burst = 0.75
		elif sees and (stat("lunge") != null or stat("roll") != null) and on_floor:
			facing = signf(d.x) if d.x != 0.0 else facing
			_rush_warning = 0.28
			AudioService.play_varied("enemy_rush", -8.0)
		elif bool(stat("scuttle", false)) and on_floor:
			_burst = 0.5
	if on_floor and speed > 0.0 and (wall_ahead(facing) or not ground_ahead(facing)):
		facing = -facing
		_burst = 0.0
	if stat("hop") != null and on_floor:
		_hop_timer -= delta
		if _hop_timer <= 0.0:
			_hop_timer = 1.15
			velocity.y = -float(stat("hop", 400.0))
			AudioService.play_varied("boing", -12.0)
	if on_floor or stat("hop") != null:
		velocity.x = move_toward(velocity.x, facing * speed, 900.0 * delta)
	move_and_slide()
	shoot_at_player(delta)
	_specials(delta, d)
	if speed > 0.0 and on_floor and stat("roll") == null and not Settings.flag("reduced_motion") and _shell <= 0.0:
		var wob := sin(Time.get_ticks_msec() * 0.012 + home.x)
		sprite.scale = Vector2(_base_scale * (1.0 + wob * 0.05), _base_scale * (1.0 - wob * 0.05))


func _specials(delta: float, d: Vector2) -> void:
	if stat("pound") == null and stat("zap") == null:
		return
	if _warn > 0.0:
		_warn -= delta
		sprite.modulate = Color(1.3, 1.3, 0.7)
		if _warn <= 0.0:
			var at := global_position + Vector2(0, -height * 0.4)
			var radius := 120.0 if stat("pound") != null else 90.0
			Fx.pop_ring(level, at, Color(1.0, 0.9, 0.3) if stat("zap") != null else Color(0.8, 0.75, 0.7), radius)
			AudioService.play_varied("zap" if stat("zap") != null else "thud", -4.0)
			level.shake(4.0 if stat("pound") != null else 1.0)
			var p := player()
			if p != null and (p.global_position + Vector2(0, -30)).distance_to(at) < radius and (stat("zap") != null or p.is_on_floor()):
				p.hurt(global_position)
		return
	_special -= delta
	if _special <= 0.0 and d.length() < 260.0:
		_special = float(stat("pound", stat("zap", 2.5)))
		_warn = 0.55


func anticipating() -> bool:
	return _warn > 0.0 or _rush_warning > 0.0 or _burst > 0.0 or super.anticipating()


func attacking() -> bool:
	return _burst > 0.0 or super.attacking()
