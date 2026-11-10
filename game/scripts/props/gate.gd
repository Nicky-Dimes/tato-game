extends Prop
## A barrier that opens when its link (`id=<id>`) is switched on.
##   h=3        height in cells (default 3)
##   needs=2    how many switches must be on at once (default 1)
##   invert     open by default, closes while the link is on

var open := false
var _h := 3
var _body: StaticBody2D
var _art: Node2D
var _want_closed := false


func _configure() -> void:
	_h = maxi(p_int("h", 3), 1)
	var size := Vector2(40, _h * Layers.TILE)
	_body = add_solid(size, Vector2(0, -size.y * 0.5))
	_art = Node2D.new()
	add_child(_art)
	for i in _h:
		var seg := Art.sized(WorldKit.art(level.theme, "block2"), 64.0)
		seg.scale.x *= 0.7
		seg.position = Vector2(0, -i * Layers.TILE)
		_art.add_child(seg)
	on_link(0)


func on_link(count: int) -> void:
	var should_open := count >= maxi(p_int("needs", 1), 1)
	if p_flag("invert"):
		should_open = not should_open
	_apply(should_open)


func _apply(value: bool) -> void:
	if value == open and (_body.collision_layer != 0) == (not open):
		return
	open = value
	var t := create_tween()
	if open:
		_want_closed = false
		_body.collision_layer = 0
		t.tween_property(_art, "position:y", -_h * Layers.TILE * 0.92, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(_art, "modulate:a", 0.25, 0.35)
		if is_inside_tree() and level != null and level.player != null:
			AudioService.play("gate_open")
			Captions.caption("A gate rumbles open")
	else:
		_want_closed = true
		t.tween_property(_art, "position:y", 0.0, 0.25)
		t.parallel().tween_property(_art, "modulate:a", 1.0, 0.25)
		if is_inside_tree() and level != null and level.player != null:
			AudioService.play("gate_close")


func _physics_process(_delta: float) -> void:
	# only become solid again once Tato is out of the doorway
	if _want_closed and level != null and level.player != null:
		var d := level.player.global_position - global_position
		if absf(d.x) > 46.0 or d.y < -_h * Layers.TILE - 4.0 or d.y > 60.0:
			_body.collision_layer = Layers.WORLD
			_want_closed = false
