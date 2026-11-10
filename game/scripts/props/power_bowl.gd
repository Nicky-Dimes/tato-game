extends Prop
## A food bowl holding one attack power-up: `power FIRE_PEPPER`. Touch it and
## that power replaces whatever Tato had. The bowl never runs out.

var food_id: StringName = &"FIRE_PEPPER"
var _icon: Sprite2D
var _cool := 0.0


func _configure() -> void:
	add_to_group("food_bowl")
	food_id = StringName(arg(0, "FIRE_PEPPER").to_upper())
	var bowl_art := WorldKit.art(level.theme, "bowl")
	if not Art.has(bowl_art):
		bowl_art = "items/bowl_fruit"
	add_child(Art.sized(bowl_art, 62.0))
	_icon = Art.icon("powers/" + String(food_id).to_lower(), 50.0)
	_icon.position = Vector2(0, -92)
	add_child(_icon)
	bob(_icon, 5.0, 1.8)
	var touch := add_touch(Vector2(70, 120), Vector2(0, -60))
	touch.body_entered.connect(_on_touch)
	if not FoodDB.has_food(food_id):
		push_warning("Power bowl with unknown power: %s" % food_id)


func _physics_process(delta: float) -> void:
	_cool = maxf(_cool - delta, 0.0)


func _on_touch(body: Node) -> void:
	if not (body is Tato) or _cool > 0.0:
		return
	var player := body as Tato
	if player.power.power == food_id:
		return
	_cool = 1.0
	player.collect_power(food_id)
	var base := _icon.scale
	var t := create_tween()
	t.tween_property(_icon, "scale", base * 1.4, 0.08)
	t.tween_property(_icon, "scale", base, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
