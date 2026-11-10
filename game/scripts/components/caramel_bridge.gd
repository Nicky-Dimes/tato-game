class_name CaramelBridge
extends StaticBody2D
## The crunchy bridge a Caramel Coat bakes. Grows out from Tato's feet,
## holds for a few seconds, blinks, then crumbles.

var length := 256.0
var dir := 1.0
var life := 8.0
var _grown := 0.0
var _cs: CollisionShape2D
var _shape: RectangleShape2D
var _gone := false


func setup(len: float, direction: float, seconds: float) -> void:
	length = len
	dir = direction
	life = seconds


func _ready() -> void:
	collision_layer = Layers.WORLD | Layers.INTERACT
	collision_mask = 0
	add_to_group("temporary")
	add_to_group("safe_ground")
	z_index = 1
	_shape = RectangleShape2D.new()
	_shape.size = Vector2(8.0, 18.0)
	_cs = CollisionShape2D.new()
	_cs.shape = _shape
	add_child(_cs)


func _physics_process(delta: float) -> void:
	if _gone:
		return
	if _grown < length:
		_grown = minf(_grown + 900.0 * delta, length)
		_shape.size = Vector2(maxf(_grown, 8.0), 18.0)
		_cs.position = Vector2(dir * _grown * 0.5, 9.0)
		queue_redraw()
	life -= delta
	if life < 1.5:
		modulate.a = 0.55 + 0.45 * absf(sin(life * 10.0))
	if life <= 0.0:
		crumble()


func crumble() -> void:
	if _gone:
		return
	_gone = true
	collision_layer = 0
	AudioService.play("crate_break", -8.0)
	for i in int(length / 64.0) + 1:
		Fx.burst(get_parent(), global_position + Vector2(dir * (i * 64.0 + 20.0), 8.0), "crumbs", Color("c8742a"), 3, {"spread": 26.0, "life": 0.5, "size": 9.0})
	queue_free()


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"cold":
		life += 3.0
		return true
	return false


func _draw() -> void:
	var x0 := 0.0 if dir > 0.0 else -_grown
	var rect := Rect2(x0, 0.0, _grown, 18.0)
	draw_rect(rect, Color("c8742a"))
	draw_rect(Rect2(x0, 0.0, _grown, 6.0), Color("ffd27a"))
	draw_rect(Rect2(x0, 14.0, _grown, 4.0), Color("9c5519"))
	var n := int(_grown / 40.0)
	for i in n:
		draw_circle(Vector2(x0 + 20.0 + i * 40.0, 10.0), 3.0, Color("ffe9b0"))
	draw_rect(rect, Color("3a1f4d"), false, 3.0)
