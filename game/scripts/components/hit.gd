class_name Hit
extends RefCounted
## Delivering hits. Anything with `take_hit(damage: int, info: Dictionary) -> bool`
## (on itself or a parent) can be hit: creatures, bosses, crates, blocks.
## info: {element, source, position, dir, knock}. take_hit returns true when
## the hit landed (so a shot knows to stop).

const MASK := Layers.ENEMY | Layers.INTERACT | Layers.PROP


static func find_target(node: Node) -> Node:
	var n := node
	for i in 4:
		if n == null:
			return null
		if n.has_method("take_hit"):
			return n
		n = n.get_parent()
	return null


static func apply(node: Node, damage: int, element: StringName, source: Node, at: Vector2, dir: Vector2 = Vector2.ZERO, knock: float = 180.0) -> bool:
	var target := find_target(node)
	if target == null:
		return false
	return bool(target.call("take_hit", damage, {
		"element": element, "source": source, "position": at, "dir": dir, "knock": knock,
	}))


## Everything hittable inside a circle, each hit once. Returns how many landed.
static func burst(parent: Node, at: Vector2, radius: float, damage: int, element: StringName, source: Node, opts: Dictionary = {}) -> int:
	if parent == null or not parent.is_inside_tree():
		return 0
	var world := (parent as Node2D).get_world_2d() if parent is Node2D else null
	if world == null:
		return 0
	var shape := CircleShape2D.new()
	shape.radius = radius
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0.0, at)
	q.collision_mask = MASK
	q.collide_with_areas = true
	q.collide_with_bodies = true
	var seen := {}
	var landed := 0
	for hit: Dictionary in world.direct_space_state.intersect_shape(q, 32):
		var target := find_target(hit["collider"] as Node)
		if target == null or target == source or seen.has(target.get_instance_id()):
			continue
		seen[target.get_instance_id()] = true
		var tpos: Vector2 = (target as Node2D).global_position if target is Node2D else at
		var dir := (tpos - at).normalized()
		if target.call("take_hit", damage, {"element": element, "source": source, "position": at, "dir": dir, "knock": float(opts.get("knock", 200.0))}):
			landed += 1
	if not opts.get("silent", false):
		Fx.pop_ring(parent, at, opts.get("color", Color.WHITE), radius)
	return landed


## Everything hittable along a line (beam, whip). Stops at solid ground.
## Returns the point where the line ends.
static func line(parent: Node2D, from: Vector2, dir: Vector2, length: float, damage: int, element: StringName, source: Node, width: float = 18.0) -> Vector2:
	var space := parent.get_world_2d().direct_space_state
	var end := from + dir * length
	var wall := PhysicsRayQueryParameters2D.create(from, end, Layers.WORLD)
	if source is CollisionObject2D:
		wall.exclude = [(source as CollisionObject2D).get_rid()]
	var blocked := space.intersect_ray(wall)
	if not blocked.is_empty():
		end = blocked["position"]
		# the thing that stopped the line may itself be breakable
		apply(blocked["collider"] as Node, damage, element, source, end, dir)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(maxf(from.distance_to(end), 4.0), width)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(dir.angle(), (from + end) * 0.5)
	q.collision_mask = MASK
	q.collide_with_areas = true
	q.collide_with_bodies = true
	var seen := {}
	for hit: Dictionary in space.intersect_shape(q, 32):
		var target := find_target(hit["collider"] as Node)
		if target == null or target == source or seen.has(target.get_instance_id()):
			continue
		seen[target.get_instance_id()] = true
		target.call("take_hit", damage, {"element": element, "source": source, "position": from, "dir": dir, "knock": 200.0})
	return end
