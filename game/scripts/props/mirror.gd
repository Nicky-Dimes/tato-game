extends Prop
## A mirror set at a slant. Light beams turn a corner on it.
##   a=/  or  a=\     which way it leans (default /)
##   turn             a honk flips it to the other slant
##   id=<id>          a link flips it too

var slash := true     # true = "/"  false = "\"
var _sprite: Sprite2D
var _start := true


func _configure() -> void:
	position = LevelData.cell_center(cell)
	slash = p_str("a", "/") != "\\" and not p_flag("back")
	_start = slash
	_sprite = Art.centered("props/mirror")
	add_child(_sprite)
	var body := StaticBody2D.new()
	body.collision_layer = Layers.INTERACT
	body.collision_mask = 0
	var shape := CircleShape2D.new()
	shape.radius = 20.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	add_to_group("mirror")
	add_to_group("resettable")
	_show()


func reflect(d: Vector2) -> Vector2:
	if slash:
		return Vector2(-d.y, -d.x)
	return Vector2(d.y, d.x)


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"honk" and p_flag("turn"):
		flip()
		return true
	if tag == &"glint":
		Fx.sparkle(level, global_position, Color(1, 1, 0.8), 3)
		return true
	return false


func on_link(count: int) -> void:
	var want := _start if count < 1 else not _start
	if want != slash:
		flip()


func flip() -> void:
	slash = not slash
	_show()
	AudioService.play("lever", -4.0)
	Captions.caption("The mirror swivels")


func _show() -> void:
	var target := 0.0 if slash else PI * 0.5
	if is_inside_tree() and not Settings.flag("reduced_motion"):
		create_tween().tween_property(_sprite, "rotation", target, 0.15)
	else:
		_sprite.rotation = target


func reset_puzzle() -> void:
	if slash != _start:
		slash = _start
		_show()
