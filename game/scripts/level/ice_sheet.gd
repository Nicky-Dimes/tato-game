class_name IceSheet
extends StaticBody2D
## A temporary slab of ice (frozen water surface, Frost Pop puddles ...).
## Slippery to walk on; melts on a timer or when heated.

var width := 128.0
var life := 10.0
var _max_life := 10.0
var _melting := false


func setup(w: float, seconds: float) -> void:
	width = w
	life = seconds
	_max_life = seconds


func _ready() -> void:
	collision_layer = Layers.WORLD | Layers.INTERACT
	collision_mask = 0
	add_to_group("ice")
	add_to_group("interactable")
	z_index = 6
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 20.0)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(width * 0.5, 10.0)
	add_child(cs)
	scale = Vector2(1.0, 0.2)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func refresh(seconds: float) -> void:
	life = maxf(life, seconds * Settings.timer_factor())
	_max_life = maxf(_max_life, life)
	modulate.a = 1.0


func _physics_process(delta: float) -> void:
	if _melting:
		return
	life -= delta
	if life < 2.0:
		# blink as a warning before it goes
		modulate.a = 0.55 + 0.45 * absf(sin(life * 9.0))
	if life <= 0.0:
		melt()


func melt() -> void:
	if _melting:
		return
	_melting = true
	collision_layer = 0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(queue_free)


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"heat":
		melt()
		return true
	if tag == &"cold":
		refresh(_max_life)
		return true
	return false


func _draw() -> void:
	var body := Rect2(0, 0, width, 20.0)
	draw_rect(body, Color("a9e4f5"))
	draw_rect(Rect2(0, 0, width, 6.0), Color("f1fdff"))
	draw_rect(Rect2(0, 16.0, width, 4.0), Color("79bfdc"))
	var n := int(width / 48.0)
	for i in n:
		var x := 14.0 + i * 48.0
		draw_line(Vector2(x, 15.0), Vector2(x + 9.0, 6.0), Color(1, 1, 1, 0.7), 3.0)
	draw_rect(body, Color("35507a"), false, 3.0)
