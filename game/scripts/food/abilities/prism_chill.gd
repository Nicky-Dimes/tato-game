extends AbilityStrategy
## Prism Chill (Zesty Citrus + Frostberry): freezes a sparkling prism in
## front of Tato. Light beams that hit it turn a corner (sideways beams go
## up, falling or rising beams go the way Tato was facing). It is also a
## handy icy step. One at a time; warmth melts it.

func can_start() -> bool:
	return player.is_on_floor() or not player.in_water


func start() -> void:
	var p := player
	p.honk_pose(0.3)
	AudioService.voice("honk_ice")
	AudioService.play("freeze")
	var at := p.global_position + Vector2(p.facing * 78.0, 0.0)
	# sit it on the grid so beams line up with mirrors and lamps
	at.x = (floorf(at.x / Layers.TILE) + 0.5) * Layers.TILE
	if p.is_on_floor():
		at.y = roundf(at.y / Layers.TILE) * Layers.TILE
	for old in p.get_tree().get_nodes_in_group("prism"):
		old.call("melt")
	var prism := PrismBlock.new()
	prism.setup(p.facing, float(def.get("duration")) * Settings.timer_factor())
	world().add_child(prism)
	prism.global_position = at
	pulse(at + Vector2(0, -30), PackedStringArray(["cold"]), 90.0, {"life": 0.2, "style": "ring", "color": Color(0.8, 0.97, 1.0)})
	p.honked.emit(&"PRISM_CHILL")


func anim() -> String:
	return "honk"
