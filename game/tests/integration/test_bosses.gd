extends TestCase
## Each boss arena loads, the boss runs through its attacks without errors,
## can be beaten, and beating it reveals the goal flag.

func before_each() -> void:
	Settings.set_value("cozy_mode", true)     # the test is about the boss, not Tato's hearts


func after_each() -> void:
	Settings.set_value("cozy_mode", false)


func test_all_six_bosses() -> void:
	for w in LevelDB.WORLDS:
		var id: String = str(w["id"]) + "-B"
		var level := await open_level(id)
		if not check(level != null, "%s opens" % id):
			continue
		var boss := level.boss as Boss
		if not check(boss != null, "%s has its boss" % id):
			continue
		check_eq(str(boss.info["name"]), str(w["boss"]), "%s is %s" % [id, str(w["boss"])])
		var goals := level.get_tree().get_nodes_in_group("resettable")
		# let it run through a full cycle of its three attacks
		var seen := {}
		for i in 1500:
			await frames(1)
			if boss.mode == Boss.Mode.ATTACK:
				seen[boss._attack] = true
			if seen.size() >= 3:
				break
		check_eq(seen.size(), 3, "%s used all three attacks %s" % [str(w["boss"]), str(seen.keys())])
		var guard := 0
		while boss.mode != Boss.Mode.DEFEATED and guard < 60:
			guard += 1
			boss.take_hit(3, {"element": &"fire", "dir": Vector2.RIGHT})
			await frames(2)
		check_eq(boss.mode, Boss.Mode.DEFEATED, "%s can be beaten" % str(w["boss"]))
		await frames(160)
		check_eq(level.link_active_count("boss"), 1, "beating %s switches the goal on" % str(w["boss"]))
		release_all()
