extends Prop
## Room-sized hint area: `hintzone w=12 h=8 text=<sign id>` where the sign
## text holds "nudge | clue | action".

var _rect := Rect2()
var _lines: Array = []


func _configure() -> void:
	var w := maxi(p_int("w", 8), 1)
	var h := maxi(p_int("h", 6), 1)
	_rect = Rect2(Vector2(cell.x, cell.y + 1 - h) * Layers.TILE, Vector2(w, h) * Layers.TILE)
	_lines = HintNest.split(Story.sign_text(p_str("text")))
	add_to_group("hint_zone")


func contains(point: Vector2) -> bool:
	return _rect.has_point(point)


func lines() -> Array:
	return _lines
