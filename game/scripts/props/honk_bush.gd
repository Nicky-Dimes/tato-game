extends Prop
## A fruit bush. A honk shakes its treats loose: a few crumbs pop out, once.

var shaken := false
var _sprite: Sprite2D


func _configure() -> void:
	_sprite = Art.standing("props/bush_full")
	add_child(_sprite)
	add_sense(Vector2(90, 90), Vector2(0, -45))


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if tag != &"honk":
		return false
	var t := create_tween()
	t.tween_property(_sprite, "rotation", 0.12, 0.05)
	t.tween_property(_sprite, "rotation", -0.1, 0.08)
	t.tween_property(_sprite, "rotation", 0.0, 0.08)
	if shaken:
		return true
	shaken = true
	_sprite.texture = Art.tex("props/bush_empty") if Art.has("props/bush_empty") else _sprite.texture
	AudioService.play("rustle")
	Captions.caption("Treats shake loose from the bush")
	var count := maxi(p_int("crumbs", 3), 1)
	for i in count:
		var crumb: Node = load("res://scripts/props/crumb.gd").new()
		var cx := cell.x + (i - count / 2) if count > 1 else cell.x
		crumb.call("setup", level, {"params": {}, "args": [], "cell": Vector2i(cx, cell.y - 1)})
		level.entities.add_child(crumb)
		(crumb as Node2D).global_position = global_position + Vector2(0, -60)
		var target := global_position + Vector2((i - (count - 1) * 0.5) * 46.0, -96.0)
		var tw := crumb.create_tween()
		tw.tween_property(crumb, "global_position", target, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return true
