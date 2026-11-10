class_name Enemy
extends CharacterBody2D
## Shared machinery for every creature: health, being hit, the elemental
## states (frozen, stuck in honey, floating in a bubble, dizzy), stomping,
## bumping Tato, and the friendly "poof" when defeated (they drop coins and
## that is all: nobody is hurt for real).

signal defeated(enemy: Enemy)

var level: Level
var params: Dictionary = {}
var kind := "slime_blob"
var stats: Dictionary = {}
var hp := 1
var home := Vector2.ZERO
var facing := -1.0
var sprite: Sprite2D
var height := 56.0
var dead := false
var touch_hurts := true
var armored := false            # true while a hit should just go "clink"

var stun_left := 0.0
var frozen_left := 0.0
var stuck_left := 0.0
var bubble_left := 0.0
var flash_left := 0.0
var shot_timer := 0.0

var _touch: Area2D
var _ice: StaticBody2D
var _art_faces := 1.0
var _base_scale := 0.5
var _spawned := false
const SLEEP_DISTANCE := 1500.0
var _hit_dir := 0.0
var _visual_time := 0.0
var _visual_squash := 1.0
var _visual_recoil := 0.0


func setup(lv: Level, e: Dictionary) -> void:
	level = lv
	params = e.get("params", {})
	kind = str(params.get("type", kind))
	stats = EnemyData.STATS.get(kind, {})
	hp = int(stats.get("hp", 1))
	height = float(stats.get("h", 56.0))
	_art_faces = float(stats.get("faces", 1))
	position = LevelData.cell_floor(e.get("cell", Vector2i.ZERO))
	home = position
	collision_layer = Layers.ENEMY
	collision_mask = Layers.WORLD | Layers.ONEWAY
	add_to_group("enemy")
	add_to_group("hittable")
	add_to_group("resettable")
	z_index = 1
	facing = 1.0 if bool(params.get("right", false)) else -1.0
	shot_timer = float(stats.get("every", 2.0)) * randf_range(0.4, 1.0)
	_build()
	_configure()


func _build() -> void:
	sprite = Art.standing("enemies/" + kind)
	if sprite.texture != null:
		_base_scale = height / float(sprite.texture.get_height())
	sprite.scale = Vector2(_base_scale, _base_scale)
	add_child(sprite)
	var w := height * 0.72
	var shape := CapsuleShape2D.new()
	shape.radius = minf(w * 0.5, height * 0.45)
	shape.height = maxf(height * 0.9, shape.radius * 2.0)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -shape.height * 0.5)
	add_child(cs)
	_touch = Area2D.new()
	_touch.collision_layer = 0
	_touch.collision_mask = Layers.PLAYER
	var tshape := RectangleShape2D.new()
	tshape.size = Vector2(w * 0.9, height * 0.8)
	var tcs := CollisionShape2D.new()
	tcs.shape = tshape
	tcs.position = Vector2(0, -height * 0.45)
	_touch.add_child(tcs)
	add_child(_touch)
	# the block of ice a frozen creature turns into
	_ice = StaticBody2D.new()
	_ice.collision_layer = 0
	_ice.collision_mask = 0
	_ice.add_to_group("ice")
	var ishape := RectangleShape2D.new()
	ishape.size = Vector2(w + 10.0, height * 0.92)
	var ics := CollisionShape2D.new()
	ics.shape = ishape
	ics.position = Vector2(0, -height * 0.46)
	_ice.add_child(ics)
	add_child(_ice)


func _configure() -> void:
	pass


func stat(key: String, fallback: Variant = null) -> Variant:
	return stats.get(key, fallback)


func clock() -> float:
	## Creature time: slower in Cozy Mode and while a Time pickup is running.
	var s := Settings.enemy_speed()
	if level != null:
		s *= level.enemy_time
	return s


func is_busy() -> bool:
	return dead or stun_left > 0.0 or frozen_left > 0.0 or stuck_left > 0.0 or bubble_left > 0.0


# -------------------------------------------------------------------- hits --

func take_hit(damage: int, info: Dictionary) -> bool:
	if dead:
		return false
	var element: StringName = info.get("element", &"plain")
	if (stats.get("immune", []) as Array).has(String(element)):
		_clink()
		return true
	if armored or _blocks(info):
		_clink()
		return true
	var dmg := damage
	if (stats.get("weak", []) as Array).has(String(element)):
		dmg *= 2
	match element:
		&"ice":
			_freeze(4.5)
		&"honey":
			stuck_left = 4.0 * Settings.timer_factor()
			AudioService.play_varied("squelch", -6.0)
		&"bubble":
			if hp <= dmg or not bool(stats.get("heavy", false)):
				bubble_left = 2.6
				velocity = Vector2(0, -90)
		&"shock":
			stun_left = maxf(stun_left, 1.4)
		&"stomp":
			stun_left = maxf(stun_left, 0.3)
	hp -= dmg
	flash_left = 0.14
	_visual_recoil = 1.0
	if not bool(stats.get("heavy", false)) and frozen_left <= 0.0 and bubble_left <= 0.0:
		var dir: Vector2 = info.get("dir", Vector2.ZERO)
		velocity.x = dir.x * float(info.get("knock", 180.0))
		if is_on_floor():
			velocity.y = -150.0
	_on_hit(info)
	_hit_dir = signf((info.get("dir", Vector2.ZERO) as Vector2).x)
	if hp <= 0:
		# a bubbled creature floats off before it pops
		if bubble_left > 0.0:
			return true
		defeat()
	else:
		AudioService.play_varied("enemy_hit", -5.0)
		_hit_feedback(false)
	return true


## Sparks, a tiny pause and a shake so every hit reads clearly.
func _hit_feedback(final: bool) -> void:
	if level == null:
		return
	var at := global_position + Vector2(0, -height * 0.55)
	Fx.sparkle(level, at, Color(1.0, 0.97, 0.7), 7 if final else 4)
	Fx.pop_ring(level, at, Color(1, 1, 1, 0.9), height * (0.9 if final else 0.55))
	level.shake(5.0 if final else 2.5)
	level.hit_pause(0.07 if final else 0.04)


## Onion Knights (and friends) turn shots from the front aside.
func _blocks(_info: Dictionary) -> bool:
	return false


func _on_hit(_info: Dictionary) -> void:
	pass


func _clink() -> void:
	AudioService.play_varied("clink", -6.0)
	Fx.burst(level, global_position + Vector2(0, -height * 0.6), "sparkle", Color(0.9, 0.9, 1.0), 3, {"spread": 18.0, "life": 0.25, "size": 5.0})


func _freeze(seconds: float) -> void:
	frozen_left = seconds * Settings.timer_factor()
	_ice.collision_layer = Layers.WORLD
	velocity = Vector2.ZERO
	AudioService.play_varied("freeze", -6.0)


func stun(seconds: float) -> void:
	stun_left = maxf(stun_left, seconds)


func defeat() -> void:
	if dead:
		return
	dead = true
	defeated.emit(self)
	collision_layer = 0
	_ice.collision_layer = 0
	_touch.set_deferred("monitoring", false)
	remove_from_group("hittable")
	GameState.meet_enemy(kind)
	AudioService.play_varied("poof", -3.0)
	Fx.puff(level, global_position + Vector2(0, -height * 0.5), Color(1, 1, 1, 0.9), 6)
	Fx.sparkle(level, global_position + Vector2(0, -height * 0.5), Color(1, 0.95, 0.6), 5)
	if level != null:
		level.drop_coins(global_position + Vector2(0, -height * 0.5), int(stats.get("coins", 1)))
		level.on_enemy_defeated(self)
	_hit_feedback(true)
	# knocked up and away, spinning, then gone
	var away := _hit_dir if _hit_dir != 0.0 else -facing
	var from := sprite.position
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(sprite, "position:x", from.x + away * 90.0, 0.42)
	t.tween_property(sprite, "position:y", from.y - 70.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(sprite, "position:y", from.y + 40.0, 0.24).set_delay(0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if not Settings.flag("reduced_motion"):
		t.tween_property(sprite, "rotation", away * TAU * 0.75, 0.42)
	t.tween_property(sprite, "modulate:a", 0.0, 0.16).set_delay(0.26)
	t.chain().tween_callback(func() -> void: visible = false)


# ------------------------------------------------------------------- frame --

func _physics_process(delta: float) -> void:
	if dead:
		return
	if not _spawned:
		_spawned = true
		GameState.meet_enemy(kind) if false else null
	# Far-away creatures rest (keeps older phones and tablets smooth); they
	# wake as Tato gets within about a screen and a half.
	if level != null and level.player != null and absf(level.player.global_position.x - global_position.x) > SLEEP_DISTANCE \
			and frozen_left <= 0.0 and bubble_left <= 0.0 and flash_left <= 0.0:
		return
	var d := delta * clock()
	_visual_time += d
	_visual_recoil = move_toward(_visual_recoil, 0.0, 5.5 * delta)
	flash_left = maxf(flash_left - delta, 0.0)
	if frozen_left > 0.0:
		frozen_left -= delta
		velocity = Vector2.ZERO
		if frozen_left <= 0.0:
			_ice.collision_layer = 0
	elif bubble_left > 0.0:
		bubble_left -= delta
		velocity = Vector2(sin(bubble_left * 5.0) * 30.0, -95.0)
		move_and_slide()
		if bubble_left <= 0.0:
			Fx.pop_ring(level, global_position + Vector2(0, -height * 0.5), Color(0.85, 0.75, 1.0), 44.0)
			AudioService.play_varied("pop", -3.0)
			if hp <= 0:
				defeat()
				return
	elif stuck_left > 0.0:
		stuck_left -= delta
		velocity.x = 0.0
		_fall(d)
		move_and_slide()
	elif stun_left > 0.0:
		stun_left -= delta
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		_fall(d)
		move_and_slide()
	else:
		_behave(d)
	_contact()
	_look()
	if level != null and global_position.y > level.kill_plane_y():
		dead = true
		visible = false
		collision_layer = 0
		remove_from_group("hittable")


func _behave(_delta: float) -> void:
	pass


func _fall(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + 1500.0 * delta, 820.0)


func _contact() -> void:
	if not touch_hurts or frozen_left > 0.0 or bubble_left > 0.0:
		return
	for body in _touch.get_overlapping_bodies():
		if body is Tato:
			_bump(body as Tato)


func _bump(player: Tato) -> void:
	if player.star_time > 0.0:
		take_hit(9, {"element": &"star", "source": player, "dir": Vector2(signf(global_position.x - player.global_position.x), 0), "knock": 300.0})
		return
	if player.is_shielded():
		return
	# jumping on top of most creatures bops them
	# (overlaps are reported a frame late, so be generous about "from above":
	# falling, with Tato's feet above the creature's feet, is a stomp)
	var from_above := player.velocity.y > 40.0 and player.global_position.y < global_position.y - height * 0.12
	if from_above and not player.is_on_floor():
		if bool(stats.get("stomp", true)):
			take_hit(1, {"element": &"stomp", "source": player, "dir": Vector2.ZERO, "knock": 0.0})
			player.bounce()
			AudioService.play_varied("stomp", -3.0)
			return
		player.bounce(Tato.STOMP_BOUNCE * 0.8)
	if stuck_left > 0.0 or stun_left > 0.0:
		return
	player.hurt(global_position)


func _look() -> void:
	if sprite == null:
		return
	sprite.flip_h = (facing * _art_faces) < 0.0
	var frame_id := int(_visual_time * (9.0 if absf(velocity.x) > 15.0 else 4.0)) % 4
	if frozen_left > 0.0 or Settings.flag("reduced_motion"):
		frame_id = 0
	var animation_tex := Art.tex("enemies/anim/%s_%d" % [kind, frame_id])
	if animation_tex != null:
		sprite.texture = animation_tex
	var m := Color.WHITE
	if frozen_left > 0.0:
		m = Color(0.6, 0.85, 1.0)
		if frozen_left < 1.0:
			m.a = 0.7 + 0.3 * absf(sin(frozen_left * 12.0))
	elif stuck_left > 0.0:
		m = Color(1.0, 0.85, 0.45)
	elif bubble_left > 0.0:
		m = Color(0.9, 0.82, 1.0)
	if flash_left > 0.0 and not Settings.flag("reduce_flashes"):
		m = Color(2.0, 2.0, 2.0)
	sprite.modulate = m
	# Give even single-image creatures a readable locomotion and impact cycle.
	# This is procedural support until proper multi-pose enemy art is integrated.
	var reduced := Settings.flag("reduced_motion")
	var active := not reduced and not is_busy()
	var moving := active and absf(velocity.x) > 10.0
	var pace := 10.0 if moving else 2.7
	var motion := sin(_visual_time * pace)
	var bob := -absf(motion) * (3.5 if moving else 1.2)
	if kind in ["bee_buzzer", "crow_swooper", "pie_bat", "ghost_poof", "balloon_jelly"]:
		bob = sin(_visual_time * 5.6) * (3.0 if not reduced else 0.0)
	elif frozen_left > 0.0 or stuck_left > 0.0:
		bob = 0.0
	var recover := _visual_recoil
	var wide := 1.0 + (absf(motion) * 0.045 if moving else sin(_visual_time * 2.7) * 0.012)
	var tall := 1.0 - (absf(motion) * 0.042 if moving else sin(_visual_time * 2.7) * 0.012)
	sprite.scale = Vector2(_base_scale * (wide + recover * 0.14), _base_scale * (tall - recover * 0.12))
	sprite.position = Vector2(-facing * recover * 6.0, bob)
	if stun_left > 0.0 and not reduced:
		sprite.rotation = sin(_visual_time * 27.0) * 0.11
	elif active:
		sprite.rotation = sin(_visual_time * pace) * (0.035 if moving else 0.012)
	else:
		sprite.rotation = 0.0


# ---------------------------------------------------------------- helpers --

func player() -> Tato:
	return level.player if level != null else null


func to_player() -> Vector2:
	var p := player()
	return (p.global_position - global_position) if p != null else Vector2(9999, 0)


func ground_ahead(dir: float, reach: float = 24.0) -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(dir * reach, -8)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 34), Layers.WORLD | Layers.ONEWAY)
	return not space.intersect_ray(q).is_empty()


func wall_ahead(dir: float, reach: float = 26.0) -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(0, -height * 0.4)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(dir * reach, 0), Layers.WORLD)
	q.exclude = [_ice.get_rid()]
	return not space.intersect_ray(q).is_empty()


## A creature's shot toward Tato (never while he is far away or out of sight).
func shoot_at_player(delta: float) -> bool:
	var look := str(stats.get("shot", ""))
	if look == "":
		return false
	shot_timer -= delta
	if shot_timer > 0.0:
		return false
	var d := to_player()
	if d.length() > float(stats.get("range", 420.0)) or absf(d.y) > 260.0:
		return false
	shot_timer = float(stats.get("every", 2.2))
	facing = signf(d.x) if d.x != 0.0 else facing
	var from := global_position + Vector2(facing * 20.0, -height * 0.6)
	var vel := Vector2(facing * 300.0, 0.0)
	var opts := {"hostile": true, "look": look, "radius": 10.0, "life": 2.2, "source": self}
	match look:
		"arrow":
			vel = Vector2(facing * 400.0, -150.0)
			opts["fall"] = 320.0
			opts["color"] = Color("d9dde8")
		"fire":
			vel = Vector2(facing * 300.0, 0.0)
			opts["look"] = "fire"
			opts["life"] = 1.0
			opts["radius"] = 12.0
		"snow":
			vel = Vector2(facing * 330.0, -60.0)
			opts["fall"] = 200.0
			opts["look"] = "ball"
			opts["color"] = Color("e8fbff")
		"candy":
			vel = Vector2(clampf(d.x * 0.9, -330.0, 330.0), -470.0)
			opts["fall"] = 900.0
			opts["look"] = "ball"
			opts["color"] = Color("ff8ac4")
			opts["spin"] = 8.0
		"rock":
			vel = Vector2(clampf(d.x * 0.95, -300.0, 300.0), -500.0)
			opts["fall"] = 950.0
			opts["look"] = "ball"
			opts["color"] = Color("9a7b5a")
	Projectile.fire(level, from, vel, opts)
	AudioService.play_varied("enemy_shot", -8.0)
	sprite.scale = Vector2(_base_scale * 1.15, _base_scale * 0.88)
	create_tween().tween_property(sprite, "scale", Vector2(_base_scale, _base_scale), 0.2)
	return true


func reset_puzzle() -> void:
	# creatures that were not defeated go back to where they started
	if dead:
		return
	position = home
	velocity = Vector2.ZERO
	stun_left = 0.0
	frozen_left = 0.0
	stuck_left = 0.0
	bubble_left = 0.0
	_ice.collision_layer = 0
