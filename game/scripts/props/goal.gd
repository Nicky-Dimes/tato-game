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
	var finish_height := maxf(480, level.data.pixel_size().y)
	var touch := add_touch(Vector2(128, finish_height), Vector2(0, -finish_height * 0.5))
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


func _physics_process(_delta: float) -> void:
	# The finish is a line across the route, including a high spring/flap arc.
	# A child should never sail over the flag and get stuck at the right wall.
	if _awake and not _used and is_instance_valid(level.player):
		var at := level.player.global_position
		if at.x >= global_position.x - 40.0 and at.y <= global_position.y + 80.0:
			_on_touch(level.player)


func _on_touch(body: Node) -> void:
	if not is_player(body) or _used or not _awake:
		return
	_used = true
	Fx.sparkle(level, global_position + Vector2(0, -90), Color(1, 0.9, 0.4), 12)
	level.complete_level()
