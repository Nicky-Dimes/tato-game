class_name CloudStep
extends AnimatableBody2D
## A small soft cloud to stand on (Feathercloud, Thundercloud). You can jump
## up through it. It melts when its time is up, faster inside a wind zone.

const MAX_ALIVE := 2

var life := 5.0
var width := 110.0
var counted := true
var drift := Vector2.ZERO
var _fading := false
var _sprite: Sprite2D

static var alive: Array[CloudStep] = []


static func spawn(parent: Node, at: Vector2, seconds: float) -> CloudStep:
	var c := CloudStep.new()
	c.life = seconds
	parent.add_child(c)
	c.global_position = at
	# only two little clouds at once: the oldest one goes
	alive = alive.filter(func(x: CloudStep) -> bool: return is_instance_valid(x) and not x._fading)
	while alive.size() >= MAX_ALIVE:
		var old: CloudStep = alive.pop_front()
		old.fade()
	alive.append(c)
	return c


func _ready() -> void:
	collision_layer = Layers.ONEWAY | Layers.INTERACT
	collision_mask = 0
	sync_to_physics = false
	add_to_group("temporary")
	add_to_group("cloud")
	z_index = 1
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 16.0)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, 8.0)
	cs.one_way_collision = true
	cs.one_way_collision_margin = 6.0
	add_child(cs)
	_sprite = Art.centered("fx/cloud")
	_sprite.position = Vector2(0, 14)
	_sprite.scale = Vector2(0.05, 0.05)
	add_child(_sprite)
	var t := create_tween()
	t.tween_property(_sprite, "scale", Vector2(0.5, 0.5) * (width / 110.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	if _fading:
		return
	if drift != Vector2.ZERO:
		position += drift * delta
	var drain := 1.0
	for w in get_tree().get_nodes_in_group("wind"):
		if w.has_method("contains") and w.call("contains", global_position):
			drain = 4.0
			break
	life -= delta * drain
	if life < 1.2:
		_sprite.modulate.a = 0.5 + 0.5 * absf(sin(life * 10.0))
	if life <= 0.0:
		fade()


func fade() -> void:
	if _fading:
		return
	_fading = true
	collision_layer = 0
	var t := create_tween()
	t.tween_property(_sprite, "modulate:a", 0.0, 0.25)
	t.parallel().tween_property(_sprite, "scale", _sprite.scale * 1.3, 0.25)
	t.tween_callback(queue_free)


func _exit_tree() -> void:
	alive.erase(self)
