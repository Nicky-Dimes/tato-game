extends Node
## Loads every FoodDefinition / RecipeDefinition and resolves fusions.
## Fusions are looked up by a canonical (sorted) pair key, so A+B == B+A.

const FOOD_IDS: Array[StringName] = [
	&"PEPPER", &"BUBBLE", &"HONEY", &"MELON", &"FROST", &"POPCORN",
	&"NOODLE", &"CITRUS", &"MINT", &"JAM", &"TRUFFLE", &"PASTRY",
]

const RECIPE_IDS: Array[StringName] = [
	&"STEAM_LIFT", &"CARAMEL_COAT", &"TAFFY_BALLOON", &"STICKY_BOWLING",
	&"SNOWBALL_EXPRESS", &"FROST_POP", &"BUBBLE_POP_JET", &"TETHER_NOODLE",
	&"PRISM_CHILL", &"QUIET_INK", &"THUNDERCLOUD", &"SUNBEAM_STEPS",
]

const GENERIC_SCRIPT := "res://scripts/food/abilities/flavor_blend.gd"

var foods: Dictionary = {}            # StringName -> FoodDefinition
var recipes: Dictionary = {}          # StringName -> RecipeDefinition (named)
var recipe_by_pair: Dictionary = {}   # "A|B" -> RecipeDefinition (named + generated)
var _icon_cache: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	foods.clear()
	recipes.clear()
	recipe_by_pair.clear()
	for id in FOOD_IDS:
		var path := "res://data/foods/%s.tres" % String(id).to_lower()
		var def := load(path) as FoodDefinition
		if def == null:
			push_error("Missing food definition: " + path)
			continue
		foods[def.id] = def
	for id in RECIPE_IDS:
		var path := "res://data/recipes/%s.tres" % String(id).to_lower()
		var rec := load(path) as RecipeDefinition
		if rec == null:
			push_error("Missing recipe definition: " + path)
			continue
		# keep the pair canonical even if someone edits the file by hand
		var names: Array[String] = [String(rec.food_a), String(rec.food_b)]
		names.sort()
		rec.food_a = StringName(names[0])
		rec.food_b = StringName(names[1])
		recipes[rec.id] = rec
		recipe_by_pair[rec.pair_key()] = rec


func food(id: StringName) -> FoodDefinition:
	return foods.get(id) as FoodDefinition


func has_food(id: StringName) -> bool:
	return foods.has(id)


func recipe(id: StringName) -> RecipeDefinition:
	return recipes.get(id) as RecipeDefinition


func canonical_pair(a: StringName, b: StringName) -> String:
	return RecipeDefinition.canonical_pair(a, b)


## Every pair of two different known foods resolves to a recipe: one of the
## twelve signature recipes, or a generated "experiment" blend that mixes both
## flavours. Returns null only for an empty / unknown / identical pair.
func resolve(a: StringName, b: StringName) -> RecipeDefinition:
	if a == b or not foods.has(a) or not foods.has(b):
		return null
	var key := canonical_pair(a, b)
	if recipe_by_pair.has(key):
		return recipe_by_pair[key]
	var rec := _make_blend(a, b)
	recipe_by_pair[key] = rec
	return rec


func resolve_key(key: String) -> RecipeDefinition:
	var parts := key.split("|")
	if parts.size() != 2:
		return null
	return resolve(StringName(parts[0]), StringName(parts[1]))


func is_named_pair(a: StringName, b: StringName) -> bool:
	var rec := resolve(a, b)
	return rec != null and rec.named


func named_recipes() -> Array[RecipeDefinition]:
	var out: Array[RecipeDefinition] = []
	for id in RECIPE_IDS:
		if recipes.has(id):
			out.append(recipes[id])
	return out


func all_foods() -> Array[FoodDefinition]:
	var out: Array[FoodDefinition] = []
	for id in FOOD_IDS:
		if foods.has(id):
			out.append(foods[id])
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


func _make_blend(a: StringName, b: StringName) -> RecipeDefinition:
	var names: Array[String] = [String(a), String(b)]
	names.sort()
	var fa := food(StringName(names[0]))
	var fb := food(StringName(names[1]))
	var rec := RecipeDefinition.new()
	rec.id = StringName("BLEND_%s_%s" % [names[0], names[1]])
	rec.food_a = fa.id
	rec.food_b = fb.id
	rec.display_name = "%s %s" % [fa.blend_adjective, fb.blend_noun]
	rec.description = "A playful mix: both flavours burst out together, and both snacks last a little longer."
	rec.color = fa.color.lerp(fb.color, 0.5)
	rec.accent = fb.accent
	rec.ability_script = GENERIC_SCRIPT
	rec.charge_cost = 24.0
	rec.duration = 0.6
	rec.cooldown = 0.8
	var merged := PackedStringArray()
	for t in fa.tags:
		if not merged.has(t):
			merged.append(t)
	for t in fb.tags:
		if not merged.has(t):
			merged.append(t)
	rec.tags = merged
	rec.named = false
	return rec
