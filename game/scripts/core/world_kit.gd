class_name WorldKit
extends RefCounted
## Which drawing from the "TATO World" level-asset board is which, per world.
## (The board's sub-panels are cut left to right by tools/art/extract_sheets.py.)

const KITS := {
	"grassland": {
		"block": "tile0", "block2": "tile1", "plat": "tile2", "rock": "tile3",
		"spiky": "hazard0", "spikes": "hazard1", "roller": "hazard2",
		"decor": ["prop0", "prop1", "prop2", "prop4", "prop5"],
		"flag": "flag0", "sign": "sign0", "bowl": "bowl0",
	},
	"orchard": {
		"block": "tile0", "block2": "tile1", "plat": "tile2", "rock": "tile3",
		"faller": "hazard0", "spiky": "hazard1", "hive": "hazard2",
		"decor": ["prop0", "prop1", "prop2", "prop3", "tile3"],
		"flag": "flag0", "sign": "sign0", "bowl": "bowl0", "treat": "gem1",
	},
	"candy": {
		"block": "tile0", "block2": "tile1", "plat": "tile2",
		"spikes": "hazard0", "saw": "hazard1", "drip": "hazard2",
		"decor": ["prop0", "prop1", "prop2", "prop3", "prop4"],
		"flag": "flag0", "sign": "sign0", "bowl": "bowl0", "treat": "gem1",
	},
	"icy": {
		"block": "tile0", "block2": "tile1", "plat": "tile2", "rock": "tile3",
		"icicle": "hazard0", "spiky": "hazard1", "spikes": "hazard2",
		"decor": ["prop0", "prop1", "prop2", "prop3"],
		"flag": "flag0", "sign": "sign0", "bowl": "bowl0", "treat": "gem1",
	},
	"windy": {
		"block": "tile0", "block2": "tile1", "plat": "tile3", "bridge": "tile2",
		"fan": "hazard0", "spikes": "hazard1",
		"decor": ["prop0", "prop1", "prop2", "prop3"],
		"flag": "flag0", "sign": "sign0", "bowl": "bowl0", "treat": "gem1",
	},
	"castle": {
		"block": "tile0", "block2": "tile1", "plat": "tile2", "plat2": "tile3",
		"mace": "hazard0", "torch": "hazard1", "spikes": "hazard2",
		"decor": ["prop0", "prop1", "prop2", "prop3"],
		"flag": "flag0", "sign": "sign0", "bowl": "bowl0", "treat": "gem1",
	},
}


## Each world's own little treat from the world board (worth five coins).
## Grassland's row on the board shows coins and a star, which every world has.
const TREAT_NAMES := {
	"orchard": "Shiny apple", "candy": "Gummy bear", "icy": "Snowflake",
	"windy": "Lucky leaf", "castle": "Golden crown",
}


static func has_treat(theme: String) -> bool:
	return KITS.has(theme) and (KITS[theme] as Dictionary).has("treat")


static func kit(theme: String) -> Dictionary:
	return KITS.get(theme, KITS["grassland"])


## Short art name ("world/grassland_hazard1") for a part, falling back to the
## Grassland kit when a world has no such drawing.
static func art(theme: String, part: String) -> String:
	var world := theme if KITS.has(theme) else "grassland"
	var k: Dictionary = KITS[world]
	if not k.has(part):
		world = "grassland"
		k = KITS[world]
	if not k.has(part):
		return ""
	return "world/%s_%s" % [world, str(k[part])]


static func decor(theme: String, index: int) -> String:
	var world := theme if KITS.has(theme) else "grassland"
	var list: Array = KITS[world]["decor"]
	return "world/%s_%s" % [world, str(list[absi(index) % list.size()])]
