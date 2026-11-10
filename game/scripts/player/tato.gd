class_name Tato
extends CharacterBody2D
## Tato the gosling. Origin is at the feet.
##
## Movement is intent based: input is read into `move_x` / `move_y` and a few
## "pressed this frame" flags, the state machine decides what Tato is doing,
## and snack powers (AbilityRunner) may take over movement for a while.
## The collision capsule never changes because of animation squash/stretch;
## only crouch/slide and ball powers switch it on purpose.

signal state_changed(state: int)
signal honked(kind: StringName)
signal ate(food: StringName)
signal got_hurt
signal fell_out
signal replace_needed(food: StringName)
signal interact_target_changed(target: Node)
signal landed(impact: float)

enum State { IDLE, WALK, RUN, JUMP, FALL, CROUCH, SLIDE, SWIM, HONK, EAT, ABILITY, HURT, DISABLED }

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
const JUMP_VELOCITY := -625.0
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
const HONK_COOLDOWN := 0.3
const HONK_RADIUS := 190.0
const INVULN_TIME := 1.6
const STAND_HEIGHT := 56.0
const LOW_HEIGHT := 40.0
const BODY_RADIUS := 20.0

var state: int = State.IDLE
var facing := 1.0
var move_x := 0.0
var move_y := 0.0
var inventory := FoodInventory.new()
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
## Overrides set by snack powers.
var gravity_scale := 1.0
var speed_scale := 1.0
var extra_air_jumps := 0
var sticky := false                    # honey: cling to walls / ceilings
var bouncy := false                    # popcorn: every landing bounces
var noise := 0.0                       # 0 silent .. 1 loud; listening creatures read this
var hurt_count := 0

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
var _pending_food: StringName = &""
var _honk_held := false
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

	last_safe_position = global_position


# ------------------------------------------------------------------- frame --

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	if state == State.DISABLED:
		_move_disabled(delta)
		_finish_frame(delta)
		return
	_read_input()
	_handle_actions()
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
	if _pose_timer > 0.0:
		_pose_timer -= delta
		if _pose_timer <= 0.0:
			_pose = ""
	noise = move_toward(noise, 0.0, delta * 2.5)
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
	_jump_held = Input.is_action_pressed("jump") or Input.is_action_pressed("flap")
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("flap"):
		_jump_buffer = JUMP_BUFFER


func _handle_actions() -> void:
	if control_lock > 0.0:
		return
	if Input.is_action_just_pressed("ability_swap"):
		var before := inventory.active
		inventory.cycle_active()
		if inventory.active != before:
			AudioService.play("swap")
	if Input.is_action_just_pressed("eat_interact"):
		try_interact()
	if Input.is_action_just_pressed("honk_primary"):
		_honk_held = true
		press_honk()
	elif _honk_held and not Input.is_action_pressed("honk_primary"):
		_honk_held = false
		runner.button_released()
	if Input.is_action_just_pressed("fusion"):
		press_fusion()


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
	if floor_now:
		if sliding:
			var slow := absf(velocity.x) < 70.0 and absf(get_floor_normal().x) < 0.2
			if not want_down or slow:
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
		velocity.x = move_toward(velocity.x, 0.0, (60.0 if absf(n.x) > 0.2 else 210.0) * delta)
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
		velocity.y += g * gravity_scale * delta
		var cap := MAX_FALL
		if _glide and _jump_held and velocity.y > 0.0:
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
			do_jump(JUMP_VELOCITY)
		elif extra_air_jumps > 0:
			extra_air_jumps -= 1
			_jump_buffer = 0.0
			velocity.y = JUMP_VELOCITY * 0.9
			air_jump_used()
		elif flaps_left > 0:
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
	flaps_left -= 1
	_glide = true
	velocity.y = minf(velocity.y, 0.0) * 0.35 + FLAP_VELOCITY
	visual.flap()
	visual.squash(Vector2(1.12, 0.92))
	AudioService.play_varied("flap", -5.0, 0.12)
	Fx.puff(get_parent(), global_position + Vector2(0, -8), Color(1, 1, 1, 0.55), 2)


## Lets a snack power use up a buffered jump press (true if there was one).
func take_jump_press() -> bool:
	if _jump_buffer > 0.0:
		_jump_buffer = 0.0
		return true
	return false


func air_jump_used() -> void:
	visual.squash(Vector2(0.85, 1.2))
	AudioService.play_varied("pop", -3.0)
	Fx.pop_ring(get_parent(), global_position + Vector2(0, -10), Color(0.6, 0.85, 1.0), 46.0)


func _after_slide(_delta: float) -> void:
	var floor_now := is_on_floor()
	if floor_now and not _was_on_floor:
		_on_land(_fall_speed)
	if not floor_now and _was_on_floor and velocity.y >= 0.0 and state != State.JUMP:
		_coyote = COYOTE_TIME


func _on_land(impact: float) -> void:
	landed.emit(impact)
	if bouncy:
		return
	if impact > 260.0:
		var amount := clampf(impact / MAX_FALL, 0.2, 1.0)
		visual.squash(Vector2(1.0 + 0.3 * amount, 1.0 - 0.28 * amount))
		Fx.puff(get_parent(), global_position, Color(1, 1, 1, 0.75), 4)
		AudioService.play_varied("land", lerpf(-12.0, -3.0, amount))
		noise = maxf(noise, 0.35)


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
	GameState.tick_charge(delta)
	if level != null and level.has_method("kill_plane_y") and global_position.y > level.kill_plane_y():
		fell_out.emit()


func _update_state() -> void:
	if state == State.DISABLED:
		return
	var s := State.IDLE
	if control_lock > 0.0 and _pose == "hurt":
		s = State.HURT
	elif _pose == "eat":
		s = State.EAT
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
		s = State.HONK
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
		if not is_quiet():
			AudioService.play_varied("step", -14.0, 0.15)
			noise = maxf(noise, 0.25 if state == State.WALK else 0.5)


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


## Used by ball powers: swap the capsule for a circle of the given radius.
func set_ball_shape(radius: float) -> void:
	if radius <= 0.0:
		_shape.radius = BODY_RADIUS
		low_shape = true      # force a recompute
		_set_low_shape(false)
		if low_shape:
			# no headroom: stay small until there is space
			_shape.height = LOW_HEIGHT
			_collider.position = Vector2(0, -LOW_HEIGHT * 0.5)
		return
	_shape.radius = radius
	_shape.height = radius * 2.0
	_collider.position = Vector2(0, -radius)
	low_shape = false


func ball_fits(radius: float) -> bool:
	var space := get_world_2d().direct_space_state
	var probe := CircleShape2D.new()
	probe.radius = radius - 2.0
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = probe
	q.transform = Transform2D(0.0, global_position + Vector2(0, -radius - 1.0))
	q.collision_mask = Layers.WORLD | Layers.PROP
	q.exclude = [get_rid()]
	return space.intersect_shape(q, 1).is_empty()


# ------------------------------------------------------------ honk & foods --

func is_quiet() -> bool:
	return runner.current != null and runner.current.is_quiet()


func is_stealthy() -> bool:
	return runner.current != null and runner.current.is_stealthy()


func press_honk() -> void:
	var food_id := inventory.active_food()
	if food_id != &"":
		var def := FoodDB.food(food_id)
		if def != null and runner.try_activate(def):
			return
		if def != null and runner.current == null and not GameState.can_spend(def.charge_cost):
			Fx.float_text(get_parent(), global_position + Vector2(0, -90), "Need more honk!", UITheme.YELLOW)
	plain_honk()


## The neutral honk: a ring that shakes fruit loose, rings chimes and startles
## light creatures. Free, with a short cooldown.
func plain_honk(quiet: bool = false) -> void:
	if honk_cd > 0.0:
		return
	honk_cd = HONK_COOLDOWN
	honk_pose()
	var hush := quiet or is_quiet()
	if hush:
		AudioService.voice("honk_quiet", -6.0)
	else:
		AudioService.voice("honk", 0.0, randf_range(0.96, 1.06))
		noise = 1.0
	var tags := PackedStringArray(["quiet"]) if hush else PackedStringArray(["honk"])
	EffectPulse.emit(get_parent(), global_position + Vector2(facing * 14.0, -40.0), tags,
		HONK_RADIUS * Settings.honk_range_factor(),
		{"life": 0.32, "color": Color(1, 1, 1, 0.9) if not hush else Color(0.6, 1.0, 0.9, 0.6), "source": self})
	honked.emit(&"quiet" if hush else &"plain")


func honk_pose(seconds: float = 0.28) -> void:
	_pose = "honk"
	_pose_timer = seconds
	visual.squash(Vector2(1.16, 0.88))
	visual.honk_flash()


func press_fusion() -> void:
	var rec := inventory.current_recipe()
	if rec == null:
		if not inventory.is_full():
			Fx.float_text(get_parent(), global_position + Vector2(0, -90), "Need two snacks!", UITheme.CREAM)
			AudioService.play("deny", -6.0)
		return
	if runner.current != null and runner.current.def == rec:
		runner.try_activate(rec)
		return
	if not GameState.can_spend(rec.charge_cost):
		Fx.float_text(get_parent(), global_position + Vector2(0, -90), "Need more honk!", UITheme.YELLOW)
		AudioService.play("deny", -6.0)
		return
	if runner.try_activate(rec):
		GameState.discover_recipe(rec)


## Eat / talk button.
func try_interact() -> void:
	if interact_target != null and is_instance_valid(interact_target) and interact_target.has_method("interact"):
		interact_target.call("interact", self)


## Called by a snack bowl. Returns true when the food went into a pocket.
func eat(food: StringName) -> bool:
	if not FoodDB.has_food(food):
		return false
	var def := FoodDB.food(food)
	var had := inventory.has(food)
	var slot := inventory.add(food)
	if slot == FoodInventory.NONE:
		_pending_food = food
		replace_needed.emit(food)
		return false
	_eat_feedback(def, not had)
	return true


## Answer from the replace prompt (slot 0/1), or -1 to keep both pockets.
func resolve_replace(slot: int) -> void:
	var food := _pending_food
	_pending_food = &""
	if food == &"" or slot < 0:
		return
	if inventory.replace(slot, food):
		_eat_feedback(FoodDB.food(food), true)


func _eat_feedback(def: FoodDefinition, fresh: bool) -> void:
	_pose = "eat"
	_pose_timer = 0.42
	control_lock = maxf(control_lock, 0.3)
	velocity.x = 0.0
	visual.squash(Vector2(1.15, 0.86))
	AudioService.play("eat")
	Fx.burst(get_parent(), global_position + Vector2(facing * 22.0, -34.0), "crumbs", def.color, 6, {"spread": 26.0, "life": 0.5, "size": 8.0})
	if fresh:
		Fx.float_text(get_parent(), global_position + Vector2(0, -96), def.ability_name + "!", def.color.lightened(0.35))
	if GameState.unlock_food(def.id):
		GameState.toast.emit("New snack: %s" % def.display_name, FoodDB.icon(def.icon_path))
	ate.emit(def.id)


# -------------------------------------------------------------------- hurt --

## Environmental "ouch": knocked back, one Comfort Feather lost (unless Cozy).
func hurt(from: Vector2, knock: float = 1.0) -> void:
	if invuln > 0.0 or state == State.DISABLED:
		return
	if runner.current != null and runner.current.blocks_hurt():
		return
	runner.cancel()
	sliding = false
	invuln = INVULN_TIME
	control_lock = 0.38
	_pose = "hurt"
	_pose_timer = 0.38
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


## Moves Tato somewhere safe (after a fall or a snack-break respawn).
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
		if best != null and Settings.flag("auto_eat") and best.is_in_group("food_bowl") and not inventory.is_full():
			try_interact()


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
