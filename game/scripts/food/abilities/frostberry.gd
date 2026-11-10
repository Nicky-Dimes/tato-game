extends AbilityStrategy
## Freeze Shot: icy shards. A frozen creature turns into a block of ice Tato
## can stand on; water freezes over where a shard lands.

func start() -> void:
	for angle: float in [-0.12, 0.0, 0.12]:
		var v := Vector2(620, 0).rotated(angle)
		shoot(v, {"look": "ice", "life": 0.8, "radius": 11.0})
	# the cold also freezes water and melts nothing: tell the scenery
	EffectPulse.emit(world(), player.muzzle() + Vector2(player.facing * 90.0, 30.0), PackedStringArray(["cold"]), 120.0,
		{"life": 0.12, "style": "none", "source": player, "info": {"freeze_time": 8.0}})
	AudioService.voice("honk_ice")
	AudioService.play_varied("freeze", -4.0)
	player.honked.emit(&"FROSTBERRY")
