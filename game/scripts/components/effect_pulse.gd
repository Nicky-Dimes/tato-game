class_name EffectPulse
extends Area2D
## A burst of "flavour" in the world: a honk ring, a cone of warmth, a flash
## of light... Anything it touches that has an on_effect(tag, info) method
## (on itself or a parent) reacts. Stages never look at the player directly:
## they only hear about pulses, so every puzzle piece works with any power
## that sends the right tag.

var tags: PackedStringArray = PackedStringArray()
var radius := 160.0
var life := 0.3
var cone_dir := Vector2.ZERO      # zero = full circle
var cone_half_angle := 0.6        # radians
var info: Dictionary = {}
var color := Color(1, 1, 1, 0.9)
var style := "ring"               # ring | cone | flash | none
var grow_from := 0.25             # ring starts at this fraction of the radius
var follow: Node2D = null
var follow_offset := Vector2.ZERO

var _age := 0.0
var _hit: Dictionary = {}
var _shape: CircleShape2D


## Convenience constructor. opts: cone (Vector2), angle (radians), life, color,
## style, info (Dictionary merged into what receivers get), source, follow.
static func emit(parent: Node, at: Vector2, pulse_tags: PackedStringArray, pulse_radius: float, opts: Dictionary = {}) -> EffectPulse:
	var p := EffectPulse.new()
	p.tags = pulse_tags
	p.radius = pulse_radius
	p.life = float(opts.get("life", 0.3))
	p.cone_dir = opts.get("cone", Vector2.ZERO)
	p.cone_half_angle = float(opts.get("angle", 0.6))
	p.color = opts.get("color", Color(1, 1, 1, 0.9))
	p.style = str(opts.get("style", "ring"))
	p.follow = opts.get("follow", null)
	p.follow_offset = opts.get("follow_offset", Vector2.ZERO)
	p.info = (opts.get("info", {}) as Dictionary).duplicate()
	p.info["source"] = opts.get("source", null)
	p.info["position"] = at
	p.info["radius"] = pulse_radius
	p.info["tags"] = pulse_tags
	parent.add_child(p)
	p.global_position = at
	return p


func _ready() -> void:
	collision_layer = Layers.EFFECT
	collision_mask = Layers.INTERACT | Layers.ENEMY | Layers.PROP
	monitoring = true
	monitorable = false
	z_index = 20
	_shape = CircleShape2D.new()
	_shape.radius = radius
	var cs := CollisionShape2D.new()
	cs.shape = _shape
	add_child(cs)


func _physics_process(delta: float) -> void:
	_age += delta
	if follow and is_instance_valid(follow):
		global_position = follow.global_position + follow_offset
		info["position"] = global_position
	for area in get_overlapping_areas():
		_touch(area)
	for body in get_overlapping_bodies():
		_touch(body)
	queue_redraw()
	if _age >= life:
		queue_free()


func _touch(node: Node2D) -> void:
	var target := find_receiver(node)
	if target == null or _hit.has(target.get_instance_id()):
		return
	if cone_dir != Vector2.ZERO:
		var to: Vector2 = (target as Node2D).global_position - global_position if target is Node2D else node.global_position - global_position
		# things right on top of the honker always count
		if to.length() > 40.0 and absf(cone_dir.angle_to(to)) > cone_half_angle:
			return
	_hit[target.get_instance_id()] = true
	for tag in tags:
		target.call("on_effect", StringName(tag), info)


static func find_receiver(node: Node) -> Node:
	var n := node
	for i in 4:
		if n == null:
			return null
		if n.has_method("on_effect"):
			return n
		n = n.get_parent()
	return null


func _draw() -> void:
	if style == "none":
		return
	var t := clampf(_age / maxf(life, 0.01), 0.0, 1.0)
	var c := color
	c.a *= 1.0 - t * t
	match style:
		"ring":
			var r := radius * lerpf(grow_from, 1.0, 1.0 - pow(1.0 - t, 2.0))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, c, lerpf(9.0, 3.0, t), true)
			var c2 := c
			c2.a *= 0.5
			draw_arc(Vector2.ZERO, r * 0.72, 0.0, TAU, 32, c2, lerpf(5.0, 2.0, t), true)
		"cone":
			var a0 := cone_dir.angle()
			var r2 := radius * lerpf(0.35, 1.0, 1.0 - pow(1.0 - t, 2.0))
			for i in 3:
				var rr := r2 * (1.0 - i * 0.26)
				var cc := c
				cc.a *= 1.0 - i * 0.25
				draw_arc(Vector2.ZERO, rr, a0 - cone_half_angle, a0 + cone_half_angle, 14, cc, lerpf(14.0, 4.0, t), true)
		"flash":
			var cf := color
			cf.a *= (1.0 - t) * 0.45
			draw_circle(Vector2.ZERO, radius * lerpf(0.5, 1.0, t), cf)
			draw_arc(Vector2.ZERO, radius * lerpf(0.5, 1.0, t), 0.0, TAU, 40, c, 4.0, true)
