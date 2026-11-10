class_name EntityFactory
extends RefCounted
## Turns an entity entry from a level file into a node. To add a new kind of
## prop or creature: write its script and add one line here.

const SCRIPTS := {
	# things to collect
	"coin": "res://scripts/props/pickup.gd",
	"heart": "res://scripts/props/pickup.gd",
	"extraheal": "res://scripts/props/pickup.gd",
	"star": "res://scripts/props/pickup.gd",
	"note": "res://scripts/props/pickup.gd",
	"key": "res://scripts/props/pickup.gd",
	"pickup": "res://scripts/props/pickup.gd",
	"power": "res://scripts/props/power_bowl.gd",
	# stage furniture
	"checkpoint": "res://scripts/props/checkpoint.gd",
	"goal": "res://scripts/props/goal.gd",
	"sign": "res://scripts/props/sign.gd",
	"decor": "res://scripts/props/decor.gd",
	"spring": "res://scripts/props/spring.gd",
	"shroom": "res://scripts/props/spring.gd",
	"crate": "res://scripts/props/crate.gd",
	"cracked": "res://scripts/props/crate.gd",
	"iceblock": "res://scripts/props/crate.gd",
	"qblock": "res://scripts/props/qblock.gd",
	"lock": "res://scripts/props/lock.gd",
	# switches and things they drive
	"button": "res://scripts/props/button.gd",
	"lever": "res://scripts/props/lever.gd",
	"gate": "res://scripts/props/gate.gd",
	"platform": "res://scripts/props/moving_platform.gd",
	"bridge": "res://scripts/props/bridge.gd",
	"conveyor": "res://scripts/props/conveyor.gd",
	"wind": "res://scripts/props/wind_zone.gd",
	# hazards
	"spikes": "res://scripts/props/hazard.gd",
	"spiky": "res://scripts/props/hazard.gd",
	"torch": "res://scripts/props/hazard.gd",
	"saw": "res://scripts/props/hazard.gd",
	"roller": "res://scripts/props/hazard.gd",
	"mace": "res://scripts/props/hazard.gd",
	"drip": "res://scripts/props/hazard.gd",
	"icicle": "res://scripts/props/hazard.gd",
	"faller": "res://scripts/props/hazard.gd",
	"hive": "res://scripts/props/hazard.gd",
	# home nest
	"worldgate": "res://scripts/props/hub_things.gd",
	"book": "res://scripts/props/hub_things.gd",
	"door": "res://scripts/props/hub_things.gd",
	"wardrobe": "res://scripts/props/hub_things.gd",
	# bosses
	"boss": "res://scripts/bosses/boss.gd",
}

static var _loaded: Dictionary = {}


static func knows(type: String) -> bool:
	return SCRIPTS.has(type) or type == "spawn" or EnemyData.has(type)


static func create(level: Level, e: Dictionary) -> Node:
	var type: String = e["type"]
	if EnemyData.has(type):
		# creatures: the script comes from the enemy table
		var epath := EnemyData.script_for(type)
		if not _loaded.has(epath):
			_loaded[epath] = load(epath)
		var enemy: Node = (_loaded[epath] as GDScript).new()
		enemy.name = "%s_%d_%d" % [type, e["cell"].x, e["cell"].y]
		e["params"]["type"] = type
		enemy.call("setup", level, e)
		return enemy
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
