extends Prop
## Move Platform Button: step on it (or bop it) and its link switches.
##   opens=<id>    the platforms / bridges / gates it drives
##   mode=toggle   (default) each press flips it;  mode=hold  on only while stood on;
##   mode=once     stays on for good

var on := false
var _sprite: Sprite2D
var _area: Area2D
var _was_down := false
var _base := Vector2.ONE


func _configure() -> void:
	_sprite = Art.sized("items/move_button", 62.0)
	_base = _sprite.scale
	add_child(_sprite)
	_area = add_touch(Vector2(54, 26), Vector2(0, -14))
	add_solid(Vector2(60, 18), Vector2(0, -9), Layers.INTERACT)
	add_to_group("hittable")
	add_to_group("resettable")


func take_hit(_damage: int, _info: Dictionary) -> bool:
	if p_str("mode", "toggle") == "hold":
		return false
	_press()
	return true


func _physics_process(_delta: float) -> void:
	var down := false
	for body in _area.get_overlapping_bodies():
		if body is Tato:
			down = true
	var mode := p_str("mode", "toggle")
	if mode == "hold":
		if down != on:
			_switch(down)
	elif down and not _was_down:
		_press()
	_was_down = down
	_sprite.scale = _base * (Vector2(1.0, 0.86) if down else Vector2.ONE)


func _press() -> void:
	var mode := p_str("mode", "toggle")
	if mode == "once" and on:
		return
	_switch(true if mode == "once" else not on)


func _switch(value: bool) -> void:
	on = value
	_sprite.modulate = Color(0.8, 1.0, 0.8) if on else Color.WHITE
	AudioService.play("button")
	Captions.caption("Click! Something moves")
	level.trigger(p_str("opens"), on, self)


func reset_puzzle() -> void:
	if on and p_str("mode", "toggle") != "once":
		_switch(false)
