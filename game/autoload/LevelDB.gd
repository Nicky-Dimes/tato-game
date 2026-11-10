extends Node
## The campaign table: worlds, stages, unlock rules and level file loading.
## Stage order and names follow docs/CONTENT_MATRIX.csv.

const LEVEL_DIR := "res://data/levels/"
const HUB_ID := "HUB"
const NOTES_PER_STAGE := 3

const WORLDS: Array[Dictionary] = [
	{
		"id": "W1", "index": 1, "name": "Grassland", "theme": "grassland",
		"tagline": "Rolling green hills, bouncy mushrooms and a windmill on the horizon.",
		"page": "Golden Crumb Page", "boss": "Mega Mushroot", "boss_art": "mega_mushroot", "music": "world1",
		"gimmick": "Bounce Mushroom", "powers": ["FIRE_PEPPER", "BUBBLEBERRY"],
		"stages": ["W1-L1", "W1-L2", "W1-L3", "W1-X", "W1-B"],
	},
	{
		"id": "W2", "index": 2, "name": "Orchard", "theme": "orchard",
		"tagline": "Apple trees, ladders and baskets. Mind the falling apples!",
		"page": "Amber Glaze Page", "boss": "Gigantapple", "boss_art": "gigantapple", "music": "world2",
		"gimmick": "Falling Apples", "powers": ["WATERMELON", "HONEYCOMB"],
		"stages": ["W2-L1", "W2-L2", "W2-L3", "W2-X", "W2-B"],
	},
	{
		"id": "W3", "index": 3, "name": "Candy Carnival", "theme": "candy",
		"tagline": "Frosted cake blocks, lollipops and candy conveyor belts.",
		"page": "Frosted Sugar Page", "boss": "Candy King", "boss_art": "candy_king", "music": "world3",
		"gimmick": "Candy Conveyor", "powers": ["POPCORN", "NOODLE"],
		"stages": ["W3-L1", "W3-L2", "W3-L3", "W3-X", "W3-B"],
	},
	{
		"id": "W4", "index": 4, "name": "Icy Pond", "theme": "icy",
		"tagline": "Snowy blocks, igloos and very slippery ice.",
		"page": "Tangy Spark Page", "boss": "Frost Puffin Lord", "boss_art": "frost_puffin_lord", "music": "world4",
		"gimmick": "Slick Ice", "powers": ["FROSTBERRY", "COCOA_SHIELD"],
		"stages": ["W4-L1", "W4-L2", "W4-L3", "W4-X", "W4-B"],
	},
	{
		"id": "W5", "index": 5, "name": "Windy Mill", "theme": "windy",
		"tagline": "High bluffs, wooden bridges and gusts that carry a little goose far.",
		"page": "Midnight Berry Page", "boss": "Sky Airship Turtle", "boss_art": "sky_airship_turtle", "music": "world5",
		"gimmick": "Wind Gust", "powers": ["GARLIC_DASH", "THUNDER_CORN"],
		"stages": ["W5-L1", "W5-L2", "W5-L3", "W5-X", "W5-B"],
	},
	{
		"id": "W6", "index": 6, "name": "Castle Feast", "theme": "castle",
		"tagline": "Banners, banquet tables, drawbridges and the grandest kitchen of all.",
		"page": "Hearthsong Page", "boss": "Chef Castle Golem", "boss_art": "chef_castle_golem", "music": "world6",
		"gimmick": "Drawbridge", "powers": ["LEMON_BEAM", "TOMATO_BOMB"],
		"stages": ["W6-L1", "W6-L2", "W6-L3", "W6-X", "W6-B"],
	},
]

## id -> {name, kind}
const STAGES := {
	"HUB": {"name": "Home Nest", "kind": "hub"},
	"TRIAL": {"name": "Snack Trial Room", "kind": "hub"},
	"W1-L1": {"name": "Honk Hill", "kind": "core"},
	"W1-L2": {"name": "Bouncy Meadow", "kind": "core"},
	"W1-L3": {"name": "Hedgehog Hollow", "kind": "core"},
	"W1-X": {"name": "Coin Dash", "kind": "optional"},
	"W1-B": {"name": "Mega Mushroot", "kind": "boss"},
	"W2-L1": {"name": "Apple Lane", "kind": "core"},
	"W2-L2": {"name": "Mole Orchard", "kind": "core"},
	"W2-L3": {"name": "Treetop Tumble", "kind": "core"},
	"W2-X": {"name": "Bee Line", "kind": "optional"},
	"W2-B": {"name": "Gigantapple", "kind": "boss"},
	"W3-L1": {"name": "Sprinkle Street", "kind": "core"},
	"W3-L2": {"name": "Conveyor Carnival", "kind": "core"},
	"W3-L3": {"name": "Cotton Candy Climb", "kind": "core"},
	"W3-X": {"name": "Balloon Bash", "kind": "optional"},
	"W3-B": {"name": "Candy King", "kind": "boss"},
	"W4-L1": {"name": "Slippy Shore", "kind": "core"},
	"W4-L2": {"name": "Icicle Cavern", "kind": "core"},
	"W4-L3": {"name": "Frozen Falls", "kind": "core"},
	"W4-X": {"name": "Puffin Slide", "kind": "optional"},
	"W4-B": {"name": "Frost Puffin Lord", "kind": "boss"},
	"W5-L1": {"name": "Breezy Bluffs", "kind": "core"},
	"W5-L2": {"name": "Gusty Gears", "kind": "core"},
	"W5-L3": {"name": "Above the Clouds", "kind": "core"},
	"W5-X": {"name": "Tailwind Trial", "kind": "optional"},
	"W5-B": {"name": "Sky Airship Turtle", "kind": "boss"},
	"W6-L1": {"name": "Banquet Bridge", "kind": "core"},
	"W6-L2": {"name": "Kitchen Keep", "kind": "core"},
	"W6-L3": {"name": "The Great Hall", "kind": "core"},
	"W6-X": {"name": "Feast Gauntlet", "kind": "optional"},
	"W6-B": {"name": "Chef Castle Golem", "kind": "boss"},
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


func note_total() -> int:
	return NOTES_PER_STAGE * all_stage_ids().size()


func star_total() -> int:
	return 3 * all_stage_ids().size()
