extends Enemy
## Flavor Drone: one of Cloche's brass helpers. It floats along its beat and
## sips the flavour out of anything it bumps: Tato loses Honk Charge (and a
## Comfort Feather). A honk knocks it dizzy; a deep Drumbeat switches it off.

var _phase := 0.0
var _off := false
var _range := Vector2(160, 0)


func _configure() -> void:
	position = LevelData.cell_center(cell)
	home = position
	_range = Vector2(p_float("dx", 3.0), p_float("dy", 0.0)) * Layers.TILE * 0.5
	_phase = p_float("phase", 0.0)
	sprite = Art.centered("enemies/flavor_drone")
	add_child(sprite)
	collision_mask = 0
	add_touch(Vector2(46, 42), Vector2.ZERO)
	var sense := Area2D.new()
	sense.collision_layer = Layers.ENEMY
	sense.collision_mask = 0
	var sh := CircleShape2D.new()
	sh.radius = 28.0
	var cs := CollisionShape2D.new()
	cs.shape = sh
	sense.add_child(cs)
	add_child(sense)


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if _off:
		return false
	if tag == &"resonance":
		_off = true
		touch_hurts = false
		sprite.modulate = Color(0.55, 0.55, 0.62)
		AudioService.play("thud")
		Captions.caption("The Flavor Drone powers down")
		var t := create_tween()
		t.tween_property(self, "position:y", position.y + 400.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(sprite, "modulate:a", 0.0, 0.9)
		return true
	if tag == &"honk" or tag == &"light":
		stun(3.0)
		AudioService.play_varied("squeak", -6.0)
		return true
	return false


func _bump(player: Tato) -> void:
	GameState.spend_charge(minf(GameState.honk_charge, 30.0))
	player.hurt(global_position)
	Captions.caption("The drone sips your flavour")


func _behave(delta: float) -> void:
	if _off:
		return
	if not is_stunned():
		_phase += delta
	position = home + Vector2(sin(_phase * 1.1) * _range.x, sin(_phase * 1.1) * _range.y + sin(_phase * 3.0) * 6.0)
	facing = signf(cos(_phase * 1.1)) if _range.x != 0.0 else facing


func reset_puzzle() -> void:
	super.reset_puzzle()
	_off = false
	touch_hurts = true
	sprite.modulate = Color.WHITE
