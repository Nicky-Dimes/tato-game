extends TestCase
## The two Flavor Pockets.

func test_add_fills_a_then_b() -> void:
	var inv := FoodInventory.new()
	check(inv.is_empty(), "starts empty")
	check_eq(inv.add(&"PEPPER"), 0, "first snack goes to pocket A")
	check_eq(inv.add(&"BUBBLE"), 1, "second snack goes to pocket B")
	check(inv.is_full(), "both pockets full")
	check_eq(inv.active, 1, "newest snack is the active pocket")


func test_duplicate_does_not_take_a_second_pocket() -> void:
	var inv := FoodInventory.new()
	inv.add(&"PEPPER")
	check_eq(inv.add(&"PEPPER"), 0, "same snack again returns the pocket it is in")
	check_eq(inv.food_in(1), &"", "pocket B still empty")
	check(not inv.can_fuse(), "one snack twice cannot fuse")


func test_full_pockets_ask_instead_of_replacing() -> void:
	var inv := FoodInventory.new()
	inv.add(&"PEPPER")
	inv.add(&"BUBBLE")
	check_eq(inv.add(&"HONEY"), FoodInventory.NONE, "third snack is not auto-equipped")
	check_eq(inv.food_in(0), &"PEPPER", "pocket A untouched")
	check_eq(inv.food_in(1), &"BUBBLE", "pocket B untouched")
	check(inv.replace(0, &"HONEY"), "explicit replace works")
	check_eq(inv.food_in(0), &"HONEY", "pocket A now honey")


func test_null_and_unknown_are_refused() -> void:
	var inv := FoodInventory.new()
	check_eq(inv.add(&""), FoodInventory.NONE, "empty id refused")
	check_eq(inv.add(&"SOUP"), FoodInventory.NONE, "unknown id refused")
	inv.add(&"PEPPER")
	check(not inv.replace(0, &""), "replace with nothing refused")
	check_eq(inv.food_in(0), &"PEPPER", "pocket kept its snack")
	check(not inv.replace(5, &"BUBBLE"), "bad slot refused")


func test_replace_never_makes_two_of_the_same() -> void:
	var inv := FoodInventory.new()
	inv.add(&"PEPPER")
	inv.add(&"BUBBLE")
	check(not inv.replace(0, &"BUBBLE"), "cannot replace A with what B already holds")
	check_eq(inv.food_in(0), &"PEPPER", "A unchanged")


func test_cycle_includes_plain_honk() -> void:
	var inv := FoodInventory.new()
	check_eq(inv.cycle_active(), FoodInventory.NONE, "nothing to cycle when empty")
	inv.add(&"PEPPER")
	inv.add(&"BUBBLE")
	inv.set_active(0)
	check_eq(inv.cycle_active(), 1, "A -> B")
	check_eq(inv.cycle_active(), FoodInventory.NONE, "B -> plain honk")
	check_eq(inv.cycle_active(), 0, "plain honk -> A")
	inv.clear_slot(1)
	inv.set_active(0)
	check_eq(inv.cycle_active(), FoodInventory.NONE, "with B empty: A -> plain honk")


func test_recipe_signal_and_snapshot() -> void:
	var inv := FoodInventory.new()
	var seen: Array = []
	inv.recipe_available.connect(func(r: RecipeDefinition) -> void: seen.append(r))
	inv.add(&"BUBBLE")
	inv.add(&"PEPPER")
	check(seen.size() > 0 and seen[seen.size() - 1] != null, "recipe_available fires when two snacks pair up")
	check_eq(inv.current_recipe().id, &"STEAM_LIFT", "pair resolves in either pocket order")
	var snap := inv.snapshot()
	inv.clear()
	check(inv.is_empty(), "clear empties both pockets")
	inv.restore(snap)
	check_eq(inv.food_in(0), &"BUBBLE", "restore brings back A")
	check_eq(inv.food_in(1), &"PEPPER", "restore brings back B")
	inv.restore({"a": "SOUP", "b": 12, "active": 9})
	check(inv.is_empty(), "restore ignores junk values")
