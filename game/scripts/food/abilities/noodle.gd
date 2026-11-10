extends AbilityStrategy
## Noodle Whip: a long noodle snaps out and back, hitting everything along it
## and scooping up coins it touches.

const REACH := 200.0
var _rope: NoodleRope
var _hit_done := false


func kind() -> String:
	return KIND_TOGGLE


func start() -> void:
	_rope = NoodleRope.new()
	_rope.z_index = 6
	world().add_child(_rope)
	AudioService.voice("honk_noodle")
	AudioService.play_varied("whip", -3.0)
	player.honked.emit(&"NOODLE")


func tick(_delta: float) -> void:
	var total := float(def.get("duration"))
	var t := clampf(elapsed / total, 0.0, 1.0)
	var out := sin(t * PI)
	var from := player.muzzle()
	var dir := Vector2(player.facing, -0.12).normalized()
	if _rope != null and is_instance_valid(_rope):
		_rope.set_points(from, from + dir * REACH * out, elapsed)
	if not _hit_done and t >= 0.35:
		_hit_done = true
		var end := Hit.line(player.get_parent() as Node2D, from, dir, REACH, damage(), element(), player, 34.0)
		Fx.burst(world(), end, "sparkle", color(), 4, {"spread": 20.0, "life": 0.3, "size": 6.0})
		for coin in player.get_tree().get_nodes_in_group("grabbable"):
			var c := coin as Node2D
			var rel := c.global_position - from
			var along := rel.dot(dir)
			if along > 0.0 and along < REACH + 20.0 and absf(rel.dot(dir.orthogonal())) < 42.0 and c.has_method("grab"):
				c.call("grab", player)


func stop() -> void:
	if _rope != null and is_instance_valid(_rope):
		_rope.queue_free()
