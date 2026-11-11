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
	var override_path := BASE + "override/" + short.replace("/", "_") + ".png"
	if ResourceLoader.exists(override_path):
		found = load(override_path) as Texture2D
		if found != null:
			found.set_meta("anchor", Vector2(found.get_width() * 0.5, found.get_height()))
			found.set_meta("body_height", float(found.get_height()))
			_cache[short] = found
			return found
	var play_names := {"items/spring_pad": "spring", "items/checkpoint": "checkpoint", "items/question_block": "question", "items/crate": "crate"}
	if short.begins_with("play/") or play_names.has(short):
		found = PlayArt.prop(short.get_file() if short.begins_with("play/") else str(play_names[short]))
		_cache[short] = found
		return found
	if short.begins_with("enemies/") and short.count("/") == 1:
		found = ProductionArt.enemy_frame(short.get_file(), 0)
		if found != null:
			_cache[short] = found
			return found
	if short.begins_with("bosses/") and short.count("/") == 1:
		found = ProductionArt.boss_frame(short.get_file(), 0)
		if found != null:
			_cache[short] = found
			return found
	for path: String in [BASE + "override/" + short.replace("/", "_") + ".png", BASE + short + ".png", BASE + short + ".svg"]:
		if ResourceLoader.exists(path):
			found = load(path) as Texture2D
			if found != null:
				break
	_cache[short] = found
	return found


static func has(short: String) -> bool:
	return tex(short) != null


## A standing sprite scaled so it is `height` pixels tall on screen.
static func sized(short: String, height: float) -> Sprite2D:
	var s := standing(short, 1.0)
	if s.texture != null:
		var k := height / float(s.texture.get_height())
		s.scale = Vector2(k, k)
	return s


## A centred sprite scaled so its larger side is `size` pixels on screen.
static func icon(short: String, size: float) -> Sprite2D:
	var s := centered(short, 1.0)
	if s.texture != null:
		var k := size / float(maxi(s.texture.get_width(), s.texture.get_height()))
		s.scale = Vector2(k, k)
	return s


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
