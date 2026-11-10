extends AbilityStrategy
## Caramel Coat (Pepper + Honeycomb): squirts honey forward and bakes it
## into a crunchy bridge for a few seconds. It also hardens any soft resin
## nearby into something solid to stand on.

const MAX_TILES := 5


func start() -> void:
	var p := player
	p.honk_pose(0.35)
	p.noise = 1.0
	AudioService.voice("honk_fire")
	AudioService.play("caramel")
	var feet := p.global_position
	pulse(feet + Vector2(p.facing * 20.0, -30.0), PackedStringArray(["heat", "sticky", "bridge"]), 170.0, {
		"life": 0.3, "style": "ring", "color": color(),
	})
	# measure how far the bridge can go before it meets a wall
	var space := p.get_world_2d().direct_space_state
	var start_x := feet.x + p.facing * 26.0
	var y := feet.y + 12.0
	var length := MAX_TILES * float(Layers.TILE)
	var q := PhysicsRayQueryParameters2D.create(Vector2(start_x, y), Vector2(start_x + p.facing * length, y), Layers.WORLD)
	q.exclude = [p.get_rid()]
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		length = absf((hit["position"] as Vector2).x - start_x)
	if length < 40.0:
		Fx.float_text(world(), feet + Vector2(0, -90), "No room for a bridge", UITheme.CREAM)
		return
	var bridge := CaramelBridge.new()
	bridge.setup(length, p.facing, float(def.get("duration")) * Settings.timer_factor())
	world().add_child(bridge)
	bridge.global_position = Vector2(start_x, feet.y + 2.0)
	p.honked.emit(&"CARAMEL_COAT")


func anim() -> String:
	return "honk"
