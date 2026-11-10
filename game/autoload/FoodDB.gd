extends Node
## The twelve attack power-ups and the "Flavor Bursts" that happen when one
## power replaces a different one. A burst is looked up by a canonical
## (sorted) pair key, so A-then-B and B-then-A are the same burst.

const FOOD_IDS: Array[StringName] = [
	&"FIRE_PEPPER", &"BUBBLEBERRY", &"WATERMELON", &"HONEYCOMB", &"POPCORN", &"NOODLE",
	&"FROSTBERRY", &"COCOA_SHIELD", &"GARLIC_DASH", &"THUNDER_CORN", &"LEMON_BEAM", &"TOMATO_BOMB",
]

var foods: Dictionary = {}            # StringName -> FoodDefinition
var recipe_by_pair: Dictionary = {}   # "A|B" -> RecipeDefinition
var _icon_cache: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	foods.clear()
	recipe_by_pair.clear()
	for id in FOOD_IDS:
		var path := "res://data/foods/%s.tres" % String(id).to_lower()
		var def := load(path) as FoodDefinition
		if def == null:
			push_error("Missing power-up definition: " + path)
			continue
		foods[def.id] = def


func food(id: StringName) -> FoodDefinition:
	return foods.get(id) as FoodDefinition


func has_food(id: StringName) -> bool:
	return foods.has(id)


func canonical_pair(a: StringName, b: StringName) -> String:
	return RecipeDefinition.canonical_pair(a, b)


## The Flavor Burst for two different powers (null for unknown or equal ids).
func resolve(a: StringName, b: StringName) -> RecipeDefinition:
	if a == b or not foods.has(a) or not foods.has(b):
		return null
	var key := canonical_pair(a, b)
	if recipe_by_pair.has(key):
		return recipe_by_pair[key]
	var rec := _make_burst(a, b)
	recipe_by_pair[key] = rec
	return rec


func resolve_key(key: String) -> RecipeDefinition:
	var parts := key.split("|")
	if parts.size() != 2:
		return null
	return resolve(StringName(parts[0]), StringName(parts[1]))


func burst_total() -> int:
	var n := FOOD_IDS.size()
	return n * (n - 1) / 2


func all_foods() -> Array[FoodDefinition]:
	var out: Array[FoodDefinition] = []
	for id in FOOD_IDS:
		if foods.has(id):
			out.append(foods[id])
	return out


func foods_for_world(world_index: int) -> Array[FoodDefinition]:
	var out: Array[FoodDefinition] = []
	for def in all_foods():
		if def.unlock_world <= world_index:
			out.append(def)
	return out


func icon(path: String) -> Texture2D:
	if path == "":
		return null
	if _icon_cache.has(path):
		return _icon_cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_icon_cache[path] = tex
	return tex


func food_icon(id: StringName) -> Texture2D:
	var def := food(id)
	return icon(def.icon_path) if def else null


func _make_burst(a: StringName, b: StringName) -> RecipeDefinition:
	var names: Array[String] = [String(a), String(b)]
	names.sort()
	var fa := food(StringName(names[0]))
	var fb := food(StringName(names[1]))
	var rec := RecipeDefinition.new()
	rec.id = StringName("BURST_%s_%s" % [names[0], names[1]])
	rec.food_a = fa.id
	rec.food_b = fb.id
	rec.display_name = "%s %s" % [fa.blend_adjective, fb.blend_noun]
	rec.description = "%s meets %s: a burst of both flavours that bops every creature nearby." % [fa.display_name, fb.display_name]
	rec.color = fa.color.lerp(fb.color, 0.5)
	rec.accent = fb.accent
	rec.named = false
	return rec
