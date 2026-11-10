extends TestCase
## Every stage file: it parses, has what a stage needs, and between them the
## stages use every item, creature, power and boss from the boards.

const PICKUPS := ["gem", "orb", "flower", "clover", "feather", "leaf", "candy", "crystal", "rainbow_star", "moon",
	"sun", "cherry", "grape", "banana", "corn", "mushroom", "egg", "time", "magnet", "wings"]


func test_campaign_has_thirty_stages() -> void:
	check_eq(LevelDB.all_stage_ids().size(), 30, "six worlds of five stages")
	for id in LevelDB.all_stage_ids():
		check(LevelDB.has_level(id), "stage file exists for %s" % id)
	check(LevelDB.has_level("HUB") and LevelDB.has_level("TRIAL"), "Home Nest and trial room exist")


func test_every_stage_is_well_formed() -> void:
	for id: String in LevelDB.all_stage_ids() + ["HUB", "TRIAL", "TEST"] as Array[String]:
		var d := LevelData.parse(LevelDB.load_text(id), id)
		check_eq(d.errors.size(), 0, "%s parses cleanly %s" % [id, str(d.errors)])
		check_eq(d.entities_of("spawn").size(), 1, "%s has one start" % id)
		check(d.height >= 14, "%s is tall enough for tablets" % id)
		for e in d.entities:
			check(EntityFactory.knows(e["type"]), "%s: '%s' is a known thing" % [id, e["type"]])
			if e["type"] == "sign":
				check(Story.has_sign(str(e["params"].get("text", ""))), "%s: sign text '%s' exists" % [id, str(e["params"].get("text", ""))])
			if e["type"] == "power":
				check(FoodDB.has_food(StringName(str((e["args"] as Array)[0]))), "%s: bowl holds a real power" % id)
		if not LevelDB.stage(id).is_empty() and LevelDB.stage_kind(id) != "hub" and id != "TEST":
			check_eq(d.entities_of("goal").size(), 1, "%s has one goal flag" % id)
			check_eq(d.entities_of("note").size(), 3, "%s has exactly three Treasure Notes" % id)
			check(d.entities_of("checkpoint").size() >= 1 or LevelDB.stage_kind(id) == "boss", "%s has a checkpoint" % id)
			if LevelDB.stage_kind(id) == "boss":
				check_eq(d.entities_of("boss").size(), 1, "%s has its boss" % id)
			else:
				check_eq(d.entities_of("star").size(), 1, "%s has one hidden Star" % id)
				check(d.entities_of("power").size() >= 1, "%s has a food bowl" % id)


func test_every_item_on_the_boards_is_used() -> void:
	var pickups := {}
	var creatures := {}
	var powers := {}
	var types := {}
	var bosses := {}
	var treat_worlds := {}
	for id in LevelDB.all_stage_ids():
		var d := LevelData.parse(LevelDB.load_text(id), id)
		for e in d.entities:
			types[e["type"]] = true
			if e["type"] == "pickup":
				pickups[str((e["args"] as Array)[0])] = true
				if str((e["args"] as Array)[0]) == "treat":
					treat_worlds[str(LevelDB.world_of(id).get("theme", ""))] = true
			elif e["type"] == "power":
				powers[str((e["args"] as Array)[0])] = true
			elif e["type"] == "boss":
				bosses[str((e["args"] as Array)[0])] = true
			elif EnemyData.has(e["type"]):
				creatures[e["type"]] = true
	for p: String in PICKUPS:
		check(pickups.has(p), "level pickup '%s' is placed in a stage" % p)
	for theme: String in WorldKit.TREAT_NAMES.keys():
		check(treat_worlds.has(theme), "the %s world's own treat (%s) is placed in its stages" % [theme, WorldKit.TREAT_NAMES[theme]])
		check(Art.has(WorldKit.art(theme, "treat")), "drawing for the %s treat" % theme)
	for kind: String in EnemyData.kinds():
		check(creatures.has(kind), "creature '%s' appears in a stage" % kind)
	for id2 in FoodDB.FOOD_IDS:
		check(powers.has(String(id2)), "power '%s' has a food bowl in a stage" % id2)
	for b: String in Boss.DATA.keys():
		check(bosses.has(b), "boss '%s' has its arena" % b)
	for t: String in ["coin", "heart", "star", "note", "key", "lock", "checkpoint", "goal", "spring", "crate", "qblock",
			"button", "platform", "bridge", "conveyor", "wind", "shroom", "faller", "icicle", "spikes", "spiky", "roller",
			"saw", "drip", "mace", "torch", "hive", "cracked", "sign", "decor"]:
		check(types.has(t), "'%s' is used in a stage" % t)


func test_art_exists_for_everything() -> void:
	for kind: String in EnemyData.kinds():
		check(Art.has("enemies/" + kind), "drawing for creature %s" % kind)
	for b: String in Boss.DATA.keys():
		check(Art.has("bosses/" + b), "drawing for boss %s" % b)
	for p: String in PICKUPS:
		check(Art.has("pickups/" + p), "drawing for pickup %s" % p)
	for item: String in ["coin", "star", "heart", "checkpoint", "key", "treasure_note", "spring_pad", "crate",
			"question_block", "move_button", "bowl_noodle", "bowl_fruit", "bowl_corn", "extra_heal"]:
		check(Art.has("items/" + item), "drawing for item %s" % item)
	for ui: String in ["btn_move", "btn_jump", "btn_attack"]:
		check(Art.has("ui/" + ui), "touch button drawing %s" % ui)
	for big: String in ["front", "side", "cheer", "defeat", "respawn"]:
		check(Art.has("tato_big/" + big), "big Tato drawing %s" % big)
	for w in LevelDB.WORLDS:
		var theme: String = w["theme"]
		check(Art.has("cards/world_" + theme) and Art.has("cards/scene_" + theme), "world pictures for %s" % theme)
		for part: String in ["block", "block2", "plat", "flag", "sign", "bowl", "spikes"]:
			check(Art.has(WorldKit.art(theme, part)), "%s kit has '%s'" % [theme, part])
		check(ResourceLoader.exists("res://assets/tiles/tiles_%s.svg" % theme), "terrain tiles for %s" % theme)
	for frame: String in ["walk_0", "run_0", "jump_air", "jump_land", "cheer"]:
		check(TatoVisual.frame_texture(frame) != null, "Tato frame %s" % frame)
