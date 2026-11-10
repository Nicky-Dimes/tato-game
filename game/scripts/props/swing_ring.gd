extends Prop
## A swing ring for the Tether Noodle. Hangs from whatever is above it.

func _configure() -> void:
	position = LevelData.cell_center(cell)
	add_child(Art.centered("props/swing_ring"))
	add_to_group("swing_ring")
	add_sense(Vector2(50, 50))


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"swing":
		Fx.pop_ring(level, global_position, Color(1, 0.9, 0.5), 40.0)
		return true
	return false
