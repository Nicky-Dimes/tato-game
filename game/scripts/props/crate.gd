extends Prop
## A fragile crate. Blocks the way until something heavy smashes it
## (Melon Roll, Snowball Express, a Pop Bounce from above).
## `tough` crates only break for the big snowball.

var broken := false
var _body: StaticBody2D
var _sprite: Sprite2D


func _configure() -> void:
	_sprite = Art.standing("props/crate_tough" if p_flag("tough") else "props/crate")
	add_child(_sprite)
	_body = add_solid(Vector2(60, 60), Vector2(0, -30), Layers.WORLD | Layers.INTERACT)
	add_to_group("resettable")


func on_effect(tag: StringName, info: Dictionary) -> bool:
	if broken or tag != &"impact":
		return false
	if p_flag("tough") and not bool(info.get("big", false)):
		_shake()
		return false
	smash()
	return true


func smash() -> void:
	broken = true
	_body.collision_layer = 0
	_sprite.visible = false
	AudioService.play("crate_break")
	Fx.burst(level, global_position + Vector2(0, -30), "crumbs", Color("d9a066"), 8, {"spread": 60.0, "life": 0.6, "size": 12.0})
	Fx.puff(level, global_position + Vector2(0, -20), Color(1, 1, 1, 0.8), 5)
	level.shake(4.0)
	Captions.caption("Crash! The crate breaks")


func _shake() -> void:
	var t := create_tween()
	t.tween_property(_sprite, "position:x", 5.0, 0.04)
	t.tween_property(_sprite, "position:x", -5.0, 0.06)
	t.tween_property(_sprite, "position:x", 0.0, 0.05)
	AudioService.play("thud", -6.0)


func reset_puzzle() -> void:
	if broken and not p_flag("keep"):
		broken = false
		_body.collision_layer = Layers.WORLD | Layers.INTERACT
		_sprite.visible = true
