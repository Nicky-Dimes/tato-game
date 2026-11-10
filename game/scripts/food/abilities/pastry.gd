extends AbilityStrategy
## Feathercloud: puff out a small soft cloud to stand on. In the air it
## appears under Tato's feet; on the ground it appears as a step in front.
## Two at a time; each melts after a few seconds (sooner in wind).

func start() -> void:
	var p := player
	var at := p.global_position + Vector2(0, 10)
	if p.is_on_floor():
		at = p.global_position + Vector2(p.facing * 84.0, -70.0)
	else:
		p.velocity.y = minf(p.velocity.y, 60.0)
	CloudStep.spawn(world(), at, float(def.get("duration")) * Settings.timer_factor())
	p.honk_pose(0.2)
	AudioService.voice("honk_puff")
	AudioService.play("puff")
	p.honked.emit(&"PASTRY")
