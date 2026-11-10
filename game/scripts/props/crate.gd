extends Prop
## Things that break when hit.
##   crate            any attack (or a stomp) smashes it; coins hop out
##   cracked          a cracked wall: only a Tomato Bomb or a Garlic Dash breaks it
##   iceblock         a block of ice: only fire melts it
## `holds=coins:5`, `holds=heart`, `holds=key`, `holds=pickup:wings` puts
## something inside. `h=2` stacks a cracked wall / ice two cells tall.

var broken := false
var _body: StaticBody2D
var _sprite: Node2D
var _kind := "crate"
var _hp := 1


func _configure() -> void:
	_kind = p_str("type", "crate")
	var h := maxi(p_int("h", 1), 1)
	var size := Vector2(60, 60 * h + (h - 1) * 4)
	_sprite = Node2D.new()
	add_child(_sprite)
	for i in h:
		var art := "items/crate"
		if _kind == "cracked":
			art = WorldKit.art(level.theme, "block2")
		elif _kind == "iceblock":
			art = "world/icy_tile3"
		var piece := Art.sized(art, 64.0 if _kind != "crate" else 60.0)
		piece.position = Vector2(0, -i * 64.0)
		if _kind == "cracked":
			piece.modulate = Color(0.82, 0.78, 0.86)
		_sprite.add_child(piece)
	_body = add_solid(size, Vector2(0, -size.y * 0.5), Layers.WORLD | Layers.INTERACT)
	if _kind == "iceblock":
		_body.add_to_group("ice")
	add_to_group("hittable")
	add_to_group("resettable")
	if _kind == "cracked":
		queue_redraw()


func take_hit(_damage: int, info: Dictionary) -> bool:
	if broken:
		return false
	var element: StringName = info.get("element", &"plain")
	if _kind == "cracked" and not (element in [&"blast", &"dash", &"burst"]):
		_shake()
		return true
	if _kind == "iceblock" and not (element in [&"fire", &"blast", &"burst"]):
		_shake()
		return true
	smash()
	return true


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag == &"heat" and _kind == "iceblock" and not broken:
		smash()
		return true
	return false


func smash() -> void:
	broken = true
	_body.collision_layer = 0
	_sprite.visible = false
	remove_from_group("hittable")
	AudioService.play("crate_break")
	var at := global_position + Vector2(0, -30)
	Fx.burst(level, at, "crumbs", Color("d9a066") if _kind == "crate" else Color(0.8, 0.85, 0.95), 8, {"spread": 60.0, "life": 0.6, "size": 12.0})
	Fx.puff(level, at, Color(1, 1, 1, 0.8), 5)
	level.shake(3.0)
	level.spill(p_str("holds", "coins:2" if _kind == "crate" else ""), at)
	queue_redraw()


func _shake() -> void:
	var t := create_tween()
	t.tween_property(_sprite, "position:x", 5.0, 0.04)
	t.tween_property(_sprite, "position:x", -5.0, 0.06)
	t.tween_property(_sprite, "position:x", 0.0, 0.05)
	AudioService.play_varied("clink", -6.0)


func _draw() -> void:
	if _kind != "cracked" or broken:
		return
	# crack lines so it reads as breakable, not as plain wall
	var h := maxi(p_int("h", 1), 1)
	for i in h:
		var y := -i * 64.0
		draw_polyline(PackedVector2Array([Vector2(-14, y - 58), Vector2(-4, y - 40), Vector2(-12, y - 28), Vector2(2, y - 10)]), Color("3a1f4d"), 3.0, true)
		draw_polyline(PackedVector2Array([Vector2(-4, y - 40), Vector2(12, y - 34), Vector2(18, y - 46)]), Color("3a1f4d"), 3.0, true)


func reset_puzzle() -> void:
	pass
