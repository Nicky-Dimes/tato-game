extends Prop
## A golden crumb: tops up Honk Charge.

const CHARGE := 9.0


func _configure() -> void:
	position = LevelData.cell_center(cell)
	var s := Art.centered("items/crumb")
	add_child(s)
	bob(s, 3.0, 1.2 + fmod(cell.x * 0.37, 0.6))
	var touch := add_touch(Vector2(44, 44))
	touch.body_entered.connect(_on_touch)


func _on_touch(body: Node) -> void:
	if not is_player(body):
		return
	GameState.add_charge(CHARGE)
	AudioService.play_varied("crumb", -6.0, 0.1)
	Fx.sparkle(level, global_position, Color(1, 0.85, 0.35), 3)
	queue_free()
