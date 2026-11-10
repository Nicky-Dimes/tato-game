extends Prop
## A signpost that shows one short tip while Tato stands near it.
## `text=<id>` looks the words up in data/text/signs.json; tokens such as
## {jump} become the right key, button or touch label.

var _text := ""


func _configure() -> void:
	add_child(Art.sized(WorldKit.art(level.theme, "sign"), 66.0))
	_text = Story.sign_text(p_str("text", arg(0)))
	var touch := add_touch(Vector2(150, 140), Vector2(0, -70))
	touch.body_entered.connect(func(body: Node) -> void:
		if is_player(body):
			level.hud.show_tip(self, _text))
	touch.body_exited.connect(func(body: Node) -> void:
		if is_player(body):
			level.hud.hide_tip(self))
