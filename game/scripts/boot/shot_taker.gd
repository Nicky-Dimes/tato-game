class_name ShotTaker
extends Node
## Debug helper: saves screenshots of the running game, then quits.
##   godot --path game -- --level=W1-L1 --shot=/tmp/a_%d.png --shot-after=120 --shot-count=4 --shot-every=6 --press=move_right
## --press holds input actions from frame 30 on; "attack" is tapped every 40 frames.

var path := ""
var after := 120
var count := 1
var every := 10
var press: PackedStringArray = []
var _frame := 0
var _taken := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 30:
		for a in press:
			if a != "attack":
				Input.action_press(a)
	if press.has("attack") and _frame > 30:
		if _frame % 40 == 0:
			Input.action_press("attack")
		elif _frame % 40 == 3:
			Input.action_release("attack")
	if _frame >= after and (_frame - after) % every == 0 and _taken < count:
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var out := path.replace("%d", str(_taken))
		img.save_png(out)
		_taken += 1
		if _taken >= count:
			get_tree().quit()
