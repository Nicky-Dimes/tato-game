extends Node
## Player options (audio, accessibility, controls). Stored apart from save slots
## in user://settings.json so they survive deleting or switching profiles.

signal changed(key: String)

const PATH := "user://settings.json"

const DEFAULTS := {
	"master_volume": 1.0,
	"music_volume": 0.7,
	"sfx_volume": 1.0,
	"voice_volume": 1.0,
	"cozy_mode": false,          # hearts never run out, creatures are slower
	"challenge_mode": false,     # creatures are quicker; never locks story rewards
	"infinite_feathers": false,  # assist: endless hearts
	"timer_scale": 1.0,          # 1.0 normal .. 2.0 relaxed
	"captions": true,
	"screen_shake": 1.0,         # 0..1
	"reduced_motion": false,
	"reduce_flashes": false,
	"high_contrast": false,
	"auto_run": true,
	"hold_to_attack": false,     # hold the attack button to keep attacking
	"ui_scale": 1.0,             # 0.75..1.5
	"fullscreen": false,
	"touch_controls": "auto",    # auto | on | off
	"touch_opacity": 0.8,
	"touch_size": 1.0,
	"quality": "auto",           # auto | low | high
	"show_timer": false,
	"bindings": {},
}

var data: Dictionary = {}
var _dirty := false
var _save_timer := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	data = DEFAULTS.duplicate(true)
	load_settings()
	apply_all()


func _process(delta: float) -> void:
	if _dirty:
		_save_timer -= delta
		if _save_timer <= 0.0:
			save_settings()


func get_value(key: String) -> Variant:
	if data.has(key):
		return data[key]
	return DEFAULTS.get(key)


func set_value(key: String, value: Variant) -> void:
	if data.get(key) == value:
		return
	data[key] = value
	_dirty = true
	_save_timer = 0.4
	_apply(key)
	changed.emit(key)


func flag(key: String) -> bool:
	return bool(get_value(key))


func num(key: String) -> float:
	return float(get_value(key))


## Timers for puzzles get longer in Cozy Mode / shorter in Challenge Mode.
func timer_factor() -> float:
	var f := num("timer_scale")
	if flag("cozy_mode"):
		f *= 1.5
	if flag("challenge_mode"):
		f *= 0.75
	return f


func honk_range_factor() -> float:
	return 1.3 if flag("cozy_mode") else 1.0


func hearts_protected() -> bool:
	return flag("cozy_mode") or flag("infinite_feathers")


## How fast creatures move and shoot: slower in Cozy Mode, quicker in Challenge.
func enemy_speed() -> float:
	if flag("cozy_mode"):
		return 0.75
	if flag("challenge_mode"):
		return 1.2
	return 1.0


func shake_amount() -> float:
	if flag("reduced_motion"):
		return 0.0
	return clampf(num("screen_shake"), 0.0, 1.0)


## True on phones/tablets or when the player asked for the light renderer path.
func low_quality() -> bool:
	var q := str(get_value("quality"))
	if q == "low":
		return true
	if q == "high":
		return false
	return OS.has_feature("mobile") or OS.has_feature("web_ios") or OS.has_feature("web_android")


func load_settings() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("settings.json was unreadable; using defaults")
		return
	for key: String in DEFAULTS.keys():
		if parsed.has(key) and typeof(parsed[key]) == typeof(DEFAULTS[key]):
			data[key] = parsed[key]
		elif parsed.has(key) and typeof(DEFAULTS[key]) == TYPE_FLOAT and typeof(parsed[key]) == TYPE_INT:
			data[key] = float(parsed[key])


func save_settings() -> void:
	_dirty = false
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write settings (%s)" % error_string(FileAccess.get_open_error()))
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


func reset_to_defaults() -> void:
	var keep_bindings: Dictionary = {}
	data = DEFAULTS.duplicate(true)
	data["bindings"] = keep_bindings
	save_settings()
	apply_all()
	for key: String in DEFAULTS.keys():
		changed.emit(key)


func apply_all() -> void:
	for key: String in ["master_volume", "music_volume", "sfx_volume", "voice_volume", "fullscreen", "ui_scale"]:
		_apply(key)


func _apply(key: String) -> void:
	match key:
		"quality":
			# The web page reads this before the game starts, to choose how
			# sharp to draw (see web/shell.html). It applies on the next load.
			if OS.has_feature("web"):
				JavaScriptBridge.eval("try{localStorage.setItem('tato_quality','%s')}catch(e){}" % str(get_value("quality")), true)
		"master_volume":
			_set_bus("Master", num(key))
		"music_volume":
			_set_bus("Music", num(key))
		"sfx_volume":
			_set_bus("SFX", num(key))
			_set_bus("UI", num(key))
		"voice_volume":
			_set_bus("Voice", num(key))
		"fullscreen":
			if not OS.has_feature("web") and DisplayServer.get_name() != "headless":
				var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if flag(key) else DisplayServer.WINDOW_MODE_WINDOWED
				if DisplayServer.window_get_mode() != mode:
					DisplayServer.window_set_mode(mode)
		"ui_scale":
			var root := get_tree().root if is_inside_tree() else null
			if root:
				root.content_scale_factor = clampf(num(key), 0.75, 1.5)


func _set_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.001, 1.0)))
