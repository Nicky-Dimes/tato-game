extends Prop
## A floor button. On while something stands on it.
##   opens=<id>   link to switch
##   heavy        only a heavy thing (Melon Roll, Snowball, a crate) presses it
##   stay         stays down once pressed

var pressed := false
var _area: Area2D
var _sprite: Sprite2D
var _latched := false


func _configure() -> void:
	_sprite = Art.standing("props/plate_heavy" if p_flag("heavy") else "props/plate")
	add_child(_sprite)
	_area = add_touch(Vector2(56, 22), Vector2(0, -10), Layers.PLAYER | Layers.PROP)
	add_to_group("resettable")


func _physics_process(_delta: float) -> void:
	var down := _latched
	if not down:
		for body in _area.get_overlapping_bodies():
			if _counts(body):
				down = true
				break
	if down != pressed:
		pressed = down
		_sprite.offset.y = -_sprite.texture.get_height() + (12.0 if pressed else 0.0) if _sprite.texture else 0.0
		AudioService.play("plate_down" if pressed else "plate_up", -4.0)
		if pressed:
			Captions.caption("Click! A button is pressed")
			if p_flag("stay"):
				_latched = true
		level.trigger(p_str("opens"), pressed, self)


func _counts(body: Node) -> bool:
	if not p_flag("heavy"):
		return body is Tato or body.is_in_group("weight")
	if body.is_in_group("weight"):
		return true
	if body is Tato:
		var def: Resource = (body as Tato).runner.active_def()
		if def != null and (def.get("tags") as PackedStringArray).has("weight"):
			return true
		# a normal waddle makes the big button wiggle so the hint is visible
		return false
	return false


func reset_puzzle() -> void:
	_latched = false
