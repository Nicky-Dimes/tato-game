class_name AbilityRunner
extends Node
## Runs Tato's snack powers: pays the Honk Charge, starts the strategy,
## counts its time and cooldown down, and tells the rest of the game with
## signals (stages and UI never reach into the player).

signal ability_started(def: Resource)
signal ability_resolved(def: Resource)
signal ability_ended(def: Resource)
signal ability_denied(def: Resource, reason: String)

var player: Tato
var current: AbilityStrategy
var cooldowns: Dictionary = {}      # id -> seconds left
var bonus_time: Dictionary = {}     # food id -> extra seconds on its next use (from blends)
var _scripts: Dictionary = {}


func is_active() -> bool:
	return current != null


func active_def() -> Resource:
	return current.def if current else null


func active_id() -> StringName:
	return current.def.get("id") if current else &""


func overrides_movement() -> bool:
	return current != null and current.overrides_movement()


func time_fraction() -> float:
	if current == null or current.kind() != AbilityStrategy.KIND_TOGGLE:
		return 0.0
	var total := float(current.def.get("duration")) * Settings.timer_factor()
	return clampf(current.time_left / maxf(total, 0.01), 0.0, 1.0)


## Honk button / fusion button. Returns true when something happened.
func try_activate(def: Resource) -> bool:
	if def == null or player == null:
		return false
	var id: StringName = def.get("id")
	if current != null and current.def == def:
		current.button_pressed_again()
		return true
	if float(cooldowns.get(id, 0.0)) > 0.0:
		return false
	var script := _load_script(str(def.get("ability_script")))
	if script == null:
		ability_denied.emit(def, "missing")
		return false
	var strat: AbilityStrategy = script.new()
	strat.def = def
	strat.player = player
	strat.runner = self
	if not strat.can_start():
		ability_denied.emit(def, "blocked")
		return false
	var cost := float(def.get("charge_cost"))
	if not GameState.can_spend(cost):
		ability_denied.emit(def, "charge")
		return false
	if current != null:
		end_ability(current)
	GameState.spend_charge(cost)
	current = strat
	var duration := float(def.get("duration"))
	if strat.kind() == AbilityStrategy.KIND_TOGGLE:
		duration *= Settings.timer_factor()
		duration += float(bonus_time.get(id, 0.0))
		bonus_time.erase(id)
	strat.time_left = duration
	cooldowns[id] = float(def.get("cooldown"))
	ability_started.emit(def)
	strat.start()
	if strat.kind() == AbilityStrategy.KIND_INSTANT:
		ability_resolved.emit(def)
	return true


func button_released() -> void:
	if current != null and current.kind() == AbilityStrategy.KIND_CHARGE:
		current.button_released()


func tick(delta: float) -> void:
	for id: StringName in cooldowns.keys():
		var left := float(cooldowns[id]) - delta
		if left <= 0.0:
			cooldowns.erase(id)
		else:
			cooldowns[id] = left
	if current == null:
		return
	var strat := current
	strat.elapsed += delta
	strat.tick(delta)
	if current != strat:
		return
	if strat.kind() != AbilityStrategy.KIND_CHARGE:
		strat.time_left -= delta
		if strat.time_left <= 0.0:
			end_ability(strat)


func end_ability(strat: AbilityStrategy) -> void:
	if strat == null or strat.finished:
		return
	strat.finished = true
	strat.stop()
	if current == strat:
		current = null
	ability_ended.emit(strat.def)


## Hurt, respawn, cutscene: drop whatever is running.
func cancel() -> void:
	if current != null:
		end_ability(current)


func add_bonus_time(food_id: StringName, seconds: float) -> void:
	bonus_time[food_id] = minf(float(bonus_time.get(food_id, 0.0)) + seconds, 4.0)


func _load_script(path: String) -> GDScript:
	if _scripts.has(path):
		return _scripts[path]
	var script: GDScript = null
	if path != "" and ResourceLoader.exists(path):
		script = load(path) as GDScript
	_scripts[path] = script
	return script
