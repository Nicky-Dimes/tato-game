extends TestCase
## Food and recipe data: every pair resolves, A+B == B+A, twelve signature
## recipes exist, and every power script is present.

func test_twelve_foods_and_recipes_load() -> void:
	check_eq(FoodDB.foods.size(), 12, "twelve foods load")
	check_eq(FoodDB.recipes.size(), 12, "twelve signature recipes load")
	for def in FoodDB.all_foods():
		check(def.display_name != "", "%s has a name" % def.id)
		check(def.shape_hint != "", "%s has a colour-blind shape hint" % def.id)
		check(def.charge_cost > 0.0, "%s has a cost" % def.id)
		check(def.tags.size() > 0, "%s sends at least one tag" % def.id)


func test_pairs_are_symmetric() -> void:
	var ids := FoodDB.FOOD_IDS
	var named := 0
	var total := 0
	for i in ids.size():
		for j in ids.size():
			if i == j:
				check(FoodDB.resolve(ids[i], ids[j]) == null, "%s with itself is not a recipe" % ids[i])
				continue
			var ab := FoodDB.resolve(ids[i], ids[j])
			var ba := FoodDB.resolve(ids[j], ids[i])
			check(ab != null, "%s + %s resolves to something (never a no-op)" % [ids[i], ids[j]])
			check(ab == ba, "%s + %s equals %s + %s" % [ids[i], ids[j], ids[j], ids[i]])
			if i < j:
				total += 1
				if ab != null and ab.named:
					named += 1
	check_eq(total, 66, "66 unordered pairs")
	check_eq(named, 12, "exactly twelve pairs are signature recipes")


func test_canonical_key_ignores_order() -> void:
	check_eq(FoodDB.canonical_pair(&"PEPPER", &"BUBBLE"), "BUBBLE|PEPPER", "key is sorted")
	check_eq(FoodDB.canonical_pair(&"BUBBLE", &"PEPPER"), "BUBBLE|PEPPER", "key is sorted both ways")
	var rec := FoodDB.resolve(&"PEPPER", &"BUBBLE")
	check(rec != null and rec.id == &"STEAM_LIFT", "Pepper + Bubbleberry is Steam Lift")
	check(FoodDB.resolve_key("BUBBLE|PEPPER") == rec, "resolve_key finds the same recipe")


func test_unknown_food_is_refused() -> void:
	check(FoodDB.resolve(&"PEPPER", &"SOUP") == null, "unknown food gives no recipe")
	check(FoodDB.resolve(&"", &"PEPPER") == null, "empty pocket gives no recipe")


func test_generated_blends_mix_both_foods() -> void:
	var rec := FoodDB.resolve(&"PEPPER", &"NOODLE")
	check(rec != null and not rec.named, "Pepper + Noodle is an experiment blend")
	check(rec.tags.has("heat") and rec.tags.has("reach"), "blend carries both flavours' tags")
	check(rec.display_name != "", "blend has a playful name")
	check(rec.charge_cost > 0.0, "blend has a cost")


func test_every_power_script_exists() -> void:
	for def in FoodDB.all_foods():
		check(ResourceLoader.exists(def.ability_script), "power script exists for %s (%s)" % [def.id, def.ability_script])
	for rec in FoodDB.named_recipes():
		check(ResourceLoader.exists(rec.ability_script), "power script exists for %s (%s)" % [rec.id, rec.ability_script])
	check(ResourceLoader.exists(FoodDB.GENERIC_SCRIPT), "blend script exists")


func test_every_food_has_an_icon() -> void:
	for def in FoodDB.all_foods():
		check(FoodDB.icon(def.icon_path) != null, "icon exists for %s" % def.id)
