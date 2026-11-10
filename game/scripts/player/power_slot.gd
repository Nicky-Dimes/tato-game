class_name PowerSlot
extends RefCounted
## Tato's single power-up slot. One active power at a time: the newest
## pickup replaces the current one.

signal changed(power: StringName, previous: StringName)

var power: StringName = &""


func has_power() -> bool:
	return power != &""


func definition() -> FoodDefinition:
	return FoodDB.food(power)


## Returns the power that was replaced ("" if the slot was empty or the
## same power was picked up again). Unknown ids are refused.
func pick_up(id: StringName) -> StringName:
	if id == &"" or not FoodDB.has_food(id):
		return &""
	var previous := power
	if previous == id:
		return &""
	power = id
	changed.emit(power, previous)
	return previous


func clear() -> void:
	if power == &"":
		return
	var previous := power
	power = &""
	changed.emit(power, previous)


func snapshot() -> Dictionary:
	return {"power": String(power)}


func restore(snap: Dictionary) -> void:
	var id := StringName(str(snap.get("power", "")))
	var previous := power
	power = id if FoodDB.has_food(id) else &""
	if power != previous:
		changed.emit(power, previous)
