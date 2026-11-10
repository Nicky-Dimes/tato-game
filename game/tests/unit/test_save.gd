extends TestCase
## Save files: round trip, backup recovery, migration, hostile input.

const SLOT := 2
var _backup_main := ""
var _backup_bak := ""


func before_each() -> void:
	# keep whatever a real player has in this slot
	_backup_main = _read(SaveService.slot_path(SLOT))
	_backup_bak = _read(SaveService.backup_path(SLOT))
	SaveService.delete_slot(SLOT)


func after_each() -> void:
	SaveService.delete_slot(SLOT)
	_write(SaveService.slot_path(SLOT), _backup_main)
	_write(SaveService.backup_path(SLOT), _backup_bak)
	GameState.use_temp_profile()


func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""


func _write(path: String, text: String) -> void:
	if text == "":
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_round_trip() -> void:
	var p := SaveService.new_profile(SLOT)
	(p["recipe_scraps"] as Array).append("W1-L1-S01")
	(p["recipe_discoveries"] as Array).append("BUBBLE|PEPPER")
	p["honk_charge"] = 55
	check(SaveService.save_slot(SLOT, p), "save succeeds")
	var q := SaveService.load_slot(SLOT)
	check_eq(q["recipe_scraps"], ["W1-L1-S01"], "scraps survive")
	check_eq(q["recipe_discoveries"], ["BUBBLE|PEPPER"], "recipes survive")
	check_eq(int(q["honk_charge"]), 55, "charge survives")
	check_eq(int(q["schema_version"]), SaveService.SCHEMA_VERSION, "schema version written")
	check_eq(str(q["profile_id"]), "slot_3", "profile id is local slot name")


func test_backup_recovers_a_damaged_save() -> void:
	var p := SaveService.new_profile(SLOT)
	(p["flavor_pages"] as Array).append("W1")
	SaveService.save_slot(SLOT, p)
	(p["flavor_pages"] as Array).append("W2")
	SaveService.save_slot(SLOT, p)      # first save is now the backup
	_write(SaveService.slot_path(SLOT), "{ this is not json")
	var q := SaveService.load_slot(SLOT)
	check(not q.is_empty(), "damaged save falls back to the backup")
	check_eq(q["flavor_pages"], ["W1"], "backup content is the previous save")


func test_empty_slot() -> void:
	check(SaveService.load_slot(SLOT).is_empty(), "empty slot loads as {}")
	check(bool(SaveService.slot_summary(SLOT)["empty"]), "summary says empty")
	check(not SaveService.slot_exists(SLOT), "slot_exists is false")


func test_migration_from_old_and_partial_saves() -> void:
	var old := {"cleared": ["W1-L1"], "scraps": ["W1-L1-S01"], "comfort_feathers": 99, "honk_charge": -5}
	var m := SaveService.migrate(old)
	check_eq(m["level_clear_ids"], ["W1-L1"], "v0 'cleared' becomes level_clear_ids")
	check_eq(m["recipe_scraps"], ["W1-L1-S01"], "v0 'scraps' becomes recipe_scraps")
	check_eq(int(m["comfort_feathers"]), 3, "feathers clamped")
	check_eq(int(m["honk_charge"]), 0, "charge clamped")
	check((m["world_unlocks"] as Array).has("W1"), "world 1 always unlocked")
	check_eq(int(m["schema_version"]), SaveService.SCHEMA_VERSION, "version brought up to date")
	for key: String in SaveService.PROFILE_DEFAULTS.keys():
		check(m.has(key), "migrated save has '%s'" % key)


func test_migration_rejects_wrong_types_and_keeps_unknown_fields() -> void:
	var weird := {
		"schema_version": 1,
		"level_clear_ids": "not a list",
		"recipe_scraps": ["ok", 7, {"x": 1}, "ok", "x".repeat(200)],
		"medals": [],
		"future_field": {"hello": "world"},
	}
	var m := SaveService.migrate(weird)
	check_eq(m["level_clear_ids"], [], "wrong-typed list replaced by default")
	check_eq(m["recipe_scraps"], ["ok"], "non-strings, repeats and oversized ids dropped")
	check(m["medals"] is Dictionary, "wrong-typed dictionary replaced")
	check(m.has("future_field"), "unknown fields are kept for newer versions")


func test_game_state_saves_and_loads() -> void:
	GameState.start_new(SLOT)
	GameState.collect("scrap", "W1-L1-S01")
	GameState.unlock_food(&"PEPPER")
	GameState.discover_recipe(FoodDB.resolve(&"PEPPER", &"BUBBLE"))
	GameState.mark_cleared("W1-L1", {"time": 61.0, "hurt": 0, "scraps_found": 3, "scraps_total": 3})
	check(GameState.save(), "GameState.save succeeds")
	GameState.use_temp_profile()
	check(not GameState.is_cleared("W1-L1"), "temp profile is blank")
	check(GameState.load_profile(SLOT), "profile loads")
	check(GameState.is_cleared("W1-L1"), "cleared stage restored")
	check(GameState.has_collected("scrap", "W1-L1-S01"), "scrap restored")
	check(GameState.knows_food(&"PEPPER"), "food restored")
	check(GameState.knows_recipe(FoodDB.resolve(&"BUBBLE", &"PEPPER")), "recipe restored")
	check(GameState.is_unlocked("W1-L2"), "next stage unlocked after clearing W1-L1")
	check(not GameState.is_unlocked("W1-B"), "finale still locked")
	var medals: Dictionary = GameState.profile["medals"]
	check(medals.has("W1-L1") and medals["W1-L1"].get("explorer", false) and medals["W1-L1"].get("gentle", false), "medals recorded")
