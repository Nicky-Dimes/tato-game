extends Prop
## Checkpoint bell: touch it and Tato comes back here if he runs out of
## hearts. It also saves the game and refills his hearts.

var checkpoint_id := ""
var lit := false
var _bell: Sprite2D


func _configure() -> void:
	add_to_group("checkpoint")
	checkpoint_id = "cp_%d_%d" % [cell.x, cell.y]
	var flag := Art.sized(WorldKit.art(level.theme, "flag"), 74.0)
	flag.position = Vector2(-26, 0)
	flag.modulate = Color(0.8, 0.8, 0.85)
	flag.name = "Flag"
	add_child(flag)
	_bell = Art.sized("items/checkpoint", 58.0)
	_bell.position = Vector2(24, 0)
	_bell.modulate = Color(0.78, 0.78, 0.85)
	add_child(_bell)
	var touch := add_touch(Vector2(90, 130), Vector2(0, -65))
	touch.body_entered.connect(_on_touch)


func _on_touch(body: Node) -> void:
	if not is_player(body) or lit:
		return
	set_lit(true)
	level.activate_checkpoint(self)
	AudioService.play("checkpoint")
	Fx.sparkle(level, global_position + Vector2(0, -70), Color(1, 0.9, 0.4), 8)
	if not Settings.flag("reduced_motion"):
		var t := create_tween()
		t.tween_property(_bell, "rotation", 0.3, 0.08)
		t.tween_property(_bell, "rotation", -0.22, 0.14)
		t.tween_property(_bell, "rotation", 0.1, 0.14)
		t.tween_property(_bell, "rotation", 0.0, 0.14)


func set_lit(value: bool) -> void:
	lit = value
	var m := Color.WHITE if lit else Color(0.78, 0.78, 0.85)
	_bell.modulate = m
	(get_node("Flag") as Sprite2D).modulate = m
