extends Node
## Save slots on disk. Atomic JSON writes (temp file + rename), one rolling
## backup per slot, and schema migration. Saves never contain code and are
## validated field-by-field when read.

signal save_failed(message: String)
signal saved(slot: int)

const SCHEMA_VERSION := 2
const SLOT_COUNT := 3
const DIR := "user://saves"

## key -> default value. Type of the default is the required type.
const PROFILE_DEFAULTS := {
	"schema_version": SCHEMA_VERSION,
	"profile_id": "",
	"created_unix": 0,
	"played_seconds": 0.0,
	"world_unlocks": ["W1"],
	"level_clear_ids": [],
	"current_level": "",
	"checkpoint": "",
	"food_unlocks": [],          # power-ups met
	"recipe_discoveries": [],    # Flavor Bursts found ("A|B")
	"treasure_notes": [],
	"stars": [],
	"flavor_pages": [],
	"enemies_met": [],
	"coins": 0,
	"coins_total": 0,
	"medals": {},
	"best_times": {},
	"cosmetic_unlocks": [],
	"equipped_cosmetics": {},
	"story_flags": [],
	"hints_used": 0,
	"game_complete": false,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(DIR)


func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [DIR, slot + 1]


func backup_path(slot: int) -> String:
	return "%s/slot_%d.bak.json" % [DIR, slot + 1]


func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot)) or FileAccess.file_exists(backup_path(slot))


func new_profile(slot: int) -> Dictionary:
	var p: Dictionary = PROFILE_DEFAULTS.duplicate(true)
	p["profile_id"] = "slot_%d" % (slot + 1)
	p["created_unix"] = int(Time.get_unix_time_from_system())
	return p


## Returns {} when the slot is empty or unreadable (after trying the backup).
func load_slot(slot: int) -> Dictionary:
	var data := _read(slot_path(slot))
	if data.is_empty():
		data = _read(backup_path(slot))
		if not data.is_empty():
			push_warning("Slot %d was damaged; restored from backup." % (slot + 1))
	if data.is_empty():
		return {}
	return migrate(data)


func save_slot(slot: int, profile: Dictionary) -> bool:
	var path := slot_path(slot)
	var tmp := path + ".tmp"
	var text := JSON.stringify(profile, "\t")
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		_fail("Could not save (%s). Private browsing or a full disk can block saving." % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(text)
	var err := f.get_error()
	f.close()
	if err != OK:
		_fail("Could not save (%s)." % error_string(err))
		return false
	# verify what was written before replacing the good file
	if _read(tmp).is_empty():
		_fail("Save check failed; kept the previous save.")
		DirAccess.remove_absolute(tmp)
		return false
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(backup_path(slot)):
			DirAccess.remove_absolute(backup_path(slot))
		DirAccess.rename_absolute(path, backup_path(slot))
	var rerr := DirAccess.rename_absolute(tmp, path)
	if rerr != OK:
		# some web filesystems cannot rename: fall back to a direct write
		var g := FileAccess.open(path, FileAccess.WRITE)
		if g == null:
			_fail("Could not save (%s)." % error_string(rerr))
			return false
		g.store_string(text)
		g.close()
		DirAccess.remove_absolute(tmp)
	saved.emit(slot)
	return true


func delete_slot(slot: int) -> void:
	for p in [slot_path(slot), backup_path(slot), slot_path(slot) + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


## Small description for the slot picker.
func slot_summary(slot: int) -> Dictionary:
	var p := load_slot(slot)
	if p.is_empty():
		return {"empty": true}
	return {
		"empty": false,
		"pages": (p["flavor_pages"] as Array).size(),
		"notes": (p["treasure_notes"] as Array).size(),
		"stars": (p["stars"] as Array).size(),
		"coins": int(p["coins_total"]),
		"levels": (p["level_clear_ids"] as Array).size(),
		"played_seconds": float(p["played_seconds"]),
		"complete": bool(p["game_complete"]),
	}


## Brings any older / partial / hand-edited save up to the current schema.
## Unknown fields are kept; wrong-typed known fields fall back to defaults.
func migrate(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	var version := int(out.get("schema_version", 0))
	if version < 1:
		# v0 (pre-release prototypes) used "cleared" and "scraps"
		if out.has("cleared") and not out.has("level_clear_ids"):
			out["level_clear_ids"] = out["cleared"]
		if out.has("scraps") and not out.has("recipe_scraps"):
			out["recipe_scraps"] = out["scraps"]
		out.erase("cleared")
		out.erase("scraps")
	if version < 2:
		# v1 was the two-pocket design: scraps became Treasure Notes; pins,
		# dishes, feathers and honk charge no longer exist.
		if out.has("recipe_scraps") and not out.has("treasure_notes"):
			out["treasure_notes"] = out["recipe_scraps"]
		for old_key: String in ["recipe_scraps", "goose_pins", "secret_dishes", "comfort_feathers", "honk_charge"]:
			out.erase(old_key)
		# old recipe keys named foods that are gone
		out["recipe_discoveries"] = []
		out["food_unlocks"] = []
	for key: String in PROFILE_DEFAULTS.keys():
		var def: Variant = PROFILE_DEFAULTS[key]
		if not out.has(key):
			out[key] = def.duplicate(true) if (def is Array or def is Dictionary) else def
			continue
		var v: Variant = out[key]
		var ok := typeof(v) == typeof(def)
		if not ok and typeof(def) == TYPE_FLOAT and typeof(v) == TYPE_INT:
			out[key] = float(v)
			ok = true
		if not ok and typeof(def) == TYPE_INT and typeof(v) == TYPE_FLOAT:
			out[key] = int(v)
			ok = true
		if not ok:
			out[key] = def.duplicate(true) if (def is Array or def is Dictionary) else def
	# id lists must hold strings only, without repeats
	for key: String in ["world_unlocks", "level_clear_ids", "food_unlocks", "recipe_discoveries",
			"treasure_notes", "stars", "flavor_pages", "enemies_met", "cosmetic_unlocks", "story_flags"]:
		var clean: Array = []
		for item: Variant in out[key]:
			if typeof(item) == TYPE_STRING and not clean.has(item) and (item as String).length() <= 64:
				clean.append(item)
		out[key] = clean
	if not (out["world_unlocks"] as Array).has("W1"):
		(out["world_unlocks"] as Array).append("W1")
	out["coins"] = clampi(int(out["coins"]), 0, 999999)
	out["coins_total"] = clampi(int(out["coins_total"]), 0, 9999999)
	out["schema_version"] = SCHEMA_VERSION
	return out


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	if text.length() > 2_000_000:
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _fail(message: String) -> void:
	push_warning(message)
	save_failed.emit(message)
