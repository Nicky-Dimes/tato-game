extends Prop
## Snack station: a checkpoint. Refills Comfort Feathers and is where Tato
## comes back after a "snack break".

var checkpoint_id := ""
var lit := false
var _flag: Sprite2D


func _configure() -> void:
	add_to_group("checkpoint")
	checkpoint_id = "cp_%d_%d" % [cell.x, cell.y]
	add_child(Art.standing("props/station"))
	_flag = Art.standing("props/station_flag")
	_flag.position = Vector2(0, -6)
	_flag.modulate = Color(0.75, 0.75, 0.8)
	add_child(_flag)
	var touch := add_touch(Vector2(70, 120), Vector2(0, -60))
	touch.body_entered.connect(_on_touch)


func _on_touch(body: Node) -> void:
	if not is_player(body) or lit:
		return
	set_lit(true)
	level.activate_checkpoint(self)
	AudioService.play("checkpoint")
	Fx.sparkle(level, global_position + Vector2(0, -70), Color(1, 0.9, 0.4), 8)
	var t := create_tween()
	t.tween_property(_flag, "scale", Vector2(0.62, 0.62), 0.1)
	t.tween_property(_flag, "scale", Vector2(0.5, 0.5), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func set_lit(value: bool) -> void:
	lit = value
	_flag.modulate = Color.WHITE if lit else Color(0.75, 0.75, 0.8)
