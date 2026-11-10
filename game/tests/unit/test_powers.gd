extends TestCase
## The twelve attack power-ups, the single power slot, and Flavor Bursts.

func test_twelve_powers_load_with_art_and_scripts() -> void:
	check_eq(FoodDB.foods.size(), 12, "twelve power-ups load")
	for def in FoodDB.all_foods():
		check(def.display_name != "" and def.ability_name != "", "%s has a name and an attack name" % def.id)
		check(FoodDB.icon(def.icon_path) != null, "%s has its icon from the item board" % def.id)
		check(FoodDB.icon(def.demo_path) != null, "%s has its action demo picture" % def.id)
		check(ResourceLoader.exists(def.ability_script), "%s has its attack script" % def.id)
		check(def.cooldown > 0.0 and def.damage > 0, "%s has a cooldown and damage" % def.id)
		check(def.element != &"plain", "%s has an element" % def.id)


func test_every_board_power_is_present() -> void:
	for id: StringName in [&"FIRE_PEPPER", &"FROSTBERRY", &"BUBBLEBERRY", &"HONEYCOMB", &"WATERMELON", &"POPCORN",
			&"NOODLE", &"THUNDER_CORN", &"TOMATO_BOMB", &"GARLIC_DASH", &"LEMON_BEAM", &"COCOA_SHIELD"]:
		check(FoodDB.has_food(id), "%s from the Item & Power-Up board exists" % id)


func test_one_power_at_a_time() -> void:
	var slot := PowerSlot.new()
	check(not slot.has_power(), "starts with no power")
	check_eq(slot.pick_up(&"FIRE_PEPPER"), &"", "first pickup replaces nothing")
	check_eq(slot.power, &"FIRE_PEPPER", "holds Fire Pepper")
	check_eq(slot.pick_up(&"FROSTBERRY"), &"FIRE_PEPPER", "the newest pickup replaces the old power")
	check_eq(slot.power, &"FROSTBERRY", "holds only Frostberry now")
	check_eq(slot.pick_up(&"FROSTBERRY"), &"", "the same power again changes nothing")
	check_eq(slot.pick_up(&"SOUP"), &"", "unknown power refused")
	check_eq(slot.pick_up(&""), &"", "empty id refused")
	check_eq(slot.power, &"FROSTBERRY", "slot unchanged by refused pickups")
	var snap := slot.snapshot()
	slot.clear()
	check(not slot.has_power(), "clear empties the slot")
	slot.restore(snap)
	check_eq(slot.power, &"FROSTBERRY", "restore brings the power back")
	slot.restore({"power": 42})
	check(not slot.has_power(), "restore ignores junk")


func test_flavor_bursts_are_symmetric() -> void:
	var ids := FoodDB.FOOD_IDS
	var names := {}
	var total := 0
	for i in ids.size():
		for j in ids.size():
			if i == j:
				check(FoodDB.resolve(ids[i], ids[j]) == null, "%s with itself is no burst" % ids[i])
				continue
			var ab := FoodDB.resolve(ids[i], ids[j])
			var ba := FoodDB.resolve(ids[j], ids[i])
			check(ab != null and ab == ba, "%s then %s equals %s then %s" % [ids[i], ids[j], ids[j], ids[i]])
			if i < j and ab != null:
				total += 1
				names[ab.display_name] = true
				check(ab.display_name != "", "burst has a name")
	check_eq(total, 66, "66 pairs")
	check_eq(FoodDB.burst_total(), 66, "burst_total agrees")
	check(FoodDB.resolve(&"FIRE_PEPPER", &"SOUP") == null, "unknown food gives no burst")
	check_eq(FoodDB.canonical_pair(&"NOODLE", &"FIRE_PEPPER"), "FIRE_PEPPER|NOODLE", "pair key is sorted")
