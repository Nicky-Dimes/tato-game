extends Prop
## A friendly character. `npc mimi talk=<dialogue id>`. Talk with the
## interact button. `after=<flag>` hides them until that story flag is set,
## `until=<flag>` hides them once it is set.

var who := "mimi"
var _sprite: Sprite2D
var _bubble: Sprite2D


func _configure() -> void:
	who = arg(0, "mimi")
	_sprite = Art.standing("npcs/" + who)
	add_child(_sprite)
	_bubble = Art.centered("ui/talk")
	_bubble.position = Vector2(0, -120)
	_bubble.visible = false
	add_child(_bubble)
	add_sense(Vector2(110, 120), Vector2(0, -60))
	z_index = 1
	if p_str("after") != "" and not GameState.has_flag(p_str("after")):
		visible = false
	if p_str("until") != "" and GameState.has_flag(p_str("until")):
		visible = false
	if not Settings.flag("reduced_motion"):
		var t := create_tween().set_loops()
		t.tween_property(_sprite, "scale", Vector2(0.5, 0.515), 0.9).set_trans(Tween.TRANS_SINE)
		t.tween_property(_sprite, "scale", Vector2(0.5, 0.5), 0.9).set_trans(Tween.TRANS_SINE)


func can_interact(_player: Tato) -> bool:
	return visible and talk_id() != ""


func prompt() -> String:
	return "Talk to %s" % Story.speaker_name(who)


func talk_id() -> String:
	return Story.pick_dialogue(p_str("talk", who))


func interact(player: Tato) -> void:
	_sprite.flip_h = player.global_position.x < global_position.x
	level.say(talk_id())


func _process(_delta: float) -> void:
	if level == null or level.player == null:
		return
	_bubble.visible = visible and level.player.interact_target == self and not level.dialogue_open()
