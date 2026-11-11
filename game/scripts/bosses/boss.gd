class_name Boss
extends CharacterBody2D
## The six world bosses from the Enemy & Boss Concept Bible. One script; the
## table below gives each boss its drawing, health and its three attacks.
## Every attack is announced first (the boss flashes and a caption names the
## attack), then there is a pause where the boss is easy to hit. Running out
## of hearts just restarts Tato at the arena's checkpoint; the boss keeps
## the damage already done, so nobody gets stuck.
##
## Level letter:  boss mega_mushroot

const DATA := {
	"mega_mushroot": {"name": "Mega Mushroot", "hp": 14, "h": 190.0, "faces": 1, "attacks": ["stomp", "spores", "hop_slam"],
		"labels": {"stomp": "Stomp", "spores": "Spore Burst", "hop_slam": "Hop Slam"}},
	"gigantapple": {"name": "Gigantapple", "hp": 16, "h": 200.0, "faces": 1, "attacks": ["rush", "seeds", "roll"],
		"labels": {"rush": "Bite Rush", "seeds": "Seed Shot", "roll": "Rolling Bite"}},
	"candy_king": {"name": "Candy King", "hp": 18, "h": 190.0, "faces": 1, "attacks": ["rain", "wave", "bounce"],
		"labels": {"rain": "Candy Rain", "wave": "Sugar Wave", "bounce": "Bounce Core"}},
	"frost_puffin_lord": {"name": "Frost Puffin Lord", "hp": 20, "h": 180.0, "faces": -1, "attacks": ["beam", "spikes", "blizzard"],
		"labels": {"beam": "Ice Beam", "spikes": "Ice Spike", "blizzard": "Blizzard Spin"}},
	"sky_airship_turtle": {"name": "Sky Airship Turtle", "hp": 22, "h": 170.0, "faces": -1, "flies": true, "attacks": ["gust", "cannons", "dash"],
		"labels": {"gust": "Propeller Gust", "cannons": "Cannon Volley", "dash": "Wind Dash"}},
	"chef_castle_golem": {"name": "Chef Castle Golem", "hp": 26, "h": 215.0, "faces": 1, "attacks": ["bombs", "wave", "slam"],
		"labels": {"bombs": "Food Bomb", "wave": "Cake Wave", "slam": "Feast Slam"}, "helpers": "onion_knight"},
}

enum Mode { INTRO, IDLE, WARN, ATTACK, REST, DEFEATED }

var level: Level
var params: Dictionary = {}
var boss_id := "mega_mushroot"
var info: Dictionary = {}
var hp := 10
var max_hp := 10
var mode: int = Mode.INTRO
var facing := -1.0
var sprite: Sprite2D
var height := 190.0
var home := Vector2.ZERO
var arena_left := 0.0
var arena_right := 0.0

var _timer := 1.6
var _attack := ""
var _attack_index := 0
var _step := 0
var _flash := 0.0
var _base_scale := 1.0
var _touch: Area2D
var _gust := 0.0
var _gust_dir := 0.0
var _helpers_sent := false
var _clock := 0.0
var _hover_y := 0.0


func setup(lv: Level, e: Dictionary) -> void:
	level = lv
	params = e.get("params", {})
	var a: Array = e.get("args", [])
	boss_id = str(a[0]) if a.size() > 0 else "mega_mushroot"
	info = DATA.get(boss_id, DATA["mega_mushroot"])
	max_hp = int(info["hp"])
	if Settings.flag("cozy_mode"):
		max_hp = int(max_hp * 0.7)
	hp = max_hp
	height = float(info["h"])
	position = LevelData.cell_floor(e.get("cell", Vector2i.ZERO))
	home = position
	arena_left = 2.5 * Layers.TILE
	arena_right = lv.data.pixel_size().x - 2.5 * Layers.TILE
	collision_layer = Layers.ENEMY
	collision_mask = Layers.WORLD
	add_to_group("hittable")
	add_to_group("boss")
	z_index = 1
	sprite = Art.sized("bosses/" + boss_id, height)
	_base_scale = height / float(sprite.texture.get_meta("body_height"))
	sprite.scale = Vector2.ONE * _base_scale
	sprite.offset = -Vector2(sprite.texture.get_meta("anchor"))
	add_child(sprite)
	var w := height * 0.62
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, height * 0.78)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -height * 0.42)
	add_child(cs)
	_touch = Area2D.new()
	_touch.collision_layer = 0
	_touch.collision_mask = Layers.PLAYER
	var tshape := RectangleShape2D.new()
	tshape.size = Vector2(w * 0.86, height * 0.68)
	var tcs := CollisionShape2D.new()
	tcs.shape = tshape
	tcs.position = Vector2(0, -height * 0.42)
	_touch.add_child(tcs)
	add_child(_touch)
	if bool(info.get("flies", false)):
		collision_mask = 0
		position.y -= 170.0
		home = position
	_hover_y = position.y
	lv.boss = self


func _ready() -> void:
	# the stage builds its HUD after its creatures: say hello a moment later
	_announce.call_deferred()


func _announce() -> void:
	if level != null and level.hud != null:
		level.hud.show_boss(str(info["name"]))
	Captions.caption("%s appears!" % str(info["name"]))
	AudioService.music("boss")


func on_player_respawn() -> void:
	# give Tato a breather after a respawn
	if mode != Mode.DEFEATED:
		mode = Mode.REST
		_timer = 1.8
		_gust = 0.0
		velocity = Vector2.ZERO


# -------------------------------------------------------------------- hits --

func take_hit(damage: int, hit: Dictionary) -> bool:
	if mode == Mode.DEFEATED or mode == Mode.INTRO:
		return false
	var element: StringName = hit.get("element", &"plain")
	# a honk or a stomp only counts while the boss is resting
	var dmg := mini(damage, 3)
	if element == &"honk" and mode != Mode.REST:
		dmg = 0
	hp -= dmg
	_flash = 0.14
	if dmg > 0:
		AudioService.play_varied("enemy_hit", -3.0)
		if level.hud != null:
			level.hud.set_boss_health(float(hp) / float(max_hp))
		level.shake(3.0)
		level.hit_pause(0.045)
		Fx.burst(level, global_position + Vector2(0, -height * 0.5), "sparkle", Color(1, 1, 0.6), 4, {"spread": 50.0, "life": 0.3, "size": 7.0})
	else:
		AudioService.play_varied("clink", -6.0)
	if hp <= 0:
		_defeat()
	elif not _helpers_sent and info.has("helpers") and hp <= max_hp / 2:
		_helpers_sent = true
		_summon(str(info["helpers"]), 2)
	return true


func _defeat() -> void:
	mode = Mode.DEFEATED
	velocity = Vector2.ZERO
	_gust = 0.0
	remove_from_group("hittable")
	collision_layer = 0
	_touch.set_deferred("monitoring", false)
	level.hud.hide_boss()
	AudioService.music("")
	AudioService.play("boss_down")
	Captions.caption("%s is beaten!" % str(info["name"]))
	level.shake(10.0)
	for shot in get_tree().get_nodes_in_group("enemy_shot"):
		shot.queue_free()
	for e in get_tree().get_nodes_in_group("enemy"):
		if e is Enemy:
			(e as Enemy).defeat()
	var t := create_tween()
	for i in 6:
		t.tween_callback(func() -> void:
			Fx.puff(level, global_position + Vector2(randf_range(-70, 70), -randf_range(20, height)), Color(1, 1, 1, 0.9), 5)
			Fx.sparkle(level, global_position + Vector2(randf_range(-70, 70), -randf_range(20, height)), Color(1, 0.9, 0.4), 6))
		t.tween_interval(0.16)
	t.tween_property(sprite, "scale", Vector2(_base_scale * 1.2, 0.02), 0.25)
	t.parallel().tween_property(sprite, "modulate:a", 0.0, 0.25)
	t.tween_callback(func() -> void:
		level.drop_coins(global_position + Vector2(0, -60), 20)
		level.trigger("boss", true, self)
		visible = false)


# ------------------------------------------------------------------- frame --

func _physics_process(delta: float) -> void:
	_clock += delta
	_flash = maxf(_flash - delta, 0.0)
	if mode == Mode.DEFEATED:
		return
	var d := delta * Settings.enemy_speed() * level.enemy_time
	var p := level.player
	var to := p.global_position - global_position
	match mode:
		Mode.INTRO:
			_timer -= delta
			if _timer <= 0.0:
				_idle(0.8)
		Mode.IDLE:
			facing = signf(to.x) if absf(to.x) > 10.0 else facing
			_timer -= d
			if _timer <= 0.0:
				_attack = (info["attacks"] as Array)[_attack_index % 3]
				_attack_index += 1
				mode = Mode.WARN
				_timer = 0.7
				_step = 0
				Captions.caption("%s: %s!" % [str(info["name"]), str((info["labels"] as Dictionary).get(_attack, _attack))])
				AudioService.play("boss_warn", -3.0)
		Mode.WARN:
			_timer -= d
			if _timer <= 0.0:
				mode = Mode.ATTACK
				_timer = 0.0
		Mode.ATTACK:
			_run_attack(d, to)
		Mode.REST:
			_timer -= d
			if _timer <= 0.0:
				_idle(0.5)
	_move(d)
	_wind(delta)
	if mode != Mode.DEFEATED:
		for body in _touch.get_overlapping_bodies():
			if body is Tato:
				(body as Tato).hurt(global_position)
	_look()


func _idle(seconds: float) -> void:
	mode = Mode.IDLE
	# quicker as its health drops
	var pace := lerpf(0.6, 1.0, float(hp) / float(max_hp))
	_timer = seconds * pace + 0.4


func _rest(seconds: float) -> void:
	mode = Mode.REST
	_timer = seconds
	velocity.x = 0.0


func _move(d: float) -> void:
	if bool(info.get("flies", false)):
		position += velocity * d
		if mode != Mode.ATTACK:
			position.y = lerpf(position.y, _hover_y + sin(_clock * 2.0) * 14.0, clampf(d * 3.0, 0.0, 1.0))
		position.x = clampf(position.x, arena_left, arena_right)
		return
	if not is_on_floor():
		velocity.y = minf(velocity.y + 1700.0 * d, 1000.0)
	var was_air := not is_on_floor()
	var fall := velocity.y
	move_and_slide()
	position.x = clampf(position.x, arena_left, arena_right)
	if was_air and is_on_floor() and fall > 300.0:
		_landed()


func _landed() -> void:
	level.shake(7.0)
	AudioService.play_varied("thud", -2.0)
	Fx.puff(level, global_position, Color(1, 1, 1, 0.8), 6)
	if mode == Mode.ATTACK and _attack in ["stomp", "hop_slam", "bounce", "slam", "roll"]:
		_shockwaves(300.0 if _attack != "hop_slam" else 220.0)


func _wind(delta: float) -> void:
	if _gust <= 0.0:
		return
	_gust -= delta
	var p := level.player
	p.velocity.x += _gust_dir * (620.0 if not p.is_on_floor() else 330.0) * delta
	if int(_clock * 10.0) % 2 == 0:
		Fx.burst(level, p.global_position + Vector2(-_gust_dir * 80.0, -randf_range(10, 90)), "puff", Color(1, 1, 1, 0.4), 1, {"spread": 6.0, "life": 0.3, "size": 8.0})


func _look() -> void:
	sprite.flip_h = facing < 0.0
	var second := int(_clock * 7.0) % 2 == 1
	var frame_id := 4 if second and not Settings.flag("reduced_motion") else 0
	match mode:
		Mode.WARN: frame_id = 5 if second else 1
		Mode.ATTACK: frame_id = 6 if second else 2
		Mode.REST: frame_id = 7 if second else 3
	var animation_tex := ProductionArt.boss_frame(boss_id, frame_id)
	if animation_tex != null:
		sprite.texture = animation_tex
		sprite.material = animation_tex.get_meta("silhouette_material") if animation_tex.has_meta("silhouette_material") else null
		_base_scale = height / float(animation_tex.get_meta("body_height"))
		sprite.offset = -Vector2(animation_tex.get_meta("anchor"))
		sprite.scale = Vector2.ONE * _base_scale
	var m := Color.WHITE
	if mode == Mode.WARN and (Settings.flag("reduce_flashes") or fmod(_clock, 0.2) > 0.1):
		m = Color(1.35, 1.25, 0.8)
	if mode == Mode.REST:
		m = Color(0.9, 0.9, 1.0)
		if not Settings.flag("reduced_motion"):
			sprite.rotation = sin(_clock * 8.0) * 0.04
	else:
		sprite.rotation = 0.0
	if _flash > 0.0 and not Settings.flag("reduce_flashes"):
		m = Color(2.0, 2.0, 2.0)
	sprite.modulate = m
	if not Settings.flag("reduced_motion"):
		var breathe := 1.0 + sin(_clock * 3.0) * 0.02
		sprite.scale = Vector2(_base_scale / breathe, _base_scale * breathe)


# ---------------------------------------------------------------- attacks --

func _run_attack(d: float, to: Vector2) -> void:
	_timer -= d
	match _attack:
		"stomp", "slam":
			if _step == 0:
				_leap(to.x * 0.9, -980.0)
				_step = 1
			elif _step == 1 and is_on_floor() and velocity.y >= 0.0 and _timer < -0.3:
				if _attack == "slam":
					_spikes_at(level.player.global_position.x)
				_rest(2.0)
		"hop_slam", "bounce", "roll":
			if _timer <= 0.0 and is_on_floor():
				if _step >= 3:
					_rest(2.0)
				else:
					_step += 1
					_timer = 0.25
					var reach := clampf(to.x, -360.0, 360.0) if _attack != "bounce" else (arena_right - arena_left) * 0.45 * -signf(global_position.x - (arena_left + arena_right) * 0.5)
					_leap(reach, -760.0 if _attack != "bounce" else -980.0)
		"spores", "seeds", "bombs", "cannons":
			if _timer <= 0.0:
				if _step >= (3 if _attack != "spores" else 2):
					_rest(1.8)
				else:
					_step += 1
					_timer = 0.55
					_volley()
		"rush", "dash", "blizzard":
			if _step == 0:
				facing = signf(to.x) if to.x != 0.0 else facing
				velocity.x = facing * (560.0 if _attack != "blizzard" else 420.0)
				if bool(info.get("flies", false)):
					velocity.y = 260.0
				_step = 1
				_timer = 1.6
				AudioService.play_varied("enemy_rush", -3.0)
				if _attack == "blizzard":
					_gust = 1.6
					_gust_dir = facing
			elif _step == 1:
				if bool(info.get("flies", false)) and position.y > _hover_y + 150.0:
					velocity.y = 0.0
				var at_edge := (facing > 0.0 and position.x >= arena_right - 4.0) or (facing < 0.0 and position.x <= arena_left + 4.0)
				if at_edge or _timer <= 0.0 or is_on_wall():
					velocity = Vector2.ZERO
					level.shake(5.0)
					_rest(2.2)
		"rain":
			if _timer <= 0.0:
				if _step >= 7:
					_rest(1.8)
				else:
					_step += 1
					_timer = 0.28
					var x := clampf(level.player.global_position.x + randf_range(-260.0, 260.0), arena_left, arena_right)
					Projectile.fire(level, Vector2(x, global_position.y - 620.0), Vector2(0, 120.0), {
						"hostile": true, "look": "ball", "color": Color("ff8ac4"), "radius": 13.0, "fall": 520.0, "life": 3.0, "spin": 6.0, "source": self})
		"wave":
			if _timer <= 0.0:
				if _step >= 2:
					_rest(1.8)
				else:
					_step += 1
					_timer = 0.9
					_shockwaves(340.0)
					level.shake(4.0)
					AudioService.play_varied("thud", -3.0)
		"beam":
			if _step == 0:
				_step = 1
				_timer = 0.5
			elif _timer <= 0.0:
				# a low beam straight across: jump it
				var from := global_position + Vector2(facing * 40.0, -34.0)
				var end := from + Vector2(facing * 1400.0, 0)
				IceBeam.fire(level, from, end)
				AudioService.play("beam")
				var p := level.player
				if signf(p.global_position.x - global_position.x) == facing and p.global_position.y > from.y - 26.0 and p.global_position.y - 56.0 < from.y + 14.0:
					p.hurt(global_position)
				_rest(2.0)
		"spikes":
			if _timer <= 0.0:
				if _step >= 3:
					_rest(1.8)
				else:
					_step += 1
					_timer = 0.8
					_spikes_at(level.player.global_position.x)
		"gust":
			if _step == 0:
				_step = 1
				_gust = 2.6
				_gust_dir = signf(level.player.global_position.x - global_position.x)
				if _gust_dir == 0.0:
					_gust_dir = 1.0
				_timer = 2.6
				AudioService.play("whistle")
			elif _timer <= 0.0:
				_rest(1.6)
		_:
			_rest(1.5)


func _leap(dx: float, up: float) -> void:
	if bool(info.get("flies", false)):
		return
	velocity = Vector2(dx / 1.15, up)
	AudioService.play_varied("boing", -4.0)


## Two little waves run along the ground, left and right: jump them.
func _shockwaves(speed: float) -> void:
	for dir: float in [-1.0, 1.0]:
		Projectile.fire(level, global_position + Vector2(dir * 60.0, -18.0), Vector2(dir * speed, 0), {
			"hostile": true, "look": "ball", "color": Color(1, 1, 1, 0.9), "radius": 16.0, "life": 2.2, "source": self})


func _volley() -> void:
	var p := level.player
	var d := p.global_position - global_position
	facing = signf(d.x) if d.x != 0.0 else facing
	var from := global_position + Vector2(facing * 50.0, -height * 0.6)
	match _attack:
		"spores":
			for i in 4:
				var vx := (-260.0 + i * 170.0) + randf_range(-30.0, 30.0)
				Projectile.fire(level, from, Vector2(vx, -620.0), {"hostile": true, "look": "ball", "color": Color("d98ad9"), "radius": 11.0, "fall": 820.0, "life": 3.0, "source": self})
		"seeds":
			for a: float in [-0.22, 0.0, 0.22]:
				var v := Vector2(facing * 430.0, -40.0).rotated(a * facing)
				Projectile.fire(level, from, v, {"hostile": true, "look": "ball", "color": Color("5a3a22"), "radius": 9.0, "life": 2.4, "source": self})
		"bombs":
			Projectile.fire(level, from, Vector2(clampf(d.x * 0.85, -420.0, 420.0), -640.0), {
				"hostile": true, "look": "tomato", "radius": 15.0, "fall": 1000.0, "life": 2.6, "splash": 96.0, "color": Color("ff9a3c"), "spin": 5.0, "source": self})
		"cannons":
			Projectile.fire(level, global_position + Vector2(0, -20), Vector2(clampf(d.x * 0.7, -380.0, 380.0) + randf_range(-60.0, 60.0), -120.0), {
				"hostile": true, "look": "ball", "color": Color("5a5f78"), "radius": 14.0, "fall": 700.0, "life": 3.0, "source": self})
	AudioService.play_varied("enemy_shot", -4.0)


## A warning mark on the ground, then spikes jump up there.
func _spikes_at(x: float) -> void:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(Vector2(x, global_position.y - 300.0), Vector2(x, global_position.y + 300.0), Layers.WORLD)
	var hit := space.intersect_ray(q)
	var ground := global_position.y if hit.is_empty() else float((hit["position"] as Vector2).y)
	var spike := GroundSpike.new()
	spike.level = level
	level.add_child(spike)
	spike.global_position = Vector2(x, ground)


func _summon(kind: String, count: int) -> void:
	for i in count:
		var cell := level.cell_at(Vector2(lerpf(arena_left, arena_right, 0.25 + 0.5 * i), global_position.y - 40.0))
		var e := EntityFactory.create(level, {"type": kind, "cell": cell, "args": [], "params": {}})
		if e != null:
			level.entities.add_child(e)
			Fx.puff(level, (e as Node2D).global_position, Color(1, 1, 1, 0.8), 5)
	Captions.caption("Helpers march in!")


class GroundSpike:
	extends Node2D

	var level: Level
	var _age := 0.0
	var _hit := false

	func _ready() -> void:
		z_index = 3

	func _physics_process(delta: float) -> void:
		_age += delta
		queue_redraw()
		if _age > 0.6 and not _hit:
			_hit = true
			AudioService.play_varied("freeze", -4.0)
			var p := level.player
			if absf(p.global_position.x - global_position.x) < 44.0 and p.global_position.y > global_position.y - 90.0:
				p.hurt(global_position)
		if _age > 1.2:
			queue_free()

	func _draw() -> void:
		if _age < 0.6:
			var a := 0.4 + 0.5 * absf(sin(_age * 20.0))
			draw_rect(Rect2(-40, -6, 80, 6), Color(1.0, 0.3, 0.3, a))
		else:
			var k := clampf((_age - 0.6) / 0.12, 0.0, 1.0) * clampf((1.2 - _age) / 0.2, 0.0, 1.0)
			for i in 3:
				var x := -28.0 + i * 28.0
				draw_colored_polygon(PackedVector2Array([Vector2(x - 13, 0), Vector2(x, -86.0 * k), Vector2(x + 13, 0)]), Color("a9e9f8"))
				draw_polyline(PackedVector2Array([Vector2(x - 13, 0), Vector2(x, -86.0 * k), Vector2(x + 13, 0)]), Color("35507a"), 3.0, true)


class IceBeam:
	extends Node2D

	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var _age := 0.0

	static func fire(parent: Node, from: Vector2, to: Vector2) -> void:
		var beam := IceBeam.new()
		beam.a = from
		beam.b = to
		beam.z_index = 14
		parent.add_child(beam)

	func _process(delta: float) -> void:
		_age += delta
		queue_redraw()
		if _age > 0.35:
			queue_free()

	func _draw() -> void:
		var w := 30.0 * (1.0 - _age / 0.35)
		draw_line(a, b, Color(0.6, 0.9, 1.0, 0.5), w + 12.0)
		draw_line(a, b, Color("a9e9f8"), w)
		draw_line(a, b, Color(1, 1, 1), w * 0.4)
