extends Node
## Scene flow: title -> hub -> world map -> stage -> results, with a soft
## fade between scenes. Also remembers which stage is being played.

signal scene_changing(path: String)
signal level_started(level_id: String)
signal level_finished(level_id: String, result: Dictionary)

const TITLE_SCENE := "res://scenes/menus/MainMenu.tscn"
const LEVEL_SCENE := "res://scenes/levels/Level.tscn"
const STORY_SCENE := "res://scenes/menus/Storybook.tscn"
const WORLD_MAP_SCENE := "res://scenes/menus/WorldMap.tscn"
const CREDITS_SCENE := "res://scenes/menus/Credits.tscn"

var level_id := ""
var start_checkpoint := ""
## What a scene should show when it opens (story id, world id ...).
var scene_args: Dictionary = {}
var is_transitioning := false
## Set by tests / the autoplay bot so stages skip intros and prompts.
var headless_test := false

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.19, 0.08, 0.27, 0.0)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)


func goto(path: String, args: Dictionary = {}) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	scene_args = args
	scene_changing.emit(path)
	var quick := headless_test or DisplayServer.get_name() == "headless"
	if not quick:
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		var t := create_tween()
		t.tween_property(_fade_rect, "color:a", 1.0, 0.22)
		await t.finished
	get_tree().paused = false
	Engine.time_scale = 1.0
	Captions.clear()
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Could not open scene %s (%s)" % [path, error_string(err)])
	await get_tree().process_frame
	if not quick:
		var t2 := create_tween()
		t2.tween_property(_fade_rect, "color:a", 0.0, 0.26)
		await t2.finished
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false


func goto_title() -> void:
	goto(TITLE_SCENE)


func goto_hub() -> void:
	start_level(LevelDB.HUB_ID)


func goto_world_map(world_id: String = "") -> void:
	goto(WORLD_MAP_SCENE, {"world": world_id})


func goto_story(story_id: String, then: Dictionary = {}) -> void:
	goto(STORY_SCENE, {"story": story_id, "then": then})


func start_level(id: String, checkpoint: String = "") -> void:
	level_id = id
	start_checkpoint = checkpoint
	GameState.profile["current_level"] = id if id != LevelDB.HUB_ID else str(GameState.profile.get("current_level", ""))
	goto(LEVEL_SCENE, {"level": id})
	level_started.emit(id)


func restart_level() -> void:
	start_level(level_id)


## Called by a stage when Tato reaches the exit (or settles a finale).
func finish_level(stats: Dictionary) -> Dictionary:
	var result := GameState.mark_cleared(level_id, stats)
	level_finished.emit(level_id, result)
	return result


## Where to go after the results card.
func leave_level(cleared: bool) -> void:
	var id := level_id
	if id == LevelDB.HUB_ID:
		goto_title()
		return
	if id == "TRIAL":
		goto_hub()
		return
	var w := LevelDB.world_of(id)
	if cleared and LevelDB.stage_kind(id) == "boss":
		if int(w.get("index", 0)) == LevelDB.WORLDS.size():
			goto_story("ending", {"scene": CREDITS_SCENE})
		else:
			goto_story("page_%s" % str(w.get("id", "")).to_lower(), {"hub": true})
		return
	if cleared and id == "W1-L1" and not GameState.has_flag("hub_intro"):
		GameState.set_flag("hub_intro")
		goto_hub()
		return
	goto_world_map(str(w.get("id", "W1")))


func quit_game() -> void:
	GameState.save()
	Settings.save_settings()
	get_tree().quit()
