class_name Prop
extends Node2D
## Base for things placed in a stage from the level file. Gives every prop
## its level, its cell and its settings, plus helpers for the two kinds of
## sensing most props need: "something flavourful touched me" (on_effect) and
## "Tato walked into me".

var level: Level
var params: Dictionary = {}
var args: Array = []
var cell := Vector2i.ZERO


func setup(lv: Level, e: Dictionary) -> void:
	level = lv
	params = e.get("params", {})
	args = e.get("args", [])
	cell = e.get("cell", Vector2i.ZERO)
	position = LevelData.cell_floor(cell)
	_configure()


## Override: read params, build children.
func _configure() -> void:
	pass


func p_str(key: String, default_value: String = "") -> String:
	return str(params.get(key, default_value))


func p_int(key: String, default_value: int = 0) -> int:
	return int(params.get(key, default_value))


func p_float(key: String, default_value: float = 0.0) -> float:
	return float(params.get(key, default_value))


func p_flag(key: String) -> bool:
	return bool(params.get(key, false))


func arg(index: int, default_value: String = "") -> String:
	return str(args[index]) if index < args.size() else default_value


## Area that EffectPulses (honks, heat, cold ...) can find. The prop itself
## implements on_effect(tag, info).
func add_sense(size: Vector2, offset: Vector2 = Vector2.ZERO) -> Area2D:
	var a := Area2D.new()
	a.name = "Sense"
	a.collision_layer = Layers.INTERACT
	a.collision_mask = 0
	a.monitoring = false
	a.monitorable = true
	var shape := RectangleShape2D.new()
	shape.size = size
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = offset
	a.add_child(cs)
	add_child(a)
	return a


## Area that notices Tato. Connect body_entered / body_exited.
func add_touch(size: Vector2, offset: Vector2 = Vector2.ZERO, mask: int = Layers.PLAYER) -> Area2D:
	var a := Area2D.new()
	a.name = "Touch"
	a.collision_layer = 0
	a.collision_mask = mask
	a.monitoring = true
	a.monitorable = false
	var shape := RectangleShape2D.new()
	shape.size = size
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = offset
	a.add_child(cs)
	add_child(a)
	return a


func add_solid(size: Vector2, offset: Vector2 = Vector2.ZERO, layer: int = Layers.WORLD) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = "Solid"
	b.collision_layer = layer
	b.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = size
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = offset
	b.add_child(cs)
	add_child(b)
	return b


func is_player(body: Node) -> bool:
	return body is Tato


## Gentle looping bob for floating pickups (skipped with Reduced Motion).
func bob(node: Node2D, amount: float = 5.0, seconds: float = 1.6) -> void:
	if Settings.flag("reduced_motion"):
		return
	var base_y := node.position.y
	var t := node.create_tween().set_loops()
	t.tween_property(node, "position:y", base_y - amount, seconds * 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_property(node, "position:y", base_y + amount, seconds * 0.5).set_trans(Tween.TRANS_SINE)
