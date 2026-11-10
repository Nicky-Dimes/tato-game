extends TestCase
## Save files: round trip, backup recovery, migration, hostile input.

const SLOT := 2
var _backup_main := ""
var _backup_bak := ""


func before_each() -> void:
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
	(p["treasure_notes"] as Array).append("W1-L1-N01")
	(p["recipe_discoveries"] as Array).append("FIRE_PEPPER|FROSTBERRY")
	p["coins"] = 55
	check(SaveService.save_slot(SLOT, p), "save succeeds")
	var q := SaveService.load_slot(SLOT)
	check_eq(q["treasure_notes"], ["W1-L1-N01"], "notes survive")
	check_eq(q["recipe_discoveries"], ["FIRE_PEPPER|FROSTBERRY"], "bursts survive")
	check_eq(int(q["coins"]), 55, "coins survive")
	check_eq(int(q["schema_version"]), SaveService.SCHEMA_VERSION, "schema version written")
	check_eq(str(q["profile_id"]), "slot_3", "profile id is a local slot name")


func test_backup_recovers_a_damaged_save() -> void:
	expects_errors = true      # the damaged file logs a JSON error on purpose
	var p := SaveService.new_profile(SLOT)
	(p["flavor_pages"] as Array).append("W1")
	SaveService.save_slot(SLOT, p)
	(p["flavor_pages"] as Array).append("W2")
	SaveService.save_slot(SLOT, p)
	_write(SaveService.slot_path(SLOT), "{ this is not json")
	var q := SaveService.load_slot(SLOT)
	check(not q.is_empty(), "damaged save falls back to the backup")
	check_eq(q["flavor_pages"], ["W1"], "backup content is the previous save")


func test_empty_slot() -> void:
	check(SaveService.load_slot(SLOT).is_empty(), "empty slot loads as {}")
	check(bool(SaveService.slot_summary(SLOT)["empty"]), "summary says empty")
	check(not SaveService.slot_exists(SLOT), "slot_exists is false")


func test_migration_from_old_designs() -> void:
	var v0 := {"cleared": ["W1-L1"], "scraps": ["W1-L1-S01"]}
	var m := SaveService.migrate(v0)
	check_eq(m["level_clear_ids"], ["W1-L1"], "v0 'cleared' becomes level_clear_ids")
	check_eq(m["treasure_notes"], ["W1-L1-S01"], "v0 scraps become Treasure Notes")
	var v1 := {"schema_version": 1, "recipe_scraps": ["W2-L1-S02"], "goose_pins": ["x"], "comfort_feathers": 2,
		"recipe_discoveries": ["BUBBLE|PEPPER"], "food_unlocks": ["PEPPER"]}
	var m1 := SaveService.migrate(v1)
	check_eq(m1["treasure_notes"], ["W2-L1-S02"], "v1 recipe_scraps become Treasure Notes")
	check(not m1.has("goose_pins") and not m1.has("comfort_feathers"), "v1 fields that no longer exist are dropped")
	check_eq(m1["recipe_discoveries"], [], "old two-pocket recipes are cleared (those foods are gone)")
	check((m1["world_unlocks"] as Array).has("W1"), "world 1 always unlocked")
	check_eq(int(m1["schema_version"]), SaveService.SCHEMA_VERSION, "version brought up to date")
	for key: String in SaveService.PROFILE_DEFAULTS.keys():
		check(m1.has(key), "migrated save has '%s'" % key)


func test_migration_rejects_wrong_types_and_keeps_unknown_fields() -> void:
	var weird := {
		"schema_version": 2,
		"level_clear_ids": "not a list",
		"treasure_notes": ["ok", 7, {"x": 1}, "ok", "x".repeat(200)],
		"medals": [],
		"coins": -50,
		"future_field": {"hello": "world"},
	}
	var m := SaveService.migrate(weird)
	check_eq(m["level_clear_ids"], [], "wrong-typed list replaced by default")
	check_eq(m["treasure_notes"], ["ok"], "non-strings, repeats and oversized ids dropped")
	check(m["medals"] is Dictionary, "wrong-typed dictionary replaced")
	check_eq(int(m["coins"]), 0, "negative coins clamped")
	check(m.has("future_field"), "unknown fields are kept for newer versions")


func test_game_state_saves_and_loads() -> void:
	GameState.start_new(SLOT)
	GameState.collect("note", "W1-L1-N01")
	GameState.unlock_food(&"FIRE_PEPPER")
	GameState.discover_recipe(FoodDB.resolve(&"FIRE_PEPPER", &"BUBBLEBERRY"))
	GameState.add_coins(30)
	GameState.mark_cleared("W1-L1", {"time": 61.0, "hurt": 0, "notes_found": 3, "notes_total": 3})
	check(GameState.save(), "GameState.save succeeds")
	GameState.use_temp_profile()
	check(not GameState.is_cleared("W1-L1"), "temp profile is blank")
	check(GameState.load_profile(SLOT), "profile loads")
	check(GameState.is_cleared("W1-L1"), "cleared stage restored")
	check(GameState.has_collected("note", "W1-L1-N01"), "note restored")
	check(GameState.knows_food(&"FIRE_PEPPER"), "power restored")
	check(GameState.knows_recipe(FoodDB.resolve(&"BUBBLEBERRY", &"FIRE_PEPPER")), "burst restored")
	check_eq(GameState.wallet(), 30, "coins restored")
	check(GameState.is_unlocked("W1-L2"), "next stage unlocked after clearing W1-L1")
	check(not GameState.is_unlocked("W1-B"), "boss still locked")
	check_eq(GameState.stars_in_level("W1-L1"), 2, "stars for finishing and for all notes")


func test_hearts_and_coins() -> void:
	GameState.use_temp_profile()
	Settings.set_value("cozy_mode", false)
	Settings.set_value("infinite_feathers", false)
	check_eq(GameState.hearts, 5, "five hearts")
	check(not GameState.lose_heart(), "losing one heart is not a defeat")
	check_eq(GameState.hearts, 4, "four left")
	check(GameState.add_heart(), "a heart pickup heals")
	check(not GameState.add_heart(), "cannot go above five")
	for i in 4:
		GameState.lose_heart()
	check(GameState.lose_heart(), "the last heart means back to the checkpoint")
	GameState.restore_hearts()
	GameState.lose_heart(2)
	GameState.add_coins(100)
	check_eq(GameState.hearts, 5, "100 coins refill the hearts")
	check_eq(GameState.wallet(), 100, "coins are kept in the wallet")
	check(GameState.spend_coins(40) and GameState.wallet() == 60, "spending works")
	check(not GameState.spend_coins(999), "cannot overspend")
