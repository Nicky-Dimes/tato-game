extends Prop
## Recipe Scraps, Goose Pins and Secret Dishes. Saved the moment they are
## picked up. Ones already found show as a faint outline.

const ART := {"scrap": "items/scrap", "pin": "items/pin", "dish": "items/dish"}
const NAMES := {"scrap": "Recipe Scrap", "pin": "Goose Pin", "dish": "Secret Dish"}

var kind := "scrap"
var collect_id := ""
var _already := false


func _configure() -> void:
	kind = p_str("type", "scrap")
	collect_id = p_str("collect_id")
	position = LevelData.cell_center(cell)
	var s := Art.centered(ART.get(kind, "items/scrap"))
	add_child(s)
	bob(s, 5.0, 1.7)
	_already = GameState.has_collected(kind, collect_id)
	if _already:
		s.modulate = Color(1, 1, 1, 0.3)
	var touch := add_touch(Vector2(54, 54))
	touch.body_entered.connect(_on_touch)
	add_sense(Vector2(50, 50))


## A Noodle Neck can fetch it from far away.
func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"reach" and level.player != null:
		_on_touch(level.player)
		return true
	return false


func _on_touch(body: Node) -> void:
	if not is_player(body):
		return
	if not _already:
		AudioService.play("collect_%s" % kind)
		Fx.float_text(level, global_position + Vector2(0, -40), NAMES.get(kind, ""), UITheme.YELLOW)
	level.collect(kind, collect_id, global_position)
	queue_free()
