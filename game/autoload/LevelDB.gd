extends Node
## The campaign table: worlds, stages, unlock rules and level file loading.
## Stage order and names follow docs/CONTENT_MATRIX.csv.

const LEVEL_DIR := "res://data/levels/"
const HUB_ID := "HUB"
## Recipe Scraps needed to open the final door in the Silent Kitchen.
const FINALE_SCRAPS := 36
const FINALE_SCRAPS_COZY := 18

const SCRAPS_PER_WORLD := 12
const PINS_PER_WORLD := 6
const DISHES_PER_WORLD := 4

const WORLDS: Array[Dictionary] = [
	{
		"id": "W1", "index": 1, "name": "Picnic Patch", "theme": "picnic",
		"tagline": "A sunny orchard of picnic cloths, windmills and honey flowers.",
		"page": "Golden Crumb Page", "keeper": "Bun the Hedgehog", "music": "world1",
		"stages": ["W1-L1", "W1-L2", "W1-L3", "W1-X", "W1-B"],
	},
	{
		"id": "W2", "index": 2, "name": "Syrupwood Farm", "theme": "farm",
		"tagline": "Golden groves, syrup rivers and creaky wooden gears.",
		"page": "Amber Glaze Page", "keeper": "Maple the Calf", "music": "world2",
		"stages": ["W2-L1", "W2-L2", "W2-L3", "W2-X", "W2-B"],
	},
	{
		"id": "W3", "index": 3, "name": "Frostpop Fair", "theme": "fair",
		"tagline": "A winter carnival of ice ponds and popcorn rides.",
		"page": "Frosted Sugar Page", "keeper": "Pompom the Penguin", "music": "world3",
		"stages": ["W3-L1", "W3-L2", "W3-L3", "W3-X", "W3-B"],
	},
	{
		"id": "W4", "index": 4, "name": "Noodlebrook Market", "theme": "market",
		"tagline": "Busy canals, paper lanterns and citrus mirrors.",
		"page": "Tangy Spark Page", "keeper": "Udon the Otter", "music": "world4",
		"stages": ["W4-L1", "W4-L2", "W4-L3", "W4-X", "W4-B"],
	},
	{
		"id": "W5", "index": 5, "name": "Moonberry Marsh", "theme": "marsh",
		"tagline": "Glowing night wetlands where everything is listening.",
		"page": "Midnight Berry Page", "keeper": "Lumi the Firefly", "music": "world5",
		"stages": ["W5-L1", "W5-L2", "W5-L3", "W5-X", "W5-B"],
	},
	{
		"id": "W6", "index": 6, "name": "The Silent Kitchen", "theme": "kitchen",
		"tagline": "A floating clockwork castle of brass ovens and silent chimes.",
		"page": "Hearthsong Page", "keeper": "Ladle the Kettle-sprite", "music": "world6",
		"stages": ["W6-L1", "W6-L2", "W6-L3", "W6-X", "W6-B"],
	},
]

## id -> {name, kind, technique}
const STAGES := {
	"HUB": {"name": "Home Nest", "kind": "hub", "technique": "Recipe book and world gates"},
	"W1-L1": {"name": "The Missing Muffin", "kind": "core", "technique": "Waddle, jump, honk, eat"},
	"W1-L2": {"name": "Berry Breeze", "kind": "core", "technique": "Bubble Float and breezes"},
	"W1-L3": {"name": "The Warm Windmill", "kind": "core", "technique": "Fire Honk and Steam Lift"},
	"W1-X": {"name": "Crumb Chase", "kind": "optional", "technique": "Shortcuts against the clock"},
	"W1-B": {"name": "Puddle Puffer", "kind": "boss", "technique": "Redirect bubbles and steam"},
	"W2-L1": {"name": "Sticky Situation", "kind": "core", "technique": "Sticky Waddle on walls"},
	"W2-L2": {"name": "Rolling Harvest", "kind": "core", "technique": "Melon Roll and big buttons"},
	"W2-L3": {"name": "The Barn That Turned Sideways", "kind": "core", "technique": "Caramel bridges"},
	"W2-X": {"name": "The Great Rolling Race", "kind": "optional", "technique": "Sticky Bowling loops"},
	"W2-B": {"name": "Barrelback", "kind": "boss", "technique": "Weight plates and gummed wheels"},
	"W3-L1": {"name": "A Slippery Welcome", "kind": "core", "technique": "Freeze paths over water"},
	"W3-L2": {"name": "Pop Goes the Platform", "kind": "core", "technique": "Bounce rhythm"},
	"W3-L3": {"name": "The Carousel of Cold", "kind": "core", "technique": "Frost Pop and Snowball Express"},
	"W3-X": {"name": "Endless Bounce", "kind": "optional", "technique": "A tall bouncing climb"},
	"W3-B": {"name": "Whirligig", "kind": "boss", "technique": "Freeze the spinning ride"},
	"W4-L1": {"name": "Market Detour", "kind": "core", "technique": "Noodle Neck reach and grab"},
	"W4-L2": {"name": "Lantern Labyrinth", "kind": "core", "technique": "Flash Zing light beams"},
	"W4-L3": {"name": "The Longest Noodle", "kind": "core", "technique": "Tether Noodle swings"},
	"W4-X": {"name": "Chef's Secret Alley", "kind": "optional", "technique": "Prism Chill redirection"},
	"W4-B": {"name": "The Twin Teapots", "kind": "boss", "technique": "Two linked puzzles"},
	"W5-L1": {"name": "A Very Quiet Honk", "kind": "core", "technique": "Sneaking with Moonmint"},
	"W5-L2": {"name": "Painted Paths", "kind": "core", "technique": "Jam Trail platforms"},
	"W5-L3": {"name": "The Whispering Bog", "kind": "core", "technique": "Quiet Ink"},
	"W5-X": {"name": "Glow Trail Hunt", "kind": "optional", "technique": "Stealth and route planning"},
	"W5-B": {"name": "The Echo Owl", "kind": "boss", "technique": "Harmony, not a fight"},
	"W6-L1": {"name": "The Quiet Gate", "kind": "core", "technique": "Drumbeat Honk resonance"},
	"W6-L2": {"name": "Cloud Oven Climb", "kind": "core", "technique": "Feathercloud steps"},
	"W6-L3": {"name": "The Missing Last Note", "kind": "core", "technique": "Thundercloud and Sunbeam Steps"},
	"W6-X": {"name": "The Perfect Feast Trial", "kind": "optional", "technique": "Every power, one trial"},
	"W6-B": {"name": "Cloche and the Silent Bell", "kind": "boss", "technique": "Three-part harmony"},
}

var _cache: Dictionary = {}


func world(world_id: String) -> Dictionary:
	for w in WORLDS:
		if w["id"] == world_id:
			return w
	return {}


func world_of(level_id: String) -> Dictionary:
	if level_id.length() >= 2 and level_id.begins_with("W"):
		return world(level_id.substr(0, 2))
	return {}


func world_index(level_id: String) -> int:
	var w := world_of(level_id)
	return int(w.get("index", 0))


func stage(level_id: String) -> Dictionary:
	return STAGES.get(level_id, {})


func stage_name(level_id: String) -> String:
	return str(stage(level_id).get("name", level_id))


func stage_kind(level_id: String) -> String:
	return str(stage(level_id).get("kind", "core"))


func all_stage_ids() -> Array[String]:
	var out: Array[String] = []
	for w in WORLDS:
		for s: String in w["stages"]:
			out.append(s)
	return out


func level_path(level_id: String) -> String:
	return LEVEL_DIR + level_id + ".txt"


func has_level(level_id: String) -> bool:
	return FileAccess.file_exists(level_path(level_id))


func load_text(level_id: String) -> String:
	var path := level_path(level_id)
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Level file missing: " + path)
		return ""
	var text := f.get_as_text()
	f.close()
	return text


func load_level(level_id: String) -> LevelData:
	if _cache.has(level_id):
		return _cache[level_id]
	var text := load_text(level_id)
	if text == "":
		return null
	var data := LevelData.parse(text, level_id)
	_cache[level_id] = data
	return data


func clear_cache() -> void:
	_cache.clear()


## Which stage has to be finished before this one opens ("" = always open).
func prerequisite(level_id: String) -> String:
	var w := world_of(level_id)
	if w.is_empty():
		return ""
	var stages: Array = w["stages"]
	var wid: String = w["id"]
	var idx := int(w["index"])
	if level_id == wid + "-L1":
		if idx == 1:
			return ""
		return "W%d-B" % (idx - 1)
	if level_id == wid + "-L2":
		return wid + "-L1"
	if level_id == wid + "-L3":
		return wid + "-L2"
	if level_id == wid + "-X":
		return wid + "-L2"
	if level_id == wid + "-B":
		return wid + "-L3"
	return str(stages[0])


## The stage the story sends the player to next after clearing level_id.
func next_story_stage(level_id: String) -> String:
	var w := world_of(level_id)
	if w.is_empty():
		return ""
	var wid: String = w["id"]
	var idx := int(w["index"])
	match level_id.substr(3):
		"L1":
			return wid + "-L2"
		"L2":
			return wid + "-L3"
		"L3":
			return wid + "-B"
		"B":
			return "W%d-L1" % (idx + 1) if idx < WORLDS.size() else ""
	return ""


func scrap_total() -> int:
	return SCRAPS_PER_WORLD * WORLDS.size()


func pin_total() -> int:
	return PINS_PER_WORLD * WORLDS.size()


func dish_total() -> int:
	return DISHES_PER_WORLD * WORLDS.size()
