extends Prop
## Scenery with no rules. `decor 2` shows the world's third prop drawing
## (fence, flower, rock, barrel, lollipop, snowman, hay, throne ...);
## `decor card=world_candy` hangs one of the picture cards.

func _configure() -> void:
	var s: Sprite2D
	if p_str("card") != "":
		s = Art.sized("cards/" + p_str("card"), p_float("size", 150.0))
	else:
		var index := int(arg(0, "0")) if arg(0, "0").is_valid_int() else cell.x
		s = Art.sized(WorldKit.decor(level.theme, index), p_float("size", 58.0))
	add_child(s)
	z_index = -1 if not p_flag("front") else 4
	if p_flag("flip"):
		s.flip_h = true
