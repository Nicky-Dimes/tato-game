class_name HintNest
extends RefCounted
## Progressive hints, only when asked for: a gentle nudge, then which snack
## to think about, then exactly what to do. No penalty for using them.
## A stage sets `hints = nudge | clue | action` in its [meta]; a `hintzone`
## entity can give a different set for one room.

static func hints_for(level: Level) -> Array:
	if level == null:
		return []
	for zone in level.get_tree().get_nodes_in_group("hint_zone"):
		if zone.has_method("contains") and zone.call("contains", level.player.global_position):
			return zone.call("lines")
	var raw := level.data.meta_str("hints")
	return split(raw)


static func split(raw: String) -> Array:
	var out: Array = []
	for part in raw.split("|", false):
		var s := part.strip_edges()
		if s != "":
			out.append(s)
	return out
