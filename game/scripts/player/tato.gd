class_name Tato
extends CharacterBody2D
## Tato the gosling. Origin is at the feet.
##
## Three buttons: move, jump (again in the air to flap), attack. With no
## power-up the attack is a honk; with one it is that power's attack. Input
## is read into `move_x` / `move_y` and a few "pressed this frame" flags, a
## small state machine decides what Tato is doing, and a power (AbilityRunner)
## may take over movement for a moment (Garlic Dash). Animation squash and
## stretch never touch the collision capsule.

signal state_changed(state: int)
signal honked(kind: StringName)
signal power_changed(power: StringName)
signal got_hurt
signal fell_out
signal interact_target_changed(target: Node)
signal landed(impact: float)

enum State { IDLE, WALK, RUN, JUMP, FALL, CROUCH, SLIDE, SWIM, ATTACK, ABILITY, HURT, DISABLED }

# --- tuning (pixels, seconds). Starting values from the design doc, adjusted by play.
const WALK_SPEED := 215.0
const RUN_SPEED := 335.0
const RUN_DELAY := 0.5
const ACCEL := 1500.0
const DECEL := 1900.0
const AIR_ACCEL := 1150.0
const AIR_DECEL := 420.0
const ICE_ACCEL := 420.0
const ICE_DECEL := 150.0
const JUMP_VELOCITY := -690.0     # a held jump clears two tiles with room to spare
const JUMP_CUT := 0.45
const GRAVITY := 1500.0
const FALL_GRAVITY := 1850.0
const MAX_FALL := 920.0
const FLAP_VELOCITY := -350.0
const MAX_FLAPS := 3
const GLIDE_FALL := 165.0
const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.12
const SWIM_SPEED := 165.0
const SLIDE_MAX := 540.0
const HONK_COOLDOWN := 0.32
const HONK_RADIUS := 120.0
const INVULN_TIME := 1.6
const STAND_HEIGHT := 56.0
const LOW_HEIGHT := 40.0
const BODY_RADIUS := 20.0
const STOMP_BOUNCE := -520.0

var state: int = State.IDLE
var facing := 1.0
var move_x := 0.0
var move_y := 0.0
var power := PowerSlot.new()
var runner: AbilityRunner
var visual: TatoVisual
var level: Node = null                 # the Level that owns this Tato (may be null in tests)

var flaps_left := MAX_FLAPS
var in_water := false
var on_ice := false
var sliding := false
var crouching := false
var low_shape := false
var invuln := 0.0
var control_lock := 0.0                # seconds input is ignored (eat, hurt)
var honk_cd := 0.0
var last_safe_position := Vector2.ZERO
var interact_target: Node = null
var speed_scale := 1.0
var hurt_count := 0
var slide_lock := 0.0                  # keeps a belly slide going (forced slides)

## Timed boosts from level pickups (seconds left).
var wings_time := 0.0                  # endless flaps
var super_jump_time := 0.0             # mushroom: bigger jumps
var slow_fall_time := 0.0              # feather: floaty falls
var magnet_time := 0.0                 # coins fly to Tato
var star_time := 0.0                   # rainbow star: nothing hurts, creatures poof on touch
var luck_time := 0.0                   # clover: coins count double
var orb_guard := false                 # orb: soaks up the next hit

var _coyote := 0.0
var _jump_buffer := 0.0
var _run_timer := 0.0
var _was_on_floor := false
var _fall_speed := 0.0
var _safe_timer := 0.0
var _drop_timer := 0.0
var _pose_timer := 0.0                 # honk / eat pose time
var _pose := ""
var _glide := false
var _jump_held := false
var _shape: CapsuleShape2D
var _collider: CollisionShape2D
var _interact_area: Area2D
var _step_timer := 0.0
var _attack_repeat := 0.0
var _jump_cut_ready := false


func _ready() -> void:
	add_to_group("player")
	collision_layer = Layers.PLAYER
	collision_mask = Layers.WORLD | Layers.ONEWAY | Layers.PROP
	floor_snap_length = 10.0
	floor_max_angle = deg_to_rad(52.0)
	floor_constant_speed = true
	platform_on_leave = CharacterBody2D.PLATFORM_ON_LEAVE_ADD_UPWARD_VELOCITY
	safe_margin = 0.6
	z_index = 2

	_shape = CapsuleShape2D.new()
	_shape.radius = BODY_RADIUS
	_shape.height = STAND_HEIGHT
	_collider = CollisionShape2D.new()
	_collider.shape = _shape
	_collider.position = Vector2(0, -STAND_HEIGHT * 0.5)
	add_child(_collider)

	visual = TatoVisual.new()
	visual.name = "Visual"
	add_child(visual)
	visual.setup(self)

	runner = AbilityRunner.new()
	runner.name = "AbilityRunner"
	runner.player = self
	add_child(runner)

	_interact_area = Area2D.new()
	_interact_area.name = "InteractArea"
	_interact_area.collision_layer = 0
	_interact_area.collision_mask = Layers.INTERACT
	_interact_area.monitoring = true
	_interact_area.monitorable = false
	var ishape := CircleShape2D.new()
	ishape.radius = 52.0
	var ics := CollisionShape2D.new()
	ics.shape = ishape
	ics.position = Vector2(0, -30)
	_interact_area.add_child(ics)
	add_child(_interact_area)

	power.changed.connect(func(p: StringName, _prev: StringName) -> void: power_changed.emit(p))
	last_safe_position = global_position


# ------------------------------------------------------------------- frame --

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	if state == State.DISABLED:
		_move_disabled(delta)
		_finish_frame(delta)
		return
	_read_input()
	_handle_actions(delta)
	runner.tick(delta)
	if runner.overrides_movement():
		runner.current.move(delta)
	else:
		_move_normal(delta)
	_finish_frame(delta)


func _tick_timers(delta: float) -> void:
	invuln = maxf(invuln - delta, 0.0)
	control_lock = maxf(control_lock - delta, 0.0)
	honk_cd = maxf(honk_cd - delta, 0.0)
	_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	_drop_timer = maxf(_drop_timer - delta, 0.0)
	wings_time = maxf(wings_time - delta, 0.0)
	super_jump_time = maxf(super_jump_time - delta, 0.0)
	slow_fall_time = maxf(slow_fall_time - delta, 0.0)
	magnet_time = maxf(magnet_time - delta, 0.0)
	luck_time = maxf(luck_time - delta, 0.0)
	if star_time > 0.0:
		star_time = maxf(star_time - delta, 0.0)
		if star_time <= 0.0:
			visual.tint = Color.WHITE
	if _pose_timer > 0.0:
		_pose_timer -= delta
		if _pose_timer <= 0.0:
			_pose = ""
	if _drop_timer <= 0.0:
		collision_mask |= Layers.ONEWAY


func _read_input() -> void:
	if control_lock > 0.0:
		move_x = 0.0
		move_y = 0.0
		_jump_held = false
		return
	move_x = Input.get_axis("move_left", "move_right")
	move_y = Input.get_axis("move_up", "move_down")
	if absf(move_x) < 0.2:
		move_x = 0.0
	_jump_held = Input.is_action_pressed("jump")
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER


func _handle_actions(delta: float) -> void:
	if control_lock > 0.0:
		return
	if Input.is_action_just_pressed("move_up") and interact_target != null:
		try_interact()
		return
	_attack_repeat = maxf(_attack_repeat - delta, 0.0)
	var pressed := Input.is_action_just_pressed("attack")
	if not pressed and Settings.flag("hold_to_attack") and Input.is_action_pressed("attack") and _attack_repeat <= 0.0:
		pressed = true
	if pressed:
		_attack_repeat = 0.18
		# the attack button also talks / goes through doors when one is right here
		if interact_target != null and is_instance_valid(interact_target) and interact_target.has_method("uses_attack_button") and interact_target.call("uses_attack_button"):
			try_interact()
		else:
			press_attack()


# ------------------------------------------------------------- normal move --

func _move_normal(delta: float) -> void:
	var floor_now := is_on_floor()
	in_water = _center_in_water()
	if in_water:
		_move_swim(delta)
		return

	if move_x != 0.0:
		facing = signf(move_x)

	on_ice = floor_now and _floor_is_ice()

	# --- crouch / belly slide
	var want_down := move_y > 0.5
	slide_lock = maxf(slide_lock - delta, 0.0)
	if floor_now:
		if sliding:
			var slow := absf(velocity.x) < 70.0 and absf(get_floor_normal().x) < 0.2
			if (not want_down and slide_lock <= 0.0) or slow:
				sliding = false
		elif want_down and (absf(velocity.x) > 240.0 or absf(get_floor_normal().x) > 0.3):
			sliding = true
			AudioService.play("slide")
			visual.squash(Vector2(1.2, 0.8))
		crouching = want_down and not sliding
	else:
		crouching = false
		if sliding and _coyote <= 0.0:
			sliding = false
	_set_low_shape(sliding or crouching)

	# --- horizontal
	if sliding:
		var n := get_floor_normal() if floor_now else Vector2.UP
		velocity.x += n.x * GRAVITY * 0.95 * delta
		var drag := 60.0 if absf(n.x) > 0.2 else 210.0
		if on_ice:
			drag = 25.0
		velocity.x = move_toward(velocity.x, 0.0, drag * delta)
		velocity.x = clampf(velocity.x, -SLIDE_MAX, SLIDE_MAX)
		if absf(velocity.x) > 20.0:
			facing = signf(velocity.x)
	else:
		if floor_now and move_x != 0.0:
			_run_timer += delta
		elif move_x == 0.0:
			_run_timer = 0.0
		var top := WALK_SPEED
		if _run_timer > RUN_DELAY and Settings.flag("auto_run"):
			top = RUN_SPEED
		if crouching:
			top = WALK_SPEED * 0.45
		top *= speed_scale
		var accel := ACCEL
		var decel := DECEL
		if not floor_now:
			accel = AIR_ACCEL
			decel = AIR_DECEL
		elif on_ice:
			accel = ICE_ACCEL
			decel = ICE_DECEL
		if move_x != 0.0:
			# keep momentum above the cap (ice, slides) instead of snapping down
			var target := move_x * top
			if absf(velocity.x) > top and signf(velocity.x) == signf(move_x):
				velocity.x = move_toward(velocity.x, target, decel * 0.35 * delta)
			else:
				velocity.x = move_toward(velocity.x, target, accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, decel * delta)

	# --- vertical
	if floor_now:
		_coyote = COYOTE_TIME
		flaps_left = MAX_FLAPS
		_glide = false
	else:
		_coyote = maxf(_coyote - delta, 0.0)
		var g := GRAVITY if (velocity.y < 0.0 and _jump_held) else FALL_GRAVITY
		velocity.y += g * delta
		var cap := MAX_FALL
		if (_glide and _jump_held and velocity.y > 0.0) or (slow_fall_time > 0.0 and velocity.y > 0.0):
			cap = GLIDE_FALL
		velocity.y = minf(velocity.y, cap)

	if _jump_buffer > 0.0:
		if want_down and floor_now and _on_oneway():
			# drop through a thin platform
			_jump_buffer = 0.0
			collision_mask &= ~Layers.ONEWAY
			_drop_timer = 0.28
			position.y += 2.0
			_coyote = 0.0
		elif _coyote > 0.0:
			do_jump(JUMP_VELOCITY * (1.22 if super_jump_time > 0.0 else 1.0))
		elif flaps_left > 0 or wings_time > 0.0:
			do_flap()

	# variable jump height: letting go early cuts the rise once
	if _jump_cut_ready and velocity.y < 0.0 and not _jump_held:
		velocity.y *= JUMP_CUT
		_jump_cut_ready = false
	if velocity.y >= 0.0:
		_jump_cut_ready = false

	_fall_speed = velocity.y
	_was_on_floor = floor_now
	move_and_slide()
	_after_slide(delta)


func do_jump(speed: float) -> void:
	_jump_buffer = 0.0
	_coyote = 0.0
	sliding = false
	velocity.y = speed
	_jump_cut_ready = true
	state = State.JUMP
	visual.squash(Vector2(0.82, 1.22))
	AudioService.play_varied("jump", -4.0)
	Fx.puff(get_parent(), global_position, Color(1, 1, 1, 0.7), 3)


func do_flap() -> void:
	_jump_buffer = 0.0
	if wings_time <= 0.0:
		flaps_left -= 1
	_glide = true
	velocity.y = minf(velocity.y, 0.0) * 0.35 + FLAP_VELOCITY
	visual.flap()
	visual.squash(Vector2(1.12, 0.92))
	AudioService.play_varied("flap", -5.0, 0.12)
	Fx.puff(get_parent(), global_position + Vector2(0, -8), Color(1, 1, 1, 0.55), 2)


## Starts a belly slide at the given speed that lasts at least `seconds`.
func force_slide(speed: float, seconds: float) -> void:
	sliding = true
	slide_lock = seconds
	velocity.x = facing * speed
	visual.squash(Vector2(1.25, 0.78))


## Lets a snack power use up a buffered jump press (true if there was one).
func take_jump_press() -> bool:
	if _jump_buffer > 0.0:
		_jump_buffer = 0.0
		return true
	return false


## Hop off something bouncy (a stomped creature, a spring).
func bounce(speed: float = STOMP_BOUNCE) -> void:
	velocity.y = speed * (1.25 if _jump_held else 1.0)
	flaps_left = MAX_FLAPS
	_jump_cut_ready = false
	_glide = false
	visual.squash(Vector2(0.8, 1.25))


func _after_slide(_delta: float) -> void:
	var floor_now := is_on_floor()
	if floor_now and not _was_on_floor:
		_on_land(_fall_speed)
	if not floor_now and _was_on_floor and velocity.y >= 0.0 and state != State.JUMP:
		_coyote = COYOTE_TIME


func _on_land(impact: float) -> void:
	landed.emit(impact)
	if impact > 260.0:
		var amount := clampf(impact / MAX_FALL, 0.2, 1.0)
		visual.squash(Vector2(1.0 + 0.3 * amount, 1.0 - 0.28 * amount))
		Fx.puff(get_parent(), global_position, Color(1, 1, 1, 0.75), 4)
		AudioService.play_varied("land", lerpf(-12.0, -3.0, amount))


# ------------------------------------------------------------------- swim --

func _move_swim(delta: float) -> void:
	sliding = false
	crouching = false
	_set_low_shape(false)
	flaps_left = MAX_FLAPS
	_glide = false
	if move_x != 0.0:
		facing = signf(move_x)
	velocity.x = move_toward(velocity.x, move_x * SWIM_SPEED * speed_scale, 900.0 * delta)
	# float with the chest at the surface
	var surface := _water_surface_y()
	var float_y := surface + 20.0          # feet position that looks like floating
	var depth := global_position.y - float_y
	velocity.y += (-depth * 26.0 - velocity.y * 5.0) * delta
	velocity.y = clampf(velocity.y, -360.0, 300.0)
	if _jump_buffer > 0.0:
		_jump_buffer = 0.0
		velocity.y = JUMP_VELOCITY * 0.88
		state = State.JUMP
		in_water = false
		visual.squash(Vector2(0.85, 1.18))
		AudioService.play_varied("splash", -4.0)
		Fx.puff(get_parent(), Vector2(global_position.x, surface), Color(0.8, 0.95, 1.0, 0.8), 5)
	_was_on_floor = false
	_coyote = 0.0
	move_and_slide()


func _center_in_water() -> bool:
	if level == null or not level.has_method("water_at"):
		return false
	return level.water_at(global_position + Vector2(0, -22.0))


func _water_surface_y() -> float:
	if level != null and level.has_method("water_surface_at"):
		return level.water_surface_at(global_position + Vector2(0, -22.0))
	return global_position.y


# ---------------------------------------------------------------- disabled --

func _move_disabled(delta: float) -> void:
	move_x = 0.0
	move_y = 0.0
	if not is_on_floor():
		velocity.y = minf(velocity.y + FALL_GRAVITY * delta, MAX_FALL)
	velocity.x = move_toward(velocity.x, 0.0, DECEL * delta)
	move_and_slide()


func set_disabled(value: bool) -> void:
	if value:
		runner.cancel()
		sliding = false
		crouching = false
		_set_state(State.DISABLED)
	elif state == State.DISABLED:
		_set_state(State.IDLE)


# ------------------------------------------------------------ after moving --

func _finish_frame(delta: float) -> void:
	_update_state()
	_track_safe_ground(delta)
	_update_interact_target()
	_footsteps(delta)
	if level != null and level.has_method("kill_plane_y") and global_position.y > level.kill_plane_y():
		fell_out.emit()


func _update_state() -> void:
	if state == State.DISABLED:
		return
	var s := State.IDLE
	if control_lock > 0.0 and _pose == "hurt":
		s = State.HURT
	elif runner.overrides_movement():
		s = State.ABILITY
	elif in_water:
		s = State.SWIM
	elif not is_on_floor():
		s = State.JUMP if velocity.y < 0.0 else State.FALL
	elif sliding:
		s = State.SLIDE
	elif crouching:
		s = State.CROUCH
	elif _pose == "honk":
		s = State.ATTACK
	elif absf(velocity.x) > RUN_SPEED * 0.82:
		s = State.RUN
	elif absf(velocity.x) > 18.0:
		s = State.WALK
	_set_state(s)


func _set_state(s: int) -> void:
	if s == state:
		return
	state = s
	state_changed.emit(state)


func _track_safe_ground(delta: float) -> void:
	_safe_timer -= delta
	if _safe_timer > 0.0 or not is_on_floor() or runner.overrides_movement() or invuln > 0.0:
		return
	_safe_timer = 0.2
	var col := get_last_slide_collision()
	if col == null:
		return
	var body := col.get_collider() as Node
	if body == null or not body.is_in_group("safe_ground") and not (body.get_parent() is Terrain):
		return
	if body.is_in_group("ice"):
		return
	# only remember spots with ground under both feet, so respawns never
	# teeter on an edge
	var space := get_world_2d().direct_space_state
	for off: float in [-26.0, 26.0]:
		var q := PhysicsRayQueryParameters2D.create(global_position + Vector2(off, -10), global_position + Vector2(off, 26), Layers.WORLD)
		if space.intersect_ray(q).is_empty():
			return
	last_safe_position = global_position


func _footsteps(delta: float) -> void:
	if state != State.WALK and state != State.RUN:
		_step_timer = 0.0
		return
	_step_timer -= delta
	if _step_timer <= 0.0:
		_step_timer = 0.3 if state == State.WALK else 0.2
		AudioService.play_varied("step", -14.0, 0.15)


func _floor_is_ice() -> bool:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var body := col.get_collider() as Node
		if body != null and body.is_in_group("ice") and col.get_normal().y < -0.5:
			return true
	return false


func _on_oneway() -> bool:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var body := col.get_collider() as CollisionObject2D
		if body != null and (body.collision_layer & Layers.ONEWAY) != 0:
			return true
	return false


func _set_low_shape(low: bool) -> void:
	if low == low_shape:
		return
	if not low and not _can_stand():
		return
	low_shape = low
	var h := LOW_HEIGHT if low else STAND_HEIGHT
	_shape.height = h
	_collider.position = Vector2(0, -h * 0.5)


func _can_stand() -> bool:
	var space := get_world_2d().direct_space_state
	var probe := CapsuleShape2D.new()
	probe.radius = BODY_RADIUS - 2.0
	probe.height = STAND_HEIGHT - 2.0
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = probe
	q.transform = Transform2D(0.0, global_position + Vector2(0, -STAND_HEIGHT * 0.5 - 1.0))
	q.collision_mask = Layers.WORLD | Layers.PROP
	q.exclude = [get_rid()]
	return space.intersect_shape(q, 1).is_empty()


# ------------------------------------------------------------------ attack --

## Where shots leave from (just in front of the beak).
func muzzle() -> Vector2:
	return global_position + Vector2(facing * 26.0, -42.0 if not low_shape else -24.0)


func press_attack() -> void:
	var def := power.definition()
	if def != null:
		if runner.try_activate(def):
			honk_pose(0.22)
		return
	plain_honk()


## The plain honk: a short ring that bops creatures right in front of Tato,
## shoves them back and rattles blocks. Free, with a short cooldown.
func plain_honk() -> void:
	if honk_cd > 0.0:
		return
	honk_cd = HONK_COOLDOWN
	honk_pose()
	AudioService.voice("honk", 0.0, randf_range(0.96, 1.06))
	Hit.burst(get_parent(), global_position + Vector2(facing * 46.0, -36.0), HONK_RADIUS, 1, &"honk", self,
		{"color": Color(1, 1, 1, 0.9), "knock": 260.0})
	honked.emit(&"plain")


func honk_pose(seconds: float = 0.26) -> void:
	_pose = "honk"
	_pose_timer = seconds
	visual.squash(Vector2(1.16, 0.88))
	visual.honk_flash()


## A power bowl was touched: the new power replaces the old one. Swapping
## two different powers sets off their Flavor Burst.
func collect_power(id: StringName) -> void:
	var def := FoodDB.food(id)
	if def == null:
		return
	runner.cancel()
	var previous := power.pick_up(id)
	visual.squash(Vector2(1.18, 0.84))
	AudioService.play("power_up")
	AudioService.voice("honk_happy", -2.0)
	Fx.sparkle(get_parent(), global_position + Vector2(0, -44), def.color.lightened(0.3), 8)
	Fx.float_text(get_parent(), global_position + Vector2(0, -100), def.ability_name + "!", def.color.lightened(0.4))
	if GameState.unlock_food(def.id):
		GameState.toast.emit("New power: %s" % def.display_name, FoodDB.icon(def.icon_path))
	if previous != &"":
		var rec := FoodDB.resolve(previous, id)
		if rec != null:
			GameState.discover_recipe(rec)
			Hit.burst(get_parent(), global_position + Vector2(0, -36), 210.0, 2, &"burst", self,
				{"color": rec.color, "knock": 320.0})
			Fx.float_text(get_parent(), global_position + Vector2(0, -132), rec.display_name + "!", rec.color.lightened(0.45))
			AudioService.play("blend")
			if level != null:
				level.shake(5.0)


## Up button / attack button next to a friend or a door.
func try_interact() -> void:
	if interact_target != null and is_instance_valid(interact_target) and interact_target.has_method("interact"):
		interact_target.call("interact", self)


# -------------------------------------------------------------------- hurt --

func is_shielded() -> bool:
	return star_time > 0.0 or (runner.current != null and runner.current.blocks_hurt())


## Something bonked Tato: knocked back, one heart lost (unless Cozy Mode).
func hurt(from: Vector2, knock: float = 1.0) -> void:
	if invuln > 0.0 or state == State.DISABLED or is_shielded():
		return
	if orb_guard:
		orb_guard = false
		invuln = 0.8
		visual.start_blink(0.8)
		Fx.pop_ring(get_parent(), global_position + Vector2(0, -36), Color(0.8, 0.7, 1.0), 70.0)
		AudioService.play_varied("pop")
		return
	runner.cancel()
	sliding = false
	invuln = INVULN_TIME
	control_lock = 0.34
	_pose = "hurt"
	_pose_timer = 0.34
	hurt_count += 1
	var dir := signf(global_position.x - from.x)
	if dir == 0.0:
		dir = -facing
	velocity = Vector2(dir * 270.0 * knock, -390.0 * knock)
	visual.squash(Vector2(0.8, 1.2))
	visual.start_blink(INVULN_TIME)
	AudioService.voice("honk_hurt", -1.0)
	AudioService.play("bonk", -4.0)
	Fx.burst(get_parent(), global_position + Vector2(0, -40), "crumbs", Color(1, 1, 1, 0.95), 5, {"spread": 40.0, "life": 0.6, "size": 9.0})
	got_hurt.emit()
	if level != null and level.has_method("shake"):
		level.shake(7.0)


## Moves Tato somewhere safe (after a fall or a respawn).
func teleport_to(point: Vector2, keep_invuln: bool = true) -> void:
	runner.cancel()
	velocity = Vector2.ZERO
	sliding = false
	crouching = false
	global_position = point
	reset_physics_interpolation()
	if keep_invuln:
		invuln = INVULN_TIME
		visual.start_blink(INVULN_TIME)
	flaps_left = MAX_FLAPS
	_coyote = 0.0
	in_water = false


func start_star(seconds: float) -> void:
	star_time = seconds
	visual.tint = Color(1.0, 0.95, 0.6)


# ---------------------------------------------------------------- interact --

func _update_interact_target() -> void:
	var best: Node = null
	var best_d := 1e9
	if state != State.DISABLED:
		for area in _interact_area.get_overlapping_areas():
			var target := _find_interactable(area)
			if target == null:
				continue
			if target.has_method("can_interact") and not target.call("can_interact", self):
				continue
			var d := (target as Node2D).global_position.distance_squared_to(global_position + Vector2(0, -30))
			if d < best_d:
				best_d = d
				best = target
	if best != interact_target:
		interact_target = best
		interact_target_changed.emit(best)


func _find_interactable(node: Node) -> Node:
	var n := node
	for i in 3:
		if n == null:
			return null
		if n.has_method("interact"):
			return n
		n = n.get_parent()
	return null


# -------------------------------------------------------------- animation --

## What TatoVisual should show right now.
func anim_hint() -> String:
	if runner.current != null:
		var a := runner.current.anim()
		if a != "":
			return a
	if _pose != "":
		return _pose
	match state:
		State.DISABLED:
			return "idle" if is_on_floor() else "fall"
		State.SWIM:
			return "swim"
		State.JUMP:
			return "jump"
		State.FALL:
			return "glide" if _glide and _jump_held else "fall"
		State.SLIDE:
			return "slide"
		State.CROUCH:
			return "crouch"
		State.RUN:
			return "run"
		State.WALK:
			return "walk"
	return "idle"


func celebrate() -> void:
	set_disabled(true)
	visual.force_anim("cheer", 2.0)
	AudioService.voice("honk_happy")
