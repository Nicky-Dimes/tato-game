class_name FoodInventory
extends RefCounted
## Tato's two Flavor Pockets (A and B) plus which one the honk button uses.
## The active marker can also sit on NONE so a plain honk is always available.

signal slot_changed(slot: int, food: StringName)
signal active_changed(active: int)
signal recipe_available(recipe: RecipeDefinition)

const SLOT_A := 0
const SLOT_B := 1
const NONE := -1

var slots: Array[StringName] = [&"", &""]
var active: int = NONE


func food_in(slot: int) -> StringName:
	if slot < 0 or slot > 1:
		return &""
	return slots[slot]


func active_food() -> StringName:
	return food_in(active)


func is_empty() -> bool:
	return slots[0] == &"" and slots[1] == &""


func is_full() -> bool:
	return slots[0] != &"" and slots[1] != &""


func has(food: StringName) -> bool:
	return food != &"" and (slots[0] == food or slots[1] == food)


func slot_of(food: StringName) -> int:
	if food == &"":
		return NONE
	if slots[0] == food:
		return SLOT_A
	if slots[1] == food:
		return SLOT_B
	return NONE


## Puts a food into a free pocket. Returns the slot used, the slot it was
## already in (duplicates never take a second pocket), or NONE when both
## pockets are full and the player has to choose which one to replace.
func add(food: StringName) -> int:
	if food == &"" or not FoodDB.has_food(food):
		return NONE
	var existing := slot_of(food)
	if existing != NONE:
		set_active(existing)
		return existing
	for i in 2:
		if slots[i] == &"":
			_set_slot(i, food)
			set_active(i)
			return i
	return NONE


## Replaces a pocket on purpose (the replace prompt). Null food is refused:
## a pocket is only ever emptied through clear().
func replace(slot: int, food: StringName) -> bool:
	if slot < 0 or slot > 1 or food == &"" or not FoodDB.has_food(food):
		return false
	var other := 1 - slot
	if slots[other] == food:
		# already carried in the other pocket: nothing to replace
		set_active(other)
		return false
	_set_slot(slot, food)
	set_active(slot)
	return true


func clear_slot(slot: int) -> void:
	if slot < 0 or slot > 1 or slots[slot] == &"":
		return
	_set_slot(slot, &"")
	if active == slot:
		set_active(NONE)


func clear() -> void:
	clear_slot(0)
	clear_slot(1)
	set_active(NONE)


## Cycles A -> B -> plain honk -> A, skipping empty pockets.
func cycle_active() -> int:
	var order: Array[int] = [SLOT_A, SLOT_B, NONE]
	var idx := order.find(active)
	for step in range(1, 4):
		var cand: int = order[(idx + step) % 3]
		if cand == NONE or slots[cand] != &"":
			if cand != active:
				set_active(cand)
			return active
	return active


func set_active(slot: int) -> void:
	if slot != NONE and (slot < 0 or slot > 1 or slots[slot] == &""):
		slot = NONE
	if active == slot:
		return
	active = slot
	active_changed.emit(active)


func can_fuse() -> bool:
	return is_full() and slots[0] != slots[1]


func current_recipe() -> RecipeDefinition:
	if not can_fuse():
		return null
	return FoodDB.resolve(slots[0], slots[1])


func snapshot() -> Dictionary:
	return {"a": String(slots[0]), "b": String(slots[1]), "active": active}


func restore(snap: Dictionary) -> void:
	_set_slot(0, StringName(str(snap.get("a", ""))) if FoodDB.has_food(StringName(str(snap.get("a", "")))) else &"")
	_set_slot(1, StringName(str(snap.get("b", ""))) if FoodDB.has_food(StringName(str(snap.get("b", "")))) else &"")
	active = NONE
	set_active(int(snap.get("active", NONE)))
	active_changed.emit(active)


func _set_slot(slot: int, food: StringName) -> void:
	if slots[slot] == food:
		return
	slots[slot] = food
	slot_changed.emit(slot, food)
	if can_fuse():
		recipe_available.emit(current_recipe())
	else:
		recipe_available.emit(null)
