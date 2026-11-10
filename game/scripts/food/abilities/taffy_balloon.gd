extends AbilityStrategy
## Taffy Balloon (Bubbleberry + Honeycomb): a stretchy taffy line shoots to
## the nearest hanging platform and tugs it over for a while.

const RANGE := 460.0
var _target: Node2D


func can_start() -> bool:
	_target = null
	var best := RANGE
	var from := player.global_position + Vector2(0, -40)
	for n in player.get_tree().get_nodes_in_group("taffy_target"):
		var node := n as Node2D
		if node == null:
			continue
		var at: Vector2 = node.call("center") if node.has_method("center") else node.global_position
		var d := from.distance_to(at)
		if d < best:
			best = d
			_target = node
	if _target == null:
		Fx.float_text(player.get_parent(), player.global_position + Vector2(0, -90), "Nothing to tug here", UITheme.CREAM)
		AudioService.play("deny", -6.0)
		return false
	return true


func start() -> void:
	var p := player
	p.honk_pose(0.4)
	AudioService.voice("honk_bubble")
	AudioService.play("stretch")
	var from := p.global_position + Vector2(p.facing * 20.0, -50.0)
	var to: Vector2 = _target.call("center") if _target.has_method("center") else _target.global_position
	var rope := NoodleRope.new()
	rope.fill = Color("ff9ec4")
	rope.slack = 18.0
	rope.z_index = 6
	world().add_child(rope)
	rope.set_points(from, to, 0.0)
	var t := rope.create_tween()
	t.tween_interval(0.45)
	t.tween_property(rope, "modulate:a", 0.0, 0.2)
	t.tween_callback(rope.queue_free)
	_target.call("on_effect", &"pull", {"source": p, "hold": float(def.get("duration")), "position": from})
	p.honked.emit(&"TAFFY_BALLOON")


func anim() -> String:
	return "honk"
