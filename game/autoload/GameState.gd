extends Node
## The player's progress (the saved profile) plus the values that only live
## during a stage: hearts, keys and the coins picked up so far.

signal hearts_changed(value: int)
signal coins_changed(stage_coins: int, wallet: int)
signal keys_changed(value: int)
signal collected(kind: String, id: String)
signal recipe_discovered(recipe: RecipeDefinition)
signal food_unlocked(id: StringName)
signal progress_changed
signal toast(text: String, icon: Texture2D)

const MAX_HEARTS := 5
const COINS_FOR_HEAL := 100
const KIND_KEYS := {
	"note": "treasure_notes",
	"star": "stars",
	"page": "flavor_pages",
}
const NOTES_PER_STAGE := 3

var slot: int = -1
var profile: Dictionary = {}

var hearts: int = MAX_HEARTS
var keys: int = 0
var stage_coins: int = 0
var _heal_counter := 0
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
	return SaveService.save_slot(slot, profile)


## Used by tests and by "play a stage directly": a throwaway profile.
func use_temp_profile() -> void:
	slot = -1
	profile = SaveService.new_profile(0)
	reset_session()


func reset_session() -> void:
	hearts = MAX_HEARTS
	keys = 0
	stage_coins = 0
	_heal_counter = 0
	hearts_changed.emit(hearts)
	keys_changed.emit(keys)
	coins_changed.emit(stage_coins, wallet())


# -------------------------------------------------------------------- flags --

func has_flag(flag: String) -> bool:
	return (profile["story_flags"] as Array).has(flag)


func set_flag(flag: String) -> void:
	var flags: Array = profile["story_flags"]
	if not flags.has(flag):
		flags.append(flag)


# ------------------------------------------------------------------- hearts --

## Returns true when Tato is out of hearts (he respawns at the checkpoint).
func lose_heart(amount: int = 1) -> bool:
	if Settings.hearts_protected():
		return false
	hearts = maxi(hearts - amount, 0)
	hearts_changed.emit(hearts)
	return hearts <= 0


func restore_hearts() -> void:
	hearts = MAX_HEARTS
	hearts_changed.emit(hearts)


func add_heart(amount: int = 1) -> bool:
	if hearts >= MAX_HEARTS:
		return false
	hearts = mini(hearts + amount, MAX_HEARTS)
	hearts_changed.emit(hearts)
	return true


# -------------------------------------------------------------- coins, keys --

func wallet() -> int:
	return int(profile.get("coins", 0))


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	stage_coins += amount
	profile["coins"] = wallet() + amount
	profile["coins_total"] = int(profile.get("coins_total", 0)) + amount
	_heal_counter += amount
	if _heal_counter >= COINS_FOR_HEAL:
		_heal_counter -= COINS_FOR_HEAL
		if add_heart(MAX_HEARTS):
			toast.emit("100 coins! Hearts refilled", null)
	coins_changed.emit(stage_coins, wallet())


func spend_coins(amount: int) -> bool:
	if wallet() < amount:
		return false
	profile["coins"] = wallet() - amount
	coins_changed.emit(stage_coins, wallet())
	return true


func add_key() -> void:
	keys += 1
	keys_changed.emit(keys)


func use_key() -> bool:
	if keys <= 0:
		return false
	keys -= 1
	keys_changed.emit(keys)
	return true


# -------------------------------------------------------------- collectibles --

func has_collected(kind: String, id: String) -> bool:
	if not KIND_KEYS.has(kind):
		return false
	return (profile[KIND_KEYS[kind]] as Array).has(id)


## Returns true when this is a new find.
func collect(kind: String, id: String) -> bool:
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


func meet_enemy(kind: String) -> void:
	var list: Array = profile["enemies_met"]
	if not list.has(kind):
		list.append(kind)


# ---------------------------------------------------------- powers & bursts --

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


func bursts_found() -> int:
	return (profile["recipe_discoveries"] as Array).size()


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


## Records a finished stage. stats: {time, hurt, notes_found, notes_total, coins}
func mark_cleared(level_id: String, stats: Dictionary = {}) -> Dictionary:
	var result := {"first_clear": false, "new_stars": []}
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
	# Stars: one for finishing, one for finding every Treasure Note. (A third
	# is the Star hidden in the stage itself.)
	var earned: Array = []
	if collect("star", level_id + "-clear"):
		earned.append("clear")
	if int(stats.get("notes_total", 0)) > 0 and int(stats.get("notes_found", 0)) >= int(stats.get("notes_total", 0)):
		if collect("star", level_id + "-notes"):
			earned.append("notes")
	result["new_stars"] = earned
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


func stars_in_level(level_id: String) -> int:
	return count_in_level("star", level_id)


## 0..1 overall completion for the save-slot card and the ending.
func completion() -> float:
	var stage_count := float(LevelDB.all_stage_ids().size())
	var have := float(count("star") + count("note") + count("page") * 3)
	var total := stage_count * 3.0 + stage_count * NOTES_PER_STAGE + LevelDB.WORLDS.size() * 3.0
	return clampf(have / maxf(total, 1.0), 0.0, 1.0)


# ---------------------------------------------------------------- cosmetics --

func unlock_cosmetic(id: String) -> bool:
	var list: Array = profile["cosmetic_unlocks"]
	if list.has(id):
		return false
	list.append(id)
	progress_changed.emit()
	return true


func owns_cosmetic(id: String) -> bool:
	return (profile["cosmetic_unlocks"] as Array).has(id)


func equipped(slot_name: String) -> String:
	return str((profile["equipped_cosmetics"] as Dictionary).get(slot_name, ""))


func equip(slot_name: String, id: String) -> void:
	(profile["equipped_cosmetics"] as Dictionary)[slot_name] = id
	progress_changed.emit()
	save()
