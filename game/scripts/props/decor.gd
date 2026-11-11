extends Prop
## Scenery with no rules. `decor 2` shows the world's third prop drawing
## (fence, flower, rock, barrel, lollipop, snowman, hay, throne ...);
## `decor card=world_candy` hangs one of the picture cards.

var _time := 0.0
var _art: Sprite2D
var _base_y := 0.0

func _configure() -> void:
	var s: Sprite2D
	if p_str("card") != "":
		s = Art.sized("cards/" + p_str("card"), p_float("size", 150.0))
	else:
		var index := int(arg(0, "0")) if arg(0, "0").is_valid_int() else cell.x
		s = Art.sized(WorldKit.decor(level.theme, index), p_float("size", 58.0))
	add_child(s)
	_art = s
	_base_y = s.position.y
	z_index = -1 if not p_flag("front") else 4
	if p_flag("flip"):
		s.flip_h = true


func _process(delta: float) -> void:
	if _art == null or Settings.flag("reduced_motion"):
		return
	# Most props stay still for level clarity; selected lightweight decorations sway.
	if p_str("card") != "":
		return
	var index := int(arg(0, "0")) if arg(0, "0").is_valid_int() else cell.x
	if absi(index) % 3 == 0:
		_time += delta
		_art.rotation = sin(_time * 1.1 + float(cell.x)) * 0.022
		_art.position.y = _base_y + sin(_time * 1.3 + float(cell.x)) * 1.2
