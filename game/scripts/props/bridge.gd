extends Prop
## Castle Feast gimmick: a drawbridge. It stands raised (a wall you cannot
## pass) until its link (`id=<id>`) is switched on, then it swings down and
## becomes a bridge `w` cells long. The hinge is the level letter's cell.

var down := false
var _w := 4
var _wall: StaticBody2D
var _deck: StaticBody2D
var _art: Node2D
var _dir := 1.0


func _configure() -> void:
	_w = maxi(p_int("w", 4), 2)
	_dir = -1.0 if p_flag("left") else 1.0
	position = Vector2((cell.x + (0.0 if _dir > 0.0 else 1.0)) * Layers.TILE, (cell.y + 1.0) * Layers.TILE)
	var length := _w * float(Layers.TILE)
	_wall = add_solid(Vector2(18, length), Vector2(_dir * 9, -length * 0.5))
	_deck = add_solid(Vector2(length, 18), Vector2(_dir * length * 0.5, 9), 0)
	_deck.add_to_group("safe_ground")
	_art = Node2D.new()
	add_child(_art)
	for i in _w:
		var plank := Art.icon(WorldKit.art("windy", "bridge"), 64.0)
		plank.position = Vector2(_dir * (i + 0.5) * Layers.TILE, 6)
		_art.add_child(plank)
	_art.rotation = -PI * 0.5 * _dir
	add_to_group("resettable")


func on_link(count: int) -> void:
	_switch(count >= 1)


func _switch(value: bool) -> void:
	if value == down:
		return
	down = value
	_wall.collision_layer = 0 if down else Layers.WORLD
	_deck.collision_layer = Layers.WORLD if down else 0
	var target := 0.0 if down else -PI * 0.5 * _dir
	if is_inside_tree():
		create_tween().tween_property(_art, "rotation", target, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		AudioService.play("gate_open")
		Captions.caption("The drawbridge comes down" if down else "The drawbridge goes up")
	else:
		_art.rotation = target
