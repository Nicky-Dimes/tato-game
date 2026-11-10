extends Prop
## A lever. Flip it with the interact button, or from far away with a
## Noodle Neck (reach). `opens=<id>`; `once` locks after the first flip.

var on := false
var _sprite: Sprite2D
var _start := false


func _configure() -> void:
	_sprite = Art.standing("props/lever")
	add_child(_sprite)
	add_sense(Vector2(70, 80), Vector2(0, -40))
	add_to_group("resettable")
	add_to_group("reach_target")
	_start = p_flag("on")
	if _start:
		flip(false)


func can_interact(_player: Tato) -> bool:
	return not (p_flag("once") and on) and not p_flag("far")


func prompt() -> String:
	return "Pull lever"


func interact(_player: Tato) -> void:
	flip()


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"reach":
		if p_flag("once") and on:
			return false
		flip()
		return true
	return false


func flip(announce: bool = true) -> void:
	on = not on
	_sprite.flip_h = on
	if announce:
		AudioService.play("lever")
		Captions.caption("Clunk! A lever flips")
	level.trigger(p_str("opens"), on, self)


func reset_puzzle() -> void:
	if on != _start and not p_flag("once"):
		flip(false)
