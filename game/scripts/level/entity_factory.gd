class_name EntityFactory
extends RefCounted
## Turns an entity entry from a level file into a node. To add a new kind of
## prop or creature: write its script and add one line here.

const SCRIPTS := {
	# pickups and stage furniture
	"food": "res://scripts/props/food_bowl.gd",
	"checkpoint": "res://scripts/props/checkpoint.gd",
	"exit": "res://scripts/props/exit_gate.gd",
	"crumb": "res://scripts/props/crumb.gd",
	"scrap": "res://scripts/props/collectible.gd",
	"pin": "res://scripts/props/collectible.gd",
	"dish": "res://scripts/props/collectible.gd",
	"feather": "res://scripts/props/feather_pickup.gd",
	"sign": "res://scripts/props/sign.gd",
	"npc": "res://scripts/props/npc.gd",
	"decor": "res://scripts/props/decor.gd",
	"hintzone": "res://scripts/props/hint_zone.gd",
	# hazards
	"thorns": "res://scripts/props/thorns.gd",
	# switches and things they drive
	"chime": "res://scripts/props/chime.gd",
	"gate": "res://scripts/props/gate.gd",
	"plate": "res://scripts/props/pressure_plate.gd",
	"platform": "res://scripts/props/moving_platform.gd",
	"lever": "res://scripts/props/lever.gd",
	"reset": "res://scripts/props/reset_plate.gd",
	# flavour reactions
	"crate": "res://scripts/props/crate.gd",
	"wax": "res://scripts/props/melt_block.gd",
	"iceblock": "res://scripts/props/melt_block.gd",
	"brazier": "res://scripts/props/brazier.gd",
	"updraft": "res://scripts/props/updraft.gd",
	"pinwheel": "res://scripts/props/pinwheel.gd",
	"bush": "res://scripts/props/honk_bush.gd",
	"bounce_pad": "res://scripts/props/bounce_pad.gd",
	"wind": "res://scripts/props/wind_zone.gd",
	# creatures
	"crumb_mite": "res://scripts/enemies/crumb_mite.gd",
}

static var _loaded: Dictionary = {}


static func knows(type: String) -> bool:
	return SCRIPTS.has(type) or type == "spawn"


static func create(level: Level, e: Dictionary) -> Node:
	var type: String = e["type"]
	if not SCRIPTS.has(type):
		push_warning("%s: nothing is registered for '%s'" % [level.level_id, type])
		return null
	var path: String = SCRIPTS[type]
	if not _loaded.has(path):
		_loaded[path] = load(path) if ResourceLoader.exists(path) else null
	var script: GDScript = _loaded[path]
	if script == null:
		push_warning("%s: script missing for '%s' (%s)" % [level.level_id, type, path])
		return null
	var node: Node = script.new()
	node.name = "%s_%d_%d" % [type, e["cell"].x, e["cell"].y]
	if node.has_method("setup"):
		e["params"]["type"] = type
		node.call("setup", level, e)
	return node
