extends Prop
## The goal flag at the end of a stage. With `needs=<link id>` it sleeps
## until that link is switched on (a boss being beaten, a button ...).

var _awake := true
var _sprite: Sprite2D
var _used := false


func _configure() -> void:
	_sprite = Art.sized(WorldKit.art(level.theme, "flag"), 150.0)
	add_child(_sprite)
	var star := Art.icon("items/star", 46.0)
	star.position = Vector2(0, -176)
	add_child(star)
	bob(star, 6.0, 1.4)
	var touch := add_touch(Vector2(80, 160), Vector2(0, -80))
	touch.body_entered.connect(_on_touch)
	if p_str("needs") != "":
		_awake = false
		visible = false
		level.register_link(p_str("needs"), self)


func on_link(count: int) -> void:
	var was := _awake
	_awake = count >= 1
	visible = _awake
	if _awake and not was:
		Fx.sparkle(level, global_position + Vector2(0, -80), Color(1, 0.9, 0.4), 10)
		Captions.caption("The goal flag appears")


func _on_touch(body: Node) -> void:
	if not is_player(body) or _used or not _awake:
		return
	_used = true
	Fx.sparkle(level, global_position + Vector2(0, -90), Color(1, 0.9, 0.4), 12)
	level.complete_level()
