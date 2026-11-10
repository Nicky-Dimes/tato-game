class_name Art
extends RefCounted
## Loads the game's pictures by short name ("props/bowl") and remembers them.
## Art is authored at 2x, so sprites are shown at half scale.
## A production picture dropped in assets/sprites/override/<name>.png replaces
## the generated one without any code change (see docs/ART_PIPELINE.md).

const BASE := "res://assets/sprites/"
const ART_SCALE := 0.5

static var _cache: Dictionary = {}


static func tex(short: String) -> Texture2D:
	if _cache.has(short):
		return _cache[short]
	var found: Texture2D = null
	for path: String in [BASE + "override/" + short.replace("/", "_") + ".png", BASE + short + ".png", BASE + short + ".svg"]:
		if ResourceLoader.exists(path):
			found = load(path) as Texture2D
			if found != null:
				break
	_cache[short] = found
	return found


static func has(short: String) -> bool:
	return tex(short) != null


## A Sprite2D whose bottom-centre sits on the node origin (things on the ground).
static func standing(short: String, scale: float = ART_SCALE) -> Sprite2D:
	var s := Sprite2D.new()
	var t := tex(short)
	s.texture = t
	s.scale = Vector2(scale, scale)
	if t != null:
		s.centered = false
		s.offset = Vector2(-t.get_width() * 0.5, -t.get_height())
	return s


## A centred Sprite2D (floating things).
static func centered(short: String, scale: float = ART_SCALE) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex(short)
	s.scale = Vector2(scale, scale)
	return s
