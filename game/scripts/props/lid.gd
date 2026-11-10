extends Prop
## A pot lid on a steam pipe. A puff of rising steam (Steam Lift) pops it up
## and holds its link on for a while: `lid opens=<id> t=6`.

var up := false
var _timer := 0.0
var _sprite: Sprite2D


func _configure() -> void:
	add_child(Art.standing("props/pot"))
	_sprite = Art.standing("props/lid")
	_sprite.position = Vector2(0, -52)
	add_child(_sprite)
	add_sense(Vector2(80, 90), Vector2(0, -45))
	add_to_group("resettable")


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag != &"lift":
		return false
	_timer = p_float("t", 6.0) * Settings.timer_factor()
	if not up:
		up = true
		AudioService.play("steam")
		Captions.caption("Steam pops the lid up")
		create_tween().tween_property(_sprite, "position:y", -96.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		level.trigger(p_str("opens"), true, self)
	return true


func _physics_process(delta: float) -> void:
	if up and p_float("t", 6.0) > 0.0:
		_timer -= delta
		if _timer <= 0.0:
			reset_puzzle()
			Captions.caption("The lid clatters back down")


func reset_puzzle() -> void:
	if up:
		up = false
		_sprite.position.y = -52.0
		level.trigger(p_str("opens"), false, self)
