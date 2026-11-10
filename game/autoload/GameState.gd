extends Node
## The player's progress (the saved profile) plus the values that only live
## during a stage (Comfort Feathers, Honk Charge).

signal feathers_changed(value: int)
signal charge_changed(value: float)
signal collected(kind: String, id: String)
signal recipe_discovered(recipe: RecipeDefinition)
signal food_unlocked(id: StringName)
signal progress_changed
signal toast(text: String, icon: Texture2D)

const MAX_FEATHERS := 3
const MAX_CHARGE := 100.0
const KIND_KEYS := {
	"scrap": "recipe_scraps",
	"pin": "goose_pins",
	"dish": "secret_dishes",
	"page": "flavor_pages",
}

var slot: int = -1
var profile: Dictionary = {}

var feathers: int = MAX_FEATHERS
var honk_charge: float = MAX_CHARGE
## Seconds since the last ability use; charge trickles back after a pause.
var _since_spend := 99.0
var _play_clock := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	profile = SaveService.new_profile(0)
	slot = -1


func _process(delta: float) -> void:
	if not get_tree().paused:
		_play_clock += delta
		if _play_clock >= 1.0:
			profile["played_seconds"] = float(profile.get("played_seconds", 0.0)) + _play_clock
			_play_clock = 0.0


# ---------------------------------------------------------------- profiles --

func start_new(new_slot: int) -> void:
	slot = new_slot
	profile = SaveService.new_profile(maxi(new_slot, 0))
	reset_session()
	save()
	progress_changed.emit()


func load_profile(load_slot_index: int) -> bool:
	var data := SaveService.load_slot(load_slot_index)
	if data.is_empty():
		return false
	slot = load_slot_index
	profile = data
	reset_session()
	progress_changed.emit()
	return true


func save() -> bool:
	if slot < 0:
		return true
	profile["comfort_feathers"] = feathers
	profile["honk_charge"] = int(honk_charge)
	return SaveService.save_slot(slot, profile)


## Used by tests and by "play a stage directly" debugging: a throwaway profile.
func use_temp_profile() -> void:
	slot = -1
	profile = SaveService.new_profile(0)
	reset_session()


func reset_session() -> void:
	feathers = MAX_FEATHERS
	honk_charge = MAX_CHARGE
	_since_spend = 99.0
	feathers_changed.emit(feathers)
	charge_changed.emit(honk_charge)


# -------------------------------------------------------------------- flags --

func has_flag(flag: String) -> bool:
	return (profile["story_flags"] as Array).has(flag)


func set_flag(flag: String) -> void:
	var flags: Array = profile["story_flags"]
	if not flags.has(flag):
		flags.append(flag)


# ------------------------------------------------------------------ feathers --

func lose_feather() -> bool:
	## Returns true when Tato is out of feathers (snack-break respawn).
	if Settings.feathers_protected():
		return false
	feathers = maxi(feathers - 1, 0)
	feathers_changed.emit(feathers)
	return feathers <= 0


func restore_feathers() -> void:
	feathers = MAX_FEATHERS
	feathers_changed.emit(feathers)


func add_feather() -> bool:
	if feathers >= MAX_FEATHERS:
		return false
	feathers += 1
	feathers_changed.emit(feathers)
	return true


# -------------------------------------------------------------- honk charge --

func can_spend(amount: float) -> bool:
	return honk_charge + 0.01 >= cost_for(amount)


func cost_for(amount: float) -> float:
	return amount * (0.6 if Settings.flag("cozy_mode") else 1.0)


func spend_charge(amount: float) -> bool:
	var cost := cost_for(amount)
	if honk_charge + 0.01 < cost:
		return false
	honk_charge = maxf(honk_charge - cost, 0.0)
	_since_spend = 0.0
	charge_changed.emit(honk_charge)
	return true


func add_charge(amount: float) -> void:
	var before := honk_charge
	honk_charge = minf(honk_charge + amount, MAX_CHARGE)
	if honk_charge != before:
		charge_changed.emit(honk_charge)


## Slow refill so no puzzle can be starved of charge. Called by the stage.
func tick_charge(delta: float) -> void:
	_since_spend += delta
	if _since_spend > 1.2 and honk_charge < MAX_CHARGE:
		add_charge(9.0 * delta)


# -------------------------------------------------------------- collectibles --

func has_collected(kind: String, id: String) -> bool:
	if not KIND_KEYS.has(kind):
		return false
	return (profile[KIND_KEYS[kind]] as Array).has(id)


func collect(kind: String, id: String) -> bool:
	## Returns true when this is a new find.
	if not KIND_KEYS.has(kind):
		return false
	var list: Array = profile[KIND_KEYS[kind]]
	if list.has(id):
		return false
	list.append(id)
	collected.emit(kind, id)
	progress_changed.emit()
	return true


func count(kind: String) -> int:
	if not KIND_KEYS.has(kind):
		return 0
	return (profile[KIND_KEYS[kind]] as Array).size()


func count_in_world(kind: String, world_id: String) -> int:
	if not KIND_KEYS.has(kind):
		return 0
	var n := 0
	for id: String in profile[KIND_KEYS[kind]]:
		if id.begins_with(world_id):
			n += 1
	return n


func count_in_level(kind: String, level_id: String) -> int:
	if not KIND_KEYS.has(kind):
		return 0
	var n := 0
	for id: String in profile[KIND_KEYS[kind]]:
		if id.begins_with(level_id + "-"):
			n += 1
	return n


# ---------------------------------------------------------- foods & recipes --

func unlock_food(id: StringName) -> bool:
	var list: Array = profile["food_unlocks"]
	if list.has(String(id)):
		return false
	list.append(String(id))
	food_unlocked.emit(id)
	progress_changed.emit()
	return true


func knows_food(id: StringName) -> bool:
	return (profile["food_unlocks"] as Array).has(String(id))


func discover_recipe(rec: RecipeDefinition) -> bool:
	if rec == null:
		return false
	var key := rec.pair_key()
	var list: Array = profile["recipe_discoveries"]
	if list.has(key):
		return false
	list.append(key)
	recipe_discovered.emit(rec)
	progress_changed.emit()
	return true


func knows_recipe(rec: RecipeDefinition) -> bool:
	return rec != null and (profile["recipe_discoveries"] as Array).has(rec.pair_key())


func named_recipes_found() -> int:
	var n := 0
	for rec in FoodDB.named_recipes():
		if knows_recipe(rec):
			n += 1
	return n


func experiments_found() -> int:
	return (profile["recipe_discoveries"] as Array).size() - named_recipes_found()


# ----------------------------------------------------------------- progress --

func is_cleared(level_id: String) -> bool:
	return (profile["level_clear_ids"] as Array).has(level_id)


func is_unlocked(level_id: String) -> bool:
	if level_id == LevelDB.HUB_ID:
		return true
	if is_cleared(level_id):
		return true
	var pre := LevelDB.prerequisite(level_id)
	if pre == "":
		return true
	return is_cleared(pre)


func world_unlocked(world_id: String) -> bool:
	return is_unlocked(world_id + "-L1")


func finale_scraps_needed() -> int:
	return LevelDB.FINALE_SCRAPS_COZY if Settings.flag("cozy_mode") else LevelDB.FINALE_SCRAPS


## Records a finished stage. stats: {time, hurt, scraps_found, scraps_total}
func mark_cleared(level_id: String, stats: Dictionary = {}) -> Dictionary:
	var result := {"first_clear": false, "new_medals": []}
	var list: Array = profile["level_clear_ids"]
	if not list.has(level_id):
		list.append(level_id)
		result["first_clear"] = true
	var w := LevelDB.world_of(level_id)
	if not w.is_empty():
		var unlocks: Array = profile["world_unlocks"]
		if not unlocks.has(w["id"]):
			unlocks.append(w["id"])
		if LevelDB.stage_kind(level_id) == "boss":
			collect("page", str(w["id"]))
			var nxt := "W%d" % (int(w["index"]) + 1)
			if not LevelDB.world(nxt).is_empty() and not unlocks.has(nxt):
				unlocks.append(nxt)
			if int(w["index"]) == LevelDB.WORLDS.size():
				profile["game_complete"] = true
	# Feather Medals: cosmetic stage achievements
	var medals: Dictionary = profile["medals"]
	var mine: Dictionary = medals.get(level_id, {})
	var earned: Array = []
	if not mine.get("clear", false):
		mine["clear"] = true
		earned.append("clear")
	if stats.get("scraps_total", 0) > 0 and stats.get("scraps_found", 0) >= stats.get("scraps_total", 0) and not mine.get("explorer", false):
		mine["explorer"] = true
		earned.append("explorer")
	if stats.has("hurt") and int(stats["hurt"]) == 0 and not mine.get("gentle", false):
		mine["gentle"] = true
		earned.append("gentle")
	medals[level_id] = mine
	result["new_medals"] = earned
	if stats.has("time"):
		var best: Dictionary = profile["best_times"]
		var t := float(stats["time"])
		if not best.has(level_id) or t < float(best[level_id]):
			best[level_id] = t
			result["best_time"] = true
	profile["current_level"] = LevelDB.next_story_stage(level_id)
	profile["checkpoint"] = ""
	progress_changed.emit()
	save()
	return result


func medal_count() -> int:
	var n := 0
	var medals: Dictionary = profile["medals"]
	for level_id: String in medals.keys():
		var m: Dictionary = medals[level_id]
		for k: String in m.keys():
			if m[k]:
				n += 1
	return n


## 0..1 overall completion used on the save-slot card and the ending.
func completion() -> float:
	var have := float(count("scrap") + count("pin") + count("dish") + count("page") * 4 + named_recipes_found() * 2)
	var total := float(LevelDB.scrap_total() + LevelDB.pin_total() + LevelDB.dish_total() + LevelDB.WORLDS.size() * 4 + FoodDB.RECIPE_IDS.size() * 2)
	return clampf(have / maxf(total, 1.0), 0.0, 1.0)


# ---------------------------------------------------------------- cosmetics --

func unlock_cosmetic(id: String) -> bool:
	var list: Array = profile["cosmetic_unlocks"]
	if list.has(id):
		return false
	list.append(id)
	progress_changed.emit()
	return true


func equipped(slot_name: String) -> String:
	return str((profile["equipped_cosmetics"] as Dictionary).get(slot_name, ""))


func equip(slot_name: String, id: String) -> void:
	(profile["equipped_cosmetics"] as Dictionary)[slot_name] = id
	progress_changed.emit()
	save()
