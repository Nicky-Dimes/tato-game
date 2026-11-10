class_name PrismBlock
extends StaticBody2D
## The icy prism from Prism Chill. Solid (a handy step) and it turns light
## beams: a sideways beam goes up; a beam coming down or up is sent the way
## Tato was facing when he made it.

var facing := 1.0
var life := 12.0
var _melting := false


func setup(direction: float, seconds: float) -> void:
	facing = direction
	life = seconds


func _ready() -> void:
	collision_layer = Layers.WORLD | Layers.INTERACT
	collision_mask = 0
	add_to_group("mirror")
	add_to_group("prism")
	add_to_group("temporary")
	add_to_group("ice")
	z_index = 1
	var shape := RectangleShape2D.new()
	shape.size = Vector2(56.0, 56.0)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -28.0)
	add_child(cs)
	var s := Art.standing("props/prism")
	add_child(s)
	scale = Vector2(0.2, 0.2)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func beam_centre() -> Vector2:
	return Vector2(0, -28.0)


func reflect(d: Vector2) -> Vector2:
	if absf(d.x) > absf(d.y):
		return Vector2.UP
	return Vector2(facing, 0.0)


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"heat":
		melt()
		return true
	if tag == &"glint":
		Fx.sparkle(get_parent(), global_position + Vector2(0, -28), Color(0.9, 1.0, 1.0), 4)
		return true
	return false


func _physics_process(delta: float) -> void:
	if _melting:
		return
	life -= delta
	if life < 2.0:
		modulate.a = 0.55 + 0.45 * absf(sin(life * 9.0))
	if life <= 0.0:
		melt()


func melt() -> void:
	if _melting:
		return
	_melting = true
	collision_layer = 0
	remove_from_group("prism")
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(queue_free)
