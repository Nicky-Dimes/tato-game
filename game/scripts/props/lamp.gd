extends Prop
## A sun lamp: lights up when a beam of light (or a flash right next to it)
## reaches it. `opens=<id>`; mode=once (default) / timed (t=6).

var lit := false
var _timer := 0.0
var _sprite: Sprite2D
var _glow: Sprite2D


func _configure() -> void:
	position = LevelData.cell_center(cell)
	_sprite = Art.centered("props/lamp")
	add_child(_sprite)
	_glow = Art.centered("props/lamp_lit")
	_glow.visible = false
	add_child(_glow)
	var body := StaticBody2D.new()
	body.collision_layer = Layers.INTERACT
	body.collision_mask = 0
	var shape := CircleShape2D.new()
	shape.radius = 24.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	add_to_group("resettable")


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag != &"light":
		return false
	if p_str("mode", "once") == "timed":
		_timer = p_float("t", 6.0) * Settings.timer_factor()
	if not lit:
		lit = true
		_glow.visible = true
		AudioService.play("lamp_on")
		Captions.caption("A lamp glows awake")
		Fx.pop_ring(level, global_position, Color(1, 0.95, 0.5), 60.0)
		level.trigger(p_str("opens"), true, self)
	return true


func _physics_process(delta: float) -> void:
	if lit and p_str("mode", "once") == "timed":
		_timer -= delta
		if _timer < 1.5:
			_glow.modulate.a = 0.5 + 0.5 * absf(sin(_timer * 10.0))
		if _timer <= 0.0:
			_off()
			Captions.caption("The lamp dims")


func _off() -> void:
	lit = false
	_glow.visible = false
	_glow.modulate.a = 1.0
	level.trigger(p_str("opens"), false, self)


func reset_puzzle() -> void:
	if lit and p_str("mode", "once") != "once":
		_off()
