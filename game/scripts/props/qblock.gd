extends Prop
## Question Block. Bump it from below (or hit it with any attack) and what
## is inside pops out: `holds=coins:5` (default coins:3), `holds=heart`,
## `holds=key`, `holds=pickup:wings`, `holds=power:FROSTBERRY`.
## Then it is an ordinary block to stand on.

var used := false
var _sprite: Sprite2D
var _bump: Area2D
var _base := Vector2.ONE


func _configure() -> void:
	position = LevelData.cell_floor(cell)
	_sprite = Art.sized("items/question_block", 64.0)
	_base = _sprite.scale
	add_child(_sprite)
	add_solid(Vector2(62, 62), Vector2(0, -32), Layers.WORLD | Layers.INTERACT)
	_bump = add_touch(Vector2(44, 12), Vector2(0, 6))
	add_to_group("hittable")


func _physics_process(_delta: float) -> void:
	if used:
		return
	for body in _bump.get_overlapping_bodies():
		if body is Tato and (body as Tato).velocity.y < -40.0:
			(body as Tato).velocity.y = 60.0
			open()


func take_hit(_damage: int, _info: Dictionary) -> bool:
	if used:
		return false
	open()
	return true


func open() -> void:
	if used:
		return
	used = true
	remove_from_group("hittable")
	_sprite.modulate = Color(0.72, 0.62, 0.55)
	AudioService.play("block")
	level.spill(p_str("holds", "coins:3"), global_position + Vector2(0, -78))
	if not Settings.flag("reduced_motion"):
		var t := create_tween()
		t.tween_property(_sprite, "position:y", -14.0, 0.06)
		t.tween_property(_sprite, "position:y", 0.0, 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
