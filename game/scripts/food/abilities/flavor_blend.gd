extends AbilityStrategy
## Any two snacks that are not one of the twelve signature recipes still do
## something: both flavours burst out together in a small ring (so each
## flavour's reactions happen at once), Tato does a happy hop, and both
## snacks last a little longer the next time they are used.

func start() -> void:
	var rec := def as RecipeDefinition
	player.honk_pose(0.35)
	player.noise = 1.0
	AudioService.voice("honk_happy")
	AudioService.play("blend")
	var origin := player.global_position + Vector2(0, -36)
	pulse(origin, rec.tags, 150.0, {"life": 0.4, "style": "ring", "color": rec.color})
	var fa := FoodDB.food(rec.food_a)
	var fb := FoodDB.food(rec.food_b)
	if fa != null:
		Fx.sparkle(world(), origin + Vector2(-20, 0), fa.color, 6)
		runner.add_bonus_time(fa.id, 2.0)
	if fb != null:
		Fx.sparkle(world(), origin + Vector2(20, 0), fb.color, 6)
		runner.add_bonus_time(fb.id, 2.0)
	Fx.float_text(world(), player.global_position + Vector2(0, -110), rec.display_name + "!", rec.color.lightened(0.4))
	if player.is_on_floor():
		player.velocity.y = -330.0
	player.honked.emit(rec.id)


func anim() -> String:
	return "honk"
