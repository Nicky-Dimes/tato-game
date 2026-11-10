extends Prop
## A stray Comfort Feather: gives one back.

func _configure() -> void:
	position = LevelData.cell_center(cell)
	var s := Art.centered("items/feather")
	add_child(s)
	bob(s, 5.0, 1.5)
	var touch := add_touch(Vector2(50, 50))
	touch.body_entered.connect(_on_touch)


func _on_touch(body: Node) -> void:
	if not is_player(body):
		return
	if GameState.add_feather():
		AudioService.play("feather")
		Fx.sparkle(level, global_position, Color(1, 1, 1), 6)
		queue_free()
