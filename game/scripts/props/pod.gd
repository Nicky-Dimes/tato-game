extends Prop
## A sealed seed pod. A Pop Bounce landing (or anything that pops) bursts it.
##   opens=<id>   switches a link on for good
##   crumbs=4     lets out golden crumbs
## A pod is also a springy step: bursting it gives a little hop.

var popped := false
var _sprite: Sprite2D
var _body: StaticBody2D


func _configure() -> void:
	_sprite = Art.standing("props/pod")
	add_child(_sprite)
	_body = add_solid(Vector2(56, 44), Vector2(0, -22), Layers.WORLD | Layers.INTERACT)
	add_to_group("resettable")


func on_effect(tag: StringName, _info: Dictionary) -> bool:
	if popped or tag != &"pop":
		return false
	popped = true
	_body.collision_layer = 0
	_sprite.visible = false
	AudioService.play("pod_pop")
	Captions.caption("Pop! The pod bursts")
	Fx.burst(level, global_position + Vector2(0, -24), "puff", Color(0.8, 1.0, 0.7, 0.9), 6, {"spread": 50.0, "life": 0.45, "size": 10.0})
	if p_str("opens") != "":
		level.trigger(p_str("opens"), true, self)
	var count := p_int("crumbs", 0)
	for i in count:
		var crumb: Node = load("res://scripts/props/crumb.gd").new()
		crumb.call("setup", level, {"params": {}, "args": [], "cell": cell})
		level.entities.add_child(crumb)
		(crumb as Node2D).global_position = global_position + Vector2(0, -30)
		var target := global_position + Vector2((i - (count - 1) * 0.5) * 44.0, -100.0 - (i % 2) * 20.0)
		crumb.create_tween().tween_property(crumb, "global_position", target, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return true


func reset_puzzle() -> void:
	if popped and p_str("opens") == "" and p_int("crumbs", 0) == 0:
		popped = false
		_body.collision_layer = Layers.WORLD | Layers.INTERACT
		_sprite.visible = true
