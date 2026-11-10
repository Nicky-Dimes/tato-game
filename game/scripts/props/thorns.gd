extends Prop
## Brambles: an "ouch" zone. Knocks Tato back and costs a Comfort Feather
## (never more than that). `flip` hangs them from the ceiling.

var _area: Area2D


func _configure() -> void:
	var s := Art.standing("props/thorns")
	add_child(s)
	var offset := Vector2(0, -16)
	if p_flag("flip"):
		position = Vector2((cell.x + 0.5) * Layers.TILE, cell.y * Layers.TILE)
		s.flip_v = true
		s.offset.y = 0.0
		offset = Vector2(0, 16)
	_area = add_touch(Vector2(50, 26), offset)
	add_to_group("hazard")


func _physics_process(_delta: float) -> void:
	for body in _area.get_overlapping_bodies():
		if body is Tato:
			(body as Tato).hurt(global_position)
