extends AbilityStrategy
## Noodle Neck: a stretchy noodle whips out of Tato's beak (straight ahead,
## or upward while holding up) to flip far levers, grab treats and poke
## through gaps too small for a goose. Tato stands still while stretching.

const REACH := 290.0
const OUT_TIME := 0.2

var _rope: NoodleRope
var _dir := Vector2.RIGHT
var _length := 0.0
var _max := REACH
var _pulse: EffectPulse


func can_start() -> bool:
	return not player.in_water


func start() -> void:
	_dir = Vector2(player.facing, 0.0)
	if player.move_y < -0.5:
		_dir = Vector2(player.facing * 0.001, -1.0).normalized() if player.move_x == 0.0 else Vector2(player.facing, -1.0).normalized()
	player.control_lock = maxf(player.control_lock, 0.5)
	player.velocity.x = 0.0
	player.honk_pose(0.5)
	AudioService.voice("honk_noodle")
	AudioService.play("stretch")
	var origin := _origin()
	# walls stop the noodle; small openings do not
	var space := player.get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(origin, origin + _dir * REACH, Layers.WORLD)
	q.exclude = [player.get_rid()]
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		_max = maxf(origin.distance_to(hit["position"]) - 6.0, 20.0)
	_rope = NoodleRope.new()
	_rope.z_index = 6
	world().add_child(_rope)
	_pulse = pulse(origin, PackedStringArray(["reach"]), 26.0, {"life": float(def.get("duration")), "style": "none"})
	player.honked.emit(&"NOODLE")


func _origin() -> Vector2:
	return player.global_position + Vector2(player.facing * 22.0, -52.0)


func tick(_delta: float) -> void:
	var total := float(def.get("duration"))
	var t := elapsed
	if t < OUT_TIME:
		_length = _max * (t / OUT_TIME)
	elif t < total - OUT_TIME:
		_length = _max
	else:
		_length = _max * clampf((total - t) / OUT_TIME, 0.0, 1.0)
	var origin := _origin()
	var tip := origin + _dir * _length
	if _rope != null and is_instance_valid(_rope):
		_rope.set_points(origin, tip, elapsed)
	if _pulse != null and is_instance_valid(_pulse):
		_pulse.global_position = tip
		_pulse.info["position"] = tip


func stop() -> void:
	if _rope != null and is_instance_valid(_rope):
		_rope.queue_free()
	if _pulse != null and is_instance_valid(_pulse):
		_pulse.queue_free()


func anim() -> String:
	return "stretch"
