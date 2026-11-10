extends Prop
## A brazier. Warmth lights it; while lit it switches its link on and (with
## `up=<cells>`) makes a column of warm rising air above it.
##   t=6      burns for t seconds (0 = stays lit)
##   lit      starts lit

var lit := false
var _timer := 0.0
var _flame: Sprite2D
var _draft: Node2D
var _start_lit := false


func _configure() -> void:
	add_child(Art.standing("props/brazier"))
	_flame = Art.standing("props/flame")
	_flame.position = Vector2(0, -38)
	_flame.visible = false
	add_child(_flame)
	add_sense(Vector2(64, 80), Vector2(0, -40))
	add_to_group("resettable")
	var up := p_int("up", 0)
	if up > 0:
		var script: GDScript = load("res://scripts/props/updraft.gd")
		_draft = script.new()
		_draft.call("setup_zone", level, Vector2(-Layers.TILE * 0.5, -56.0 - up * Layers.TILE), Vector2(Layers.TILE, up * Layers.TILE))
		add_child(_draft)
		_draft.call("set_blowing", false)
	_start_lit = p_flag("lit")
	if _start_lit:
		_set_lit(true, false)
	if not Settings.flag("reduced_motion"):
		var t := create_tween().set_loops()
		t.tween_property(_flame, "scale", Vector2(0.54, 0.46), 0.16)
		t.tween_property(_flame, "scale", Vector2(0.46, 0.54), 0.16)


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"heat":
		_timer = p_float("t", 0.0) * Settings.timer_factor()
		if not lit:
			_set_lit(true)
		return true
	if tag == &"cold" and lit:
		_set_lit(false)
		return true
	return false


func _physics_process(delta: float) -> void:
	if lit and p_float("t", 0.0) > 0.0:
		_timer -= delta
		if _timer < 1.5:
			_flame.modulate.a = 0.5 + 0.5 * absf(sin(_timer * 10.0))
		if _timer <= 0.0:
			_set_lit(false)


func _set_lit(value: bool, announce: bool = true) -> void:
	lit = value
	_flame.visible = lit
	_flame.modulate.a = 1.0
	if _draft:
		_draft.call("set_blowing", lit)
	if announce:
		AudioService.play("ignite" if lit else "fizzle")
		Captions.caption("The brazier lights. Warm air rises" if lit and _draft else ("The brazier lights" if lit else "The brazier goes out"))
		if lit:
			Fx.sparkle(level, global_position + Vector2(0, -60), Color(1, 0.6, 0.2), 6)
	level.trigger(p_str("opens"), lit, self)


func reset_puzzle() -> void:
	if lit != _start_lit:
		_set_lit(_start_lit, false)
