extends Prop
## A locked block. Walk into it with a key and it opens (the key is used up).
## `h=2` makes it two cells tall.

var open := false
var _body: StaticBody2D
var _art: Node2D
var _touch: Area2D


func _configure() -> void:
	var h := maxi(p_int("h", 2), 1)
	var size := Vector2(60, 64 * h)
	_body = add_solid(size, Vector2(0, -size.y * 0.5))
	_art = Node2D.new()
	add_child(_art)
	for i in h:
		var piece := Art.sized(WorldKit.art(level.theme, "block2"), 64.0)
		piece.position = Vector2(0, -i * 64.0)
		piece.modulate = Color(1.0, 0.9, 0.6)
		_art.add_child(piece)
	var key := Art.icon("items/key", 38.0)
	key.position = Vector2(0, -size.y * 0.5)
	_art.add_child(key)
	_touch = add_touch(size + Vector2(26, 0), Vector2(0, -size.y * 0.5))


func _physics_process(_delta: float) -> void:
	if open:
		return
	for body in _touch.get_overlapping_bodies():
		if body is Tato and GameState.use_key():
			open = true
			_body.collision_layer = 0
			AudioService.play("unlock")
			Captions.caption("The lock clicks open")
			Fx.sparkle(level, global_position + Vector2(0, -60), Color(1, 0.9, 0.4), 8)
			var t := create_tween()
			t.tween_property(_art, "modulate:a", 0.0, 0.3)
			t.parallel().tween_property(_art, "position:y", -40.0, 0.3)
