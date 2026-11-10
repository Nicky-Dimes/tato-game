extends Prop
## A snack bowl holding one magical food. Never runs out, so a puzzle can
## always be retried. Eat with the interact button.

var food_id: StringName = &"PEPPER"
var _icon: Sprite2D
var _glow: Sprite2D


func _configure() -> void:
	add_to_group("food_bowl")
	food_id = StringName(arg(0, "PEPPER").to_upper())
	var def := FoodDB.food(food_id)
	add_child(Art.standing("props/bowl"))
	_icon = Art.centered("foods/" + String(food_id).to_lower(), 0.5)
	_icon.position = Vector2(0, -64)
	add_child(_icon)
	bob(_icon, 5.0, 1.8)
	add_sense(Vector2(84, 110), Vector2(0, -55))
	if def == null:
		push_warning("Snack bowl with unknown food: %s" % food_id)


func can_interact(_player: Tato) -> bool:
	return FoodDB.has_food(food_id)


func prompt() -> String:
	var def := FoodDB.food(food_id)
	return "Eat %s" % (def.display_name if def else "snack")


func interact(player: Tato) -> void:
	player.eat(food_id)
	var t := create_tween()
	t.tween_property(_icon, "scale", Vector2(0.68, 0.68), 0.08)
	t.tween_property(_icon, "scale", Vector2(0.5, 0.5), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
