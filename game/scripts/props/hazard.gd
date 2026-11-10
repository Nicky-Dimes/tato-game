extends Prop
## The "ouch" things from the world kits. One script, picked by type:
##   spikes [flip]     a row of spikes (each world has its own drawing)
##   spiky             a prickly thing to walk around (spiky bush, thorn apple, ice star)
##   torch             castle torch: a flame that flares on a rhythm
##   saw  dx= dy= t=   a peppermint that glides along a path, spinning
##   roller dx= t=     a log that rolls back and forth
##   mace r=2          a spiked ball swinging round its chain
##   drip every=2      pink goo dripping from the ceiling
##   icicle            hangs still until Tato walks under it, then drops
##   faller every=3    Orchard gimmick: an apple that keeps falling from the tree
##   hive              a beehive: bees come out while Tato is near (two at most)
## All of them cost one heart at most, with a knock-back.

var _kind := "spikes"
var _sprite: Sprite2D
var _area: Area2D
var _clock := 0.0
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _period := 3.0
var _active := true
var _fall_vel := 0.0
var _state := 0
var _bees: Array = []
var _radius := 128.0


func _configure() -> void:
	_kind = p_str("type", "spikes")
	add_to_group("hazard")
	_clock = p_float("phase", 0.0)
	_from = position
	match _kind:
		"spikes":
			_sprite = Art.sized(WorldKit.art(level.theme, "spikes"), 34.0)
			if _sprite.texture != null:
				_sprite.scale.x = 62.0 / _sprite.texture.get_width()
			add_child(_sprite)
			var off := Vector2(0, -12)
			if p_flag("flip"):
				position = Vector2((cell.x + 0.5) * Layers.TILE, cell.y * Layers.TILE)
				_sprite.flip_v = true
				_sprite.offset.y = 0.0
				off = Vector2(0, 12)
			_area = add_touch(Vector2(50, 20), off)
		"spiky":
			_sprite = Art.sized(WorldKit.art(level.theme, "spiky"), 54.0)
			add_child(_sprite)
			_area = add_touch(Vector2(46, 40), Vector2(0, -22))
		"torch":
			_sprite = Art.sized(WorldKit.art("castle", "torch"), 60.0)
			add_child(_sprite)
			_area = add_touch(Vector2(40, 70), Vector2(0, -92))
			_period = p_float("every", 2.4)
		"saw":
			position = LevelData.cell_center(cell)
			_from = position
			_to = _from + Vector2(p_float("dx", 3.0), p_float("dy", 0.0)) * Layers.TILE
			_period = maxf(p_float("t", 2.5), 0.5)
			_sprite = Art.icon(WorldKit.art("candy", "saw"), 60.0)
			add_child(_sprite)
			_area = add_touch(Vector2(44, 44))
		"roller":
			_to = _from + Vector2(p_float("dx", 4.0), 0.0) * Layers.TILE
			_period = maxf(p_float("t", 3.0), 0.5)
			_sprite = Art.icon(WorldKit.art("grassland", "roller"), 56.0)
			_sprite.position = Vector2(0, -28)
			add_child(_sprite)
			_area = add_touch(Vector2(46, 46), Vector2(0, -26))
		"mace":
			position = LevelData.cell_center(cell)
			_radius = p_float("r", 2.0) * Layers.TILE
			_period = maxf(p_float("t", 3.2), 0.8)
			_sprite = Art.icon(WorldKit.art("castle", "mace"), 58.0)
			add_child(_sprite)
			_area = add_touch(Vector2(44, 44))
		"drip":
			position = Vector2((cell.x + 0.5) * Layers.TILE, cell.y * Layers.TILE)
			_sprite = Art.sized(WorldKit.art("candy", "drip"), 44.0)
			_sprite.offset.y = 0.0
			add_child(_sprite)
			_period = p_float("every", 2.2)
		"icicle":
			position = Vector2((cell.x + 0.5) * Layers.TILE, cell.y * Layers.TILE)
			_from = position
			_sprite = Art.sized(WorldKit.art("icy", "icicle"), 50.0)
			_sprite.offset.y = 0.0
			add_child(_sprite)
			_area = add_touch(Vector2(40, 44), Vector2(0, 24))
		"faller":
			position = LevelData.cell_center(cell)
			_from = position
			_sprite = Art.icon(WorldKit.art("orchard", "faller"), 50.0)
			add_child(_sprite)
			_area = add_touch(Vector2(40, 40))
			_period = p_float("every", 3.0)
		"hive":
			position = LevelData.cell_center(cell)
			_sprite = Art.icon(WorldKit.art("orchard", "hive"), 58.0)
			add_child(_sprite)
			_period = p_float("every", 5.0)
			_clock = _period - 1.5
	z_index = 1


func _physics_process(delta: float) -> void:
	var d := delta * (level.enemy_time if level != null else 1.0)
	_clock += d
	match _kind:
		"torch":
			var phase := fmod(_clock, _period)
			_active = phase < _period * 0.55
			queue_redraw()
		"saw", "roller":
			var k := 1.0 - absf(fmod(_clock / _period, 2.0) - 1.0)
			k = k * k * (3.0 - 2.0 * k)
			position = _from.lerp(_to, k)
			if not Settings.flag("reduced_motion"):
				_sprite.rotation += (9.0 if _kind == "saw" else 5.0) * d * (1.0 if fmod(_clock / _period, 2.0) < 1.0 else -1.0)
		"mace":
			var ang := sin(_clock * TAU / _period) * 1.25
			_sprite.position = Vector2(sin(ang), cos(ang)) * _radius
			(_area.get_child(0) as CollisionShape2D).position = _sprite.position
			queue_redraw()
		"drip":
			if _clock >= _period:
				_clock = 0.0
				if _near(900.0):
					Projectile.fire(level, global_position + Vector2(0, 40), Vector2(0, 60), {
						"hostile": true, "look": "ball", "color": Color("ff8ac4"), "radius": 10.0, "fall": 900.0, "life": 3.0, "source": self})
		"icicle":
			_icicle(d)
		"faller":
			_faller(d)
		"hive":
			_hive()
	if _area != null and _active and _state != 2:
		for body in _area.get_overlapping_bodies():
			if body is Tato:
				(body as Tato).hurt(_area.global_position + (_area.get_child(0) as CollisionShape2D).position)


func _near(dist: float) -> bool:
	return level != null and level.player != null and level.player.global_position.distance_to(global_position) < dist


func _icicle(d: float) -> void:
	var p := level.player
	if _state == 0:
		if p != null and absf(p.global_position.x - global_position.x) < 40.0 and p.global_position.y > global_position.y and p.global_position.y - global_position.y < 420.0:
			_state = 1
			_clock = 0.0
			AudioService.play_varied("clink", -8.0)
	elif _state == 1:
		# a little wobble as a warning, then it drops
		_sprite.rotation = sin(_clock * 40.0) * 0.08
		if _clock > 0.35:
			_state = 3
			_fall_vel = 0.0
			_sprite.rotation = 0.0
	elif _state == 3:
		_fall_vel = minf(_fall_vel + 1600.0 * d, 900.0)
		position.y += _fall_vel * d
		if level.is_solid_at(global_position + Vector2(0, 44)) or position.y > level.kill_plane_y():
			Fx.burst(level, global_position + Vector2(0, 40), "crumbs", Color(0.8, 0.95, 1.0), 6, {"spread": 40.0, "life": 0.4, "size": 8.0})
			AudioService.play_varied("crate_break", -8.0)
			_state = 2
			visible = false
			_clock = 0.0
	elif _state == 2 and _clock > 3.5:
		position = _from
		visible = true
		_state = 0


func _faller(d: float) -> void:
	if _state == 0:
		# hanging in the tree, wobbling before it lets go
		if _clock > _period - 0.5:
			_sprite.rotation = sin(_clock * 40.0) * 0.12
		if _clock >= _period and _near(1000.0):
			_state = 3
			_fall_vel = 0.0
			_sprite.rotation = 0.0
	elif _state == 3:
		_fall_vel = minf(_fall_vel + 1300.0 * d, 760.0)
		position.y += _fall_vel * d
		if level.is_solid_at(global_position + Vector2(0, 22)) or position.y > level.kill_plane_y():
			Fx.puff(level, global_position, Color(1, 0.8, 0.8, 0.9), 4)
			AudioService.play_varied("thud", -8.0)
			position = _from
			_state = 0
			_clock = 0.0


func _hive() -> void:
	_bees = _bees.filter(func(b: Variant) -> bool: return is_instance_valid(b) and not (b as Enemy).dead)
	if _clock < _period or _bees.size() >= 2 or not _near(520.0):
		return
	_clock = 0.0
	var bee := EntityFactory.create(level, {"type": "bee_buzzer", "cell": cell, "args": [], "params": {"up": 0.0, "range": 4.0}})
	if bee != null:
		level.entities.add_child(bee)
		_bees.append(bee)
		AudioService.play_varied("buzz", -8.0)
		Fx.puff(level, global_position, Color(1, 0.9, 0.4, 0.8), 3)


func _draw() -> void:
	if _kind == "torch" and _active:
		var flick := 1.0 + sin(_clock * 30.0) * 0.08
		draw_colored_polygon(PackedVector2Array([Vector2(-16, -62), Vector2(0, -62 - 66 * flick), Vector2(16, -62)]), Color(1.0, 0.45, 0.1, 0.9))
		draw_colored_polygon(PackedVector2Array([Vector2(-9, -62), Vector2(0, -62 - 40 * flick), Vector2(9, -62)]), Color(1.0, 0.85, 0.3, 0.95))
	elif _kind == "mace":
		draw_line(Vector2.ZERO, _sprite.position, Color("5a5f78"), 5.0)
		draw_circle(Vector2.ZERO, 7.0, Color("3a1f4d"))
