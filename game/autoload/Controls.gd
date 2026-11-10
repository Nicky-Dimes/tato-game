extends Node
## Input actions, default bindings, remapping and "which device is the player
## using right now" (so prompts can show a key, a pad button or a touch label).

signal device_changed(device: String)
signal bindings_changed

const DEVICE_KEYBOARD := "keyboard"
const DEVICE_GAMEPAD := "gamepad"
const DEVICE_TOUCH := "touch"

## Gameplay actions in the order the remap screen lists them.
const ACTIONS: Array[String] = [
	"move_left", "move_right", "move_up", "move_down", "jump", "attack", "pause",
]

const ACTION_LABELS := {
	"move_left": "Move left",
	"move_right": "Move right",
	"move_up": "Look up / talk / go in",
	"move_down": "Crouch / drop / slide",
	"jump": "Jump (again in the air to flap)",
	"attack": "Attack (honk or power)",
	"pause": "Pause",
}

## Defaults: physical key codes and joypad buttons / axes.
const DEFAULT_KEYS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"jump": [KEY_SPACE, KEY_Z],
	"attack": [KEY_J, KEY_X],
	"pause": [KEY_ESCAPE, KEY_P],
}

const DEFAULT_PAD_BUTTONS := {
	"move_left": [JOY_BUTTON_DPAD_LEFT],
	"move_right": [JOY_BUTTON_DPAD_RIGHT],
	"move_up": [JOY_BUTTON_DPAD_UP],
	"move_down": [JOY_BUTTON_DPAD_DOWN],
	"jump": [JOY_BUTTON_A],
	"attack": [JOY_BUTTON_X, JOY_BUTTON_B],
	"pause": [JOY_BUTTON_START],
}

## axis, sign
const DEFAULT_PAD_AXES := {
	"move_left": [[JOY_AXIS_LEFT_X, -1.0]],
	"move_right": [[JOY_AXIS_LEFT_X, 1.0]],
	"move_up": [[JOY_AXIS_LEFT_Y, -1.0]],
	"move_down": [[JOY_AXIS_LEFT_Y, 1.0]],
}

const PAD_BUTTON_NAMES := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_START: "Start", JOY_BUTTON_BACK: "Select",
	JOY_BUTTON_DPAD_LEFT: "D-pad Left", JOY_BUTTON_DPAD_RIGHT: "D-pad Right",
	JOY_BUTTON_DPAD_UP: "D-pad Up", JOY_BUTTON_DPAD_DOWN: "D-pad Down",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
}

const TOUCH_LABELS := {
	"jump": "JUMP", "attack": "ATTACK", "pause": "II",
	"move_left": "◀", "move_right": "▶", "move_up": "▲", "move_down": "▼",
}

var device := DEVICE_KEYBOARD
## action -> {"keys": Array[int], "pad": Array[int]} currently in effect
var bindings: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_bindings()
	apply_bindings()
	if DisplayServer.is_touchscreen_available() and (OS.has_feature("mobile") or OS.has_feature("web")):
		device = DEVICE_TOUCH


func _input(event: InputEvent) -> void:
	var new_device := device
	if event is InputEventKey and event.pressed:
		new_device = DEVICE_KEYBOARD
	elif event is InputEventJoypadButton and event.pressed:
		new_device = DEVICE_GAMEPAD
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.5:
		new_device = DEVICE_GAMEPAD
	elif event is InputEventScreenTouch and event.pressed:
		new_device = DEVICE_TOUCH
	if new_device != device:
		device = new_device
		device_changed.emit(device)


func using_touch() -> bool:
	var mode := str(Settings.get_value("touch_controls"))
	if mode == "on":
		return true
	if mode == "off":
		return false
	return device == DEVICE_TOUCH


func default_bindings() -> Dictionary:
	var out := {}
	for action in ACTIONS:
		out[action] = {
			"keys": (DEFAULT_KEYS.get(action, []) as Array).duplicate(),
			"pad": (DEFAULT_PAD_BUTTONS.get(action, []) as Array).duplicate(),
		}
	return out


func _load_bindings() -> void:
	bindings = default_bindings()
	var saved: Variant = Settings.get_value("bindings")
	if typeof(saved) != TYPE_DICTIONARY:
		return
	for action in ACTIONS:
		if not saved.has(action) or typeof(saved[action]) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = saved[action]
		for kind in ["keys", "pad"]:
			if entry.has(kind) and typeof(entry[kind]) == TYPE_ARRAY:
				var clean: Array = []
				for v: Variant in entry[kind]:
					if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
						clean.append(int(v))
				bindings[action][kind] = clean


func apply_bindings() -> void:
	for action in ACTIONS:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			InputMap.add_action(action, 0.35)
		for code: int in bindings[action]["keys"]:
			var ek := InputEventKey.new()
			ek.physical_keycode = code as Key
			InputMap.action_add_event(action, ek)
		for button: int in bindings[action]["pad"]:
			var eb := InputEventJoypadButton.new()
			eb.button_index = button as JoyButton
			InputMap.action_add_event(action, eb)
		for pair: Array in DEFAULT_PAD_AXES.get(action, []):
			var ea := InputEventJoypadMotion.new()
			ea.axis = pair[0] as JoyAxis
			ea.axis_value = pair[1]
			InputMap.action_add_event(action, ea)
	bindings_changed.emit()


## Replace one binding (slot 0 = main, 1 = alternate). kind is "keys" or "pad".
## A code used by another action is taken away from it, except for the
## jump/flap pair which are allowed to share a button.
func rebind(action: String, kind: String, slot: int, code: int) -> void:
	if not bindings.has(action):
		return
	for other in ACTIONS:
		if other == action:
			continue
		if _may_share(action, other):
			continue
		var arr: Array = bindings[other][kind]
		if arr.has(code):
			arr.erase(code)
	var mine: Array = bindings[action][kind]
	while mine.size() <= slot:
		mine.append(code)
	mine[slot] = code
	# no duplicates inside one action
	var seen: Array = []
	for c: int in mine:
		if not seen.has(c):
			seen.append(c)
	bindings[action][kind] = seen
	_store()
	apply_bindings()


func reset_bindings() -> void:
	bindings = default_bindings()
	_store()
	apply_bindings()


func _may_share(_a: String, _b: String) -> bool:
	return false


func _store() -> void:
	Settings.set_value("bindings", bindings.duplicate(true))
	Settings.save_settings()


func key_name(code: int) -> String:
	var s := OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(code as Key))
	if s == "":
		s = OS.get_keycode_string(code as Key)
	match s:
		"Space":
			return "Space"
		"Escape":
			return "Esc"
		"Left":
			return "←"
		"Right":
			return "→"
		"Up":
			return "↑"
		"Down":
			return "↓"
	return s


func pad_name(button: int) -> String:
	return str(PAD_BUTTON_NAMES.get(button, "Button %d" % button))


## Short label for an action on the device in use, e.g. "E", "X" or "EAT".
func prompt(action: String) -> String:
	if not bindings.has(action):
		return ""
	match device:
		DEVICE_TOUCH:
			return str(TOUCH_LABELS.get(action, action))
		DEVICE_GAMEPAD:
			var pad: Array = bindings[action]["pad"]
			return pad_name(pad[0]) if pad.size() > 0 else "?"
		_:
			var keys: Array = bindings[action]["keys"]
			return key_name(keys[0]) if keys.size() > 0 else "?"


## Replaces {action} tokens in hint text with the current prompt, e.g.
## "Press {jump} to jump" -> "Press Space to jump".
func fill(text: String) -> String:
	var out := text
	for action in ACTIONS:
		var token := "{" + action + "}"
		if out.contains(token):
			out = out.replace(token, prompt(action))
	return out
