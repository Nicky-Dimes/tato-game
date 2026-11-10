class_name Story
extends RefCounted
## All written words that are not menus: signpost tips, conversations,
## speaker names and Secret Dish names. Loaded from JSON in data/text/ so
## writers can edit (and translators can copy) without touching code.

const DIR := "res://data/text/"

static var _signs: Dictionary = {}
static var _dialogue: Dictionary = {}
static var _names: Dictionary = {}
static var _loaded := false


static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	_signs = _read("signs.json")
	_dialogue = _read("dialogue.json")
	_names = _read("names.json")


static func reload() -> void:
	_loaded = false
	_ensure()


static func _read(file: String) -> Dictionary:
	var path := DIR + file
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Could not read " + path)
		return {}
	return parsed


static func sign_text(id: String) -> String:
	_ensure()
	return str(_signs.get(id, id.replace("_", " ")))


static func has_sign(id: String) -> bool:
	_ensure()
	return _signs.has(id)


static func speaker_name(who: String) -> String:
	_ensure()
	var speakers: Dictionary = _names.get("speakers", {})
	return str(speakers.get(who, who.capitalize()))


static func dish_name(id: String) -> String:
	_ensure()
	var dishes: Dictionary = _names.get("dishes", {})
	return str(dishes.get(id, "Mystery Dish"))


static func has_dialogue(id: String) -> bool:
	_ensure()
	return _dialogue.has(id)


## Lines of one conversation: [{who, text, face?, honk?}, ...]
static func dialogue(id: String) -> Array:
	_ensure()
	var lines: Variant = _dialogue.get(id, [])
	return lines if typeof(lines) == TYPE_ARRAY else []


## Friends say new things as the story moves on. "mimi_hub" picks the newest
## of mimi_hub, mimi_hub@1, mimi_hub@2 ... that matches the Flavor Pages found.
static func pick_dialogue(base: String) -> String:
	_ensure()
	var pages := GameState.count("page")
	for n in range(pages, 0, -1):
		var key := "%s@%d" % [base, n]
		if _dialogue.has(key):
			return key
	return base if _dialogue.has(base) else ""


static func portrait(who: String, face: String = "happy") -> Texture2D:
	if who == "tato":
		var tex := TatoVisual.frame_texture("face_" + face)
		return tex if tex != null else TatoVisual.frame_texture("face_happy")
	var t := Art.tex("npcs/" + who)
	return t


static func all_dialogue_ids() -> Array:
	_ensure()
	return _dialogue.keys()


static func story_pages(id: String) -> Array:
	_ensure()
	var stories: Dictionary = _read("stories.json")
	var pages: Variant = stories.get(id, [])
	return pages if typeof(pages) == TYPE_ARRAY else []
