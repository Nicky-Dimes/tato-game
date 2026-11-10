class_name AbilityStrategy
extends RefCounted
## Base class for every snack power and fusion. One small script per power
## overrides the hooks below; the AbilityRunner handles cost, cooldown,
## timing and the signals the HUD and stages listen to.

const KIND_INSTANT := "instant"   # fires once, short pose
const KIND_TOGGLE := "toggle"     # stays on until its time runs out or the button is pressed again
const KIND_CHARGE := "charge"     # hold to charge, fires on release

var def: Resource                 # FoodDefinition or RecipeDefinition
var player: Tato
var runner: AbilityRunner
var time_left := 0.0
var elapsed := 0.0
var finished := false


func kind() -> String:
	return KIND_INSTANT


## Return false to refuse activation (nothing is spent).
func can_start() -> bool:
	return true


func start() -> void:
	pass


## Called every physics frame while active (before movement).
func tick(_delta: float) -> void:
	pass


## True when this power fully replaces Tato's normal movement this frame.
func overrides_movement() -> bool:
	return false


func move(_delta: float) -> void:
	pass


## Honk button pressed while this power is running.
func button_pressed_again() -> void:
	finish()


func button_released() -> void:
	pass


## Jump pressed while this power overrides movement. Return true if used.
func jump_pressed() -> bool:
	return false


## Always called exactly once when the power ends, however it ends.
func stop() -> void:
	pass


## Animation hint for TatoVisual ("" = let normal movement decide).
func anim() -> String:
	return ""


## Lets a power shrug off thorns etc. (none do by default).
func blocks_hurt() -> bool:
	return false


func finish() -> void:
	if runner:
		runner.end_ability(self)


# ---- helpers shared by power scripts --------------------------------------

func color() -> Color:
	return def.get("color") if def else Color.WHITE


func accent() -> Color:
	return def.get("accent") if def else Color.WHITE


func damage() -> int:
	return int(def.get("damage")) if def else 1


func element() -> StringName:
	return def.get("element") if def else &"plain"


func world() -> Node:
	return player.get_parent() if player else null


## One shot from Tato's beak. `vel` is for facing right; it is mirrored for left.
func shoot(vel: Vector2, opts: Dictionary = {}) -> Projectile:
	var o := opts.duplicate()
	o["source"] = player
	if not o.has("damage"):
		o["damage"] = damage()
	if not o.has("element"):
		o["element"] = element()
	if not o.has("color"):
		o["color"] = color()
	return Projectile.fire(world(), player.muzzle(), Vector2(vel.x * player.facing, vel.y), o)
