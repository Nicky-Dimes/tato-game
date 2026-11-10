class_name Enemy
extends CharacterBody2D
## Base for the mischievous food-magic sprites and machines. Nobody gets
## hurt for real: creatures are startled, stunned, redirected or calmed, and
## bumping into one costs Tato a Comfort Feather at most.

var level: Level
var params: Dictionary = {}
var args: Array = []
var cell := Vector2i.ZERO
var home := Vector2.ZERO
var stun_left := 0.0
var facing := -1.0
var touch_hurts := true
var sprite: Sprite2D
var _touch: Area2D
var _body_shape: CollisionShape2D


func setup(lv: Level, e: Dictionary) -> void:
	level = lv
	params = e.get("params", {})
	args = e.get("args", [])
	cell = e.get("cell", Vector2i.ZERO)
	position = LevelData.cell_floor(cell)
	home = position
	collision_layer = Layers.ENEMY
	collision_mask = Layers.WORLD | Layers.ONEWAY
	add_to_group("enemy")
	add_to_group("resettable")
	z_index = 1
	_configure()


func _configure() -> void:
	pass


func p_float(key: String, default_value: float = 0.0) -> float:
	return float(params.get(key, default_value))


func p_str(key: String, default_value: String = "") -> String:
	return str(params.get(key, default_value))


func p_flag(key: String) -> bool:
	return bool(params.get(key, false))


func add_body(radius: float, height: float) -> void:
	var shape := CapsuleShape2D.new()
	shape.radius = radius
	shape.height = maxf(height, radius * 2.0)
	_body_shape = CollisionShape2D.new()
	_body_shape.shape = shape
	_body_shape.position = Vector2(0, -shape.height * 0.5)
	add_child(_body_shape)


func add_touch(size: Vector2, offset: Vector2) -> void:
	_touch = Area2D.new()
	_touch.collision_layer = 0
	_touch.collision_mask = Layers.PLAYER
	var shape := RectangleShape2D.new()
	shape.size = size
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = offset
	_touch.add_child(cs)
	add_child(_touch)


func add_art(short: String) -> void:
	sprite = Art.standing(short)
	add_child(sprite)


func is_stunned() -> bool:
	return stun_left > 0.0


func stun(seconds: float) -> void:
	stun_left = maxf(stun_left, seconds * Settings.timer_factor())
	if sprite:
		sprite.modulate = Color(0.8, 0.85, 1.0)
	Fx.burst(level, global_position + Vector2(0, -50), "sparkle", Color(1, 1, 0.6), 3, {"spread": 22.0, "life": 0.5, "size": 5.0})


func _physics_process(delta: float) -> void:
	if stun_left > 0.0:
		stun_left -= delta
		if stun_left <= 0.0 and sprite:
			sprite.modulate = Color.WHITE
	_behave(delta)
	if touch_hurts and _touch != null and not is_stunned():
		for body in _touch.get_overlapping_bodies():
			if body is Tato:
				_bump(body as Tato)
	if sprite:
		sprite.flip_h = facing > 0.0


func _behave(_delta: float) -> void:
	pass


func _bump(player: Tato) -> void:
	player.hurt(global_position)


## Is there ground to keep walking on in this direction?
func ground_ahead(dir: float, reach: float = 22.0) -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(dir * reach, -8)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 30), Layers.WORLD | Layers.ONEWAY)
	return not space.intersect_ray(q).is_empty()


func wall_ahead(dir: float, reach: float = 24.0) -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(0, -20)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(dir * reach, 0), Layers.WORLD)
	return not space.intersect_ray(q).is_empty()


func reset_puzzle() -> void:
	position = home
	velocity = Vector2.ZERO
	stun_left = 0.0
	if sprite:
		sprite.modulate = Color.WHITE
