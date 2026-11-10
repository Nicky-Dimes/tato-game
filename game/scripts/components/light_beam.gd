class_name LightBeam
extends Node2D
## A ray of light from a Flash Zing (or a lamp). It travels until something
## solid stops it, bounces off mirrors and prisms, and tells whatever it
## lands on that it has been lit (`light`).

const MAX_BOUNCES := 8
const MAX_LENGTH := 1800.0
const LIFE := 0.5

var points := PackedVector2Array()
var _age := 0.0
var tint := Color(1.0, 0.95, 0.45)


static func fire(parent: Node, origin: Vector2, dir: Vector2, source: Node) -> LightBeam:
	var beam := LightBeam.new()
	beam.z_index = 18
	parent.add_child(beam)
	beam.trace(origin, dir.normalized(), source)
	return beam


func trace(origin: Vector2, dir: Vector2, source: Node) -> void:
	points.clear()
	points.append(origin)
	var space := get_world_2d().direct_space_state
	var pos := origin
	var d := dir
	var remaining := MAX_LENGTH
	var exclude: Array[RID] = []
	if source is CollisionObject2D:
		exclude.append((source as CollisionObject2D).get_rid())
	var bounces := 0
	var guard := 0
	while remaining > 4.0 and bounces <= MAX_BOUNCES and guard < 40:
		guard += 1
		var q := PhysicsRayQueryParameters2D.create(pos, pos + d * remaining, Layers.WORLD | Layers.INTERACT)
		q.collide_with_areas = true
		q.collide_with_bodies = true
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			points.append(pos + d * remaining)
			break
		var hit_pos: Vector2 = hit["position"]
		var collider := hit["collider"] as Node
		var receiver := EffectPulse.find_receiver(collider)
		if receiver != null and receiver.is_in_group("mirror") and receiver.has_method("reflect"):
			var centre: Vector2 = (receiver as Node2D).global_position + (receiver.call("beam_centre") as Vector2 if receiver.has_method("beam_centre") else Vector2.ZERO)
			var out: Vector2 = receiver.call("reflect", d)
			points.append(centre)
			receiver.call("on_effect", &"glint", {"source": source})
			if out == Vector2.ZERO:
				break
			remaining -= pos.distance_to(centre)
			pos = centre
			d = out
			bounces += 1
			exclude = [(collider as CollisionObject2D).get_rid()]
			continue
		if receiver != null:
			var took: bool = receiver.call("on_effect", &"light", {"source": source, "position": hit_pos, "radius": 20.0, "direction": d, "tags": PackedStringArray(["light"])})
			if took or collider is PhysicsBody2D:
				points.append(hit_pos)
				break
			# an unrelated sensing area: light passes straight through it
			exclude.append((collider as CollisionObject2D).get_rid())
			continue
		points.append(hit_pos)
		break
	AudioService.play("beam", -8.0)
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= LIFE:
		queue_free()


func _draw() -> void:
	if points.size() < 2:
		return
	var t := clampf(_age / LIFE, 0.0, 1.0)
	var local := PackedVector2Array()
	for p in points:
		local.append(to_local(p))
	var glow := tint
	glow.a = 0.35 * (1.0 - t)
	var core := Color(1, 1, 1, 0.95 * (1.0 - t * t))
	if Settings.flag("reduce_flashes"):
		glow.a *= 0.5
	draw_polyline(local, glow, 22.0, true)
	draw_polyline(local, tint * Color(1, 1, 1, 1.0 - t), 10.0, true)
	draw_polyline(local, core, 4.0, true)
	draw_circle(local[local.size() - 1], 12.0 * (1.0 - t), core)
