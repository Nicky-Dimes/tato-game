extends AbilityStrategy
## Lightning Shot: a bolt that leaps to the nearest creature in front of
## Tato, then jumps on to others nearby. With nobody in reach it flies ahead.

const REACH := 430.0
const CHAIN := 250.0
const JUMPS := 3


func start() -> void:
	AudioService.voice("honk_boom")
	AudioService.play_varied("zap", -2.0)
	player.honked.emit(&"THUNDER_CORN")
	var from := player.muzzle()
	var hit: Array[Node2D] = []
	var at := from
	var reach := REACH
	for i in JUMPS + 1:
		var best: Node2D = null
		var best_d := reach
		for e in player.get_tree().get_nodes_in_group("hittable"):
			var n := e as Node2D
			if n == null or hit.has(n) or not n.has_method("take_hit"):
				continue
			var aim := n.global_position + Vector2(0, -24)
			var d := at.distance_to(aim)
			if i == 0 and signf(aim.x - from.x) == -player.facing and absf(aim.x - from.x) > 30.0:
				continue
			if d < best_d:
				best_d = d
				best = n
		if best == null:
			break
		hit.append(best)
		var to := best.global_position + Vector2(0, -24)
		Bolt.draw_between(world(), at, to)
		best.call("take_hit", damage(), {"element": element(), "source": player, "position": at, "dir": (to - at).normalized(), "knock": 160.0})
		at = to
		reach = CHAIN
	if hit.is_empty():
		shoot(Vector2(900, 0), {"look": "bolt", "life": 0.5, "radius": 12.0, "pierce": 1})


class Bolt:
	extends Node2D

	var pts := PackedVector2Array()
	var _age := 0.0

	static func draw_between(parent: Node, a: Vector2, b: Vector2) -> void:
		var bolt := Bolt.new()
		bolt.z_index = 16
		parent.add_child(bolt)
		var n := 6
		var normal := (b - a).orthogonal().normalized()
		for i in n + 1:
			var t := float(i) / n
			var off := 0.0 if (i == 0 or i == n) else randf_range(-16.0, 16.0)
			bolt.pts.append(a.lerp(b, t) + normal * off)
		bolt.queue_redraw()

	func _process(delta: float) -> void:
		_age += delta
		modulate.a = 1.0 - _age / 0.22
		if _age >= 0.22:
			queue_free()

	func _draw() -> void:
		draw_polyline(pts, Color("7a4fcf"), 10.0, true)
		draw_polyline(pts, Color("ffe34d"), 5.0, true)
		draw_polyline(pts, Color(1, 1, 1), 2.0, true)
