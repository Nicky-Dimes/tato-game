extends AbilityStrategy
## Sunbeam Steps (Zesty Citrus + Cloud Puff Pastry): a warm burst of
## sunlight shows hidden cloud steps all around and makes them solid for a
## little while.

func start() -> void:
	var p := player
	p.honk_pose(0.35)
	p.noise = 0.6
	AudioService.voice("honk_zing")
	AudioService.play("sunbeam")
	pulse(p.global_position + Vector2(0, -40), PackedStringArray(["reveal", "light"]), 470.0, {
		"life": 0.5, "style": "flash",
		"color": Color(1.0, 0.92, 0.5, 0.4 if Settings.flag("reduce_flashes") else 0.85),
		"info": {"solid_time": float(def.get("duration"))},
	})
	Captions.caption("Sunlight fills the air")
	p.honked.emit(&"SUNBEAM_STEPS")


func anim() -> String:
	return "honk"
