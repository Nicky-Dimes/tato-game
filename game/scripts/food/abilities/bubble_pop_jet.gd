extends AbilityStrategy
## Bubble Pop Jet (Bubbleberry + Popcorn): four bursts of lift. Each press
## of jump in mid-air pops a bubble under Tato and kicks him upward.

const JUMPS := 4


func kind() -> String:
	return KIND_TOGGLE


func start() -> void:
	player.extra_air_jumps = JUMPS
	player.visual.tint = Color(0.9, 0.97, 1.0)
	AudioService.voice("honk_bubble")
	AudioService.play("bubble_up")
	player.honk_pose(0.2)
	if player.is_on_floor():
		player.velocity.y = Tato.JUMP_VELOCITY * 0.6
	else:
		player.velocity.y = minf(player.velocity.y, Tato.JUMP_VELOCITY * 0.75)
		Fx.pop_ring(world(), player.global_position, Color(0.6, 0.85, 1.0), 46.0)
	player.honked.emit(&"BUBBLE_POP_JET")


func tick(_delta: float) -> void:
	if player.extra_air_jumps <= 0 and player.is_on_floor():
		finish()


func stop() -> void:
	player.extra_air_jumps = 0
	player.visual.tint = Color.WHITE
