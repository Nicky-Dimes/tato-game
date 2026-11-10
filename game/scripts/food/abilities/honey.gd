extends AbilityStrategy
## Sticky Waddle: honey feet. Walk into a wall to climb it, jump into a
## ceiling to waddle along it upside down. Jump lets go. Water rinses the
## honey off. Ice is too slippery to stick to.

const CLIMB := 150.0
const NONE := 0
const WALL := 1
const CEIL := 2

var mode := NONE
var wall_dir := 1.0
var _drip := 0.0
var _regrab := 0.0


func kind() -> String:
	return KIND_TOGGLE


func start() -> void:
	player.sticky = true
	player.visual.tint = Color(1.0, 0.93, 0.7)
	AudioService.voice("honk_sticky")
	AudioService.play("squelch")
	player.honk_pose(0.25)
	player.honked.emit(&"HONEY")
	pulse(player.global_position + Vector2(0, -30), PackedStringArray(["sticky"]), 110.0, {"life": 0.25, "style": "ring"})


func overrides_movement() -> bool:
	return mode != NONE


func tick(delta: float) -> void:
	_regrab = maxf(_regrab - delta, 0.0)
	if player.in_water:
		Captions.caption("Water rinses the honey away")
		finish()
		return
	if mode != NONE or _regrab > 0.0:
		return
	# grab a wall by walking into it, or a ceiling by bumping it
	if player.is_on_wall() and player.move_x != 0.0 and signf(player.move_x) == -signf(player.get_wall_normal().x):
		if _surface_ok(Vector2(-player.get_wall_normal().x, 0.0)):
			_attach(WALL, -signf(player.get_wall_normal().x))
	elif player.is_on_ceiling() and _surface_ok(Vector2.UP):
		_attach(CEIL, player.facing)


func _attach(new_mode: int, dir: float) -> void:
	mode = new_mode
	wall_dir = dir
	player.velocity = Vector2.ZERO
	player.sliding = false
	AudioService.play_varied("squelch", -6.0)
	_pose()


func _pose() -> void:
	var v := player.visual
	if mode == WALL:
		player.facing = wall_dir
		v.extra_rotation = -PI * 0.5
		v.pose_offset = Vector2(Tato.BODY_RADIUS, -Tato.STAND_HEIGHT * 0.5)
	elif mode == CEIL:
		v.extra_rotation = PI
		v.pose_offset = Vector2(0, -Tato.STAND_HEIGHT)
	else:
		v.extra_rotation = 0.0
		v.pose_offset = Vector2.ZERO


func _detach(vel: Vector2) -> void:
	mode = NONE
	_regrab = 0.25
	player.velocity = vel
	player.flaps_left = Tato.MAX_FLAPS
	_pose()


## Is there solid, non-icy ground in this direction to stick to?
func _surface_ok(dir: Vector2, at_offset: Vector2 = Vector2.ZERO) -> bool:
	var space := player.get_world_2d().direct_space_state
	var from := player.global_position + Vector2(0, -Tato.STAND_HEIGHT * 0.5) + at_offset
	var q := PhysicsRayQueryParameters2D.create(from, from + dir * 44.0, Layers.WORLD)
	q.exclude = [player.get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return false
	var body := hit["collider"] as Node
	return body == null or not body.is_in_group("ice")


func move(delta: float) -> void:
	var p := player
	if mode == WALL:
		var climb := 0.0
		if p.move_y < -0.3 or (p.move_x != 0.0 and signf(p.move_x) == wall_dir):
			climb = -CLIMB
		elif p.move_y > 0.3:
			climb = CLIMB
		p.velocity = Vector2(wall_dir * 60.0, climb)
		p.move_and_slide()
		if p.take_jump_press():
			_detach(Vector2(-wall_dir * 250.0, Tato.JUMP_VELOCITY * 0.82))
			p.facing = -wall_dir
			AudioService.play_varied("jump", -4.0)
			return
		if p.is_on_ceiling() and climb < 0.0 and _surface_ok(Vector2.UP):
			mode = CEIL
			_pose()
			return
		if p.is_on_floor() and climb > 0.0:
			_detach(Vector2.ZERO)
			return
		if not _surface_ok(Vector2(wall_dir, 0.0), Vector2(0, 18.0)):
			if climb < 0.0:
				# top of the wall: hop up onto the ledge
				_detach(Vector2(wall_dir * 190.0, -360.0))
			else:
				_detach(Vector2.ZERO)
			return
	elif mode == CEIL:
		if p.move_x != 0.0:
			p.facing = signf(p.move_x)
		p.velocity = Vector2(p.move_x * CLIMB, -60.0)
		p.move_and_slide()
		if p.take_jump_press() or p.move_y > 0.6:
			_detach(Vector2(p.velocity.x, 40.0))
			return
		if not _surface_ok(Vector2.UP):
			_detach(Vector2(p.velocity.x, 0.0))
			return
	_drip -= delta
	if _drip <= 0.0 and p.velocity.length() > 20.0:
		_drip = 0.22
		Fx.burst(world(), p.global_position + p.visual.pose_offset * Vector2(p.facing, 1.0), "crumbs", Color(1.0, 0.75, 0.2, 0.9), 2, {"spread": 10.0, "life": 0.5, "size": 7.0})


func stop() -> void:
	mode = NONE
	player.sticky = false
	player.visual.tint = Color.WHITE
	_pose()


func anim() -> String:
	if mode == NONE:
		return ""
	return "climb" if player.velocity.length() > 20.0 else "look"
