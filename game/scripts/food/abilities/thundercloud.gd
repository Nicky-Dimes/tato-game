extends AbilityStrategy
## Thundercloud (Thunder Truffle + Cloud Puff Pastry): a rumbling cloud
## appears under Tato and drifts the way he faced. Ride it! Every so often
## it booms, waking giant bells and resonance plates along the way.
## Up / down steer it gently while Tato is standing on it.

const SPEED := 115.0
var _cloud: CloudStep
var _boom := 0.9
var _dir := 1.0


func kind() -> String:
	return KIND_TOGGLE


func start() -> void:
	var p := player
	_dir = p.facing
	_cloud = CloudStep.new()
	_cloud.life = 99.0
	_cloud.width = 150.0
	world().add_child(_cloud)
	_cloud.global_position = p.global_position + Vector2(0, 12)
	_cloud.modulate = Color(0.82, 0.78, 1.0)
	p.velocity.y = minf(p.velocity.y, 0.0)
	AudioService.voice("honk_boom")
	AudioService.play("puff")
	p.honked.emit(&"THUNDERCLOUD")


func tick(delta: float) -> void:
	if _cloud == null or not is_instance_valid(_cloud):
		finish()
		return
	var p := player
	var riding := p.is_on_floor() and absf(p.global_position.x - _cloud.global_position.x) < 90.0 and absf(p.global_position.y - _cloud.global_position.y) < 30.0
	var vy := 0.0
	if riding:
		vy = p.move_y * 80.0
	# stop at walls instead of pushing through them
	var space := p.get_world_2d().direct_space_state
	var from := _cloud.global_position + Vector2(0, 8)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(_dir * 90.0, 0), Layers.WORLD)
	var vx := SPEED * _dir
	if not space.intersect_ray(q).is_empty():
		vx = 0.0
	_cloud.drift = Vector2(vx, vy)
	_boom -= delta
	if _boom <= 0.0:
		_boom = 1.4
		AudioService.play("boom", -4.0)
		pulse(_cloud.global_position, PackedStringArray(["resonance"]), 240.0, {
			"life": 0.45, "style": "ring", "color": Color(0.75, 0.6, 1.0, 0.9), "info": {"big": true},
		})
		if p.level != null:
			p.level.shake(3.0)
		Captions.caption("Rumble... BOOM")


func stop() -> void:
	if _cloud != null and is_instance_valid(_cloud):
		_cloud.fade()
