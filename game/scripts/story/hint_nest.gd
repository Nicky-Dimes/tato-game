class_name HintNest
extends RefCounted
## Hints, only when asked for (pause menu). A stage can set
## `hints = first | second | third` in its [meta].

static func hints_for(level: Level) -> Array:
	if level == null:
		return []
	return split(level.data.meta_str("hints"))


static func split(raw: String) -> Array:
	var out: Array = []
	for part in raw.split("|", false):
		var s := part.strip_edges()
		if s != "":
			out.append(s)
	return out
