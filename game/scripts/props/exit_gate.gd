extends Prop
## The end of a stage: the golden dinner bell. Touch it to finish.
## With `needs=<link id>` it stays asleep until that link is switched on.

var _awake := true
var _sprite: Sprite2D
var _used := false


func _configure() -> void:
	_sprite = Art.standing("props/exit")
	add_child(_sprite)
	var touch := add_touch(Vector2(72, 130), Vector2(0, -65))
	touch.body_entered.connect(_on_touch)
	if p_str("needs") != "":
		_awake = false
		_sprite.modulate = Color(0.6, 0.6, 0.7, 0.8)
		level.register_link(p_str("needs"), self)
	if not Settings.flag("reduced_motion"):
		var t := create_tween().set_loops()
		t.tween_property(_sprite, "rotation", 0.05, 0.9).set_trans(Tween.TRANS_SINE)
		t.tween_property(_sprite, "rotation", -0.05, 0.9).set_trans(Tween.TRANS_SINE)


func on_link(count: int) -> void:
	var was := _awake
	_awake = count >= maxi(p_int("count", 1), 1)
	_sprite.modulate = Color.WHITE if _awake else Color(0.6, 0.6, 0.7, 0.8)
	if _awake and not was:
		Fx.sparkle(level, global_position + Vector2(0, -70), Color(1, 0.9, 0.4), 10)
		Captions.caption("The dinner bell wakes up")


func _on_touch(body: Node) -> void:
	if not is_player(body) or _used or not _awake:
		return
	_used = true
	Fx.sparkle(level, global_position + Vector2(0, -80), Color(1, 0.9, 0.4), 12)
	level.complete_level()
