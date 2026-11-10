extends Prop
## Scenery with no rules: `decor <picture>` shows assets/sprites/decor/<picture>.

func _configure() -> void:
	var s := Art.standing("decor/" + arg(0, "flower"))
	add_child(s)
	z_index = -1 if not p_flag("front") else 4
	if p_flag("flip"):
		s.flip_h = true
