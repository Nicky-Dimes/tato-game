extends Prop
## A listening flower. If it hears Tato (a honk, running feet, a heavy
## landing) within `r` cells it startles: its link switches on for a few
## seconds (use it to shut a gate with `invert`, or to call a breeze).
## Tiptoeing with Moonmint is silent, and a hush-honk sends it to sleep.

var alarmed := 0.0
var asleep := 0.0
var _sprite: Sprite2D
var _radius := 256.0


func _configure() -> void:
	_sprite = Art.standing("props/ear_flower")
	add_child(_sprite)
	_radius = p_float("r", 4.0) * Layers.TILE
	add_sense(Vector2(70, 100), Vector2(0, -50))
	add_to_group("resettable")
	add_to_group("listener")


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"quiet":
		asleep = p_float("sleep", 9.0) * Settings.timer_factor()
		if alarmed > 0.0:
			_calm()
		_sprite.modulate = Color(0.75, 0.8, 1.0)
		Captions.caption("The listening flower dozes off")
		return true
	return false


func _physics_process(delta: float) -> void:
	if asleep > 0.0:
		asleep -= delta
		if asleep <= 0.0:
			_sprite.modulate = Color.WHITE
		return
	var p := level.player
	if p != null and not p.is_quiet() and p.noise > 0.42 and p.global_position.distance_to(global_position) < _radius:
		if alarmed <= 0.0:
			AudioService.play("alarm")
			Captions.caption("! The listening flower heard that")
			_sprite.modulate = Color(1.0, 0.7, 0.7)
			Fx.float_text(level, global_position + Vector2(0, -110), "!", UITheme.RED)
			level.trigger(p_str("opens"), true, self)
		alarmed = p_float("t", 3.0)
	elif alarmed > 0.0:
		alarmed -= delta
		if alarmed <= 0.0:
			_calm()


func _calm() -> void:
	alarmed = 0.0
	_sprite.modulate = Color.WHITE
	level.trigger(p_str("opens"), false, self)


func reset_puzzle() -> void:
	asleep = 0.0
	if alarmed > 0.0:
		_calm()


func _draw() -> void:
	# a soft ring shows how far it can hear (information is never sound-only)
	if asleep > 0.0:
		return
	draw_arc(Vector2(0, -40), _radius, 0.0, TAU, 48, Color(1, 1, 1, 0.12), 3.0, true)
