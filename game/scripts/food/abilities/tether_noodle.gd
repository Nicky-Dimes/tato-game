extends AbilityStrategy
## Tether Noodle (Stretchy Noodles + Honeycomb): a sticky noodle grabs the
## nearest swing ring and Tato swings like a pendulum. Push left / right to
## pump the swing; jump lets go and flings him onward.

const RANGE := 360.0

var _ring: Node2D
var _rope: NoodleRope
var _length := 200.0
var _angle := 0.0        # from straight down, positive to the right
var _omega := 0.0


func kind() -> String:
	return KIND_TOGGLE


func can_start() -> bool:
	_ring = null
	var best := RANGE
	var from := player.global_position + Vector2(0, -40)
	for n in player.get_tree().get_nodes_in_group("swing_ring"):
		var node := n as Node2D
		if node == null:
			continue
		var d := from.distance_to(node.global_position)
		# rings ahead of Tato are preferred over rings behind
		if signf(node.global_position.x - from.x) == -player.facing:
			d += 120.0
		if d < best and node.global_position.y < from.y + 60.0:
			best = d
			_ring = node
	if _ring == null:
		Fx.float_text(player.get_parent(), player.global_position + Vector2(0, -90), "No swing ring in reach", UITheme.CREAM)
		AudioService.play("deny", -6.0)
		return false
	return true


func start() -> void:
	var p := player
	var hang := (p.global_position + Vector2(0, -40)) - _ring.global_position
	_length = clampf(hang.length(), 110.0, 300.0)
	_angle = atan2(hang.x, hang.y)
	# keep the speed Tato arrived with
	var tangent := Vector2(cos(_angle), -sin(_angle))
	_omega = p.velocity.dot(tangent) / _length
	_rope = NoodleRope.new()
	_rope.z_index = 6
	world().add_child(_rope)
	AudioService.voice("honk_noodle")
	AudioService.play("stretch")
	if _ring.has_method("on_effect"):
		_ring.call("on_effect", &"swing", {"source": p})
	p.honked.emit(&"TETHER_NOODLE")


func overrides_movement() -> bool:
	return true


func move(delta: float) -> void:
	var p := player
	if _ring == null or not is_instance_valid(_ring):
		finish()
		return
	_omega += (-Tato.GRAVITY / _length * sin(_angle)) * delta
	_omega += p.move_x * 2.6 * delta * cos(_angle)
	_omega *= 1.0 - 0.25 * delta
	_omega = clampf(_omega, -4.2, 4.2)
	_angle += _omega * delta
	_angle = clampf(_angle, -1.45, 1.45)
	var want := _ring.global_position + Vector2(sin(_angle), cos(_angle)) * _length + Vector2(0, 40)
	p.velocity = (want - p.global_position) / maxf(delta, 0.001)
	p.velocity = p.velocity.limit_length(1100.0)
	p.move_and_slide()
	if p.get_slide_collision_count() > 0:
		_omega *= -0.3
		var hang := (p.global_position + Vector2(0, -40)) - _ring.global_position
		_angle = atan2(hang.x, hang.y)
	if absf(_omega) > 0.3:
		p.facing = signf(_omega)
	p.in_water = false
	_rope.set_points(p.global_position + Vector2(p.facing * 14.0, -54.0), _ring.global_position, elapsed)
	if p.take_jump_press():
		finish()


func stop() -> void:
	if _rope != null and is_instance_valid(_rope):
		_rope.queue_free()
	var tangent := Vector2(cos(_angle), -sin(_angle))
	player.velocity = tangent * _omega * _length * 1.12 + Vector2(0, -150.0)
	player.flaps_left = Tato.MAX_FLAPS
	AudioService.play_varied("jump", -5.0)


func anim() -> String:
	return "fall"
