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
## Debug: start a stage this many columns in (set by ?at= / --at=).
var debug_column := -1

## Debug: show frames per second and drawing numbers (?fps=1 / --fps).
var show_stats := false
var _stats_label: Label
var _stats_clock := 0.0
var _first_scene := true
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


func _process(delta: float) -> void:
	if not show_stats:
		return
	_stats_clock -= delta
	if _stats_clock > 0.0:
		return
	_stats_clock = 0.5
	if _stats_label == null:
		_stats_label = Label.new()
		_stats_label.position = Vector2(12, 96)
		_stats_label.add_theme_font_size_override("font_size", 18)
		_stats_label.add_theme_color_override("font_color", Color.WHITE)
		_stats_label.add_theme_color_override("font_outline_color", Color.BLACK)
		_stats_label.add_theme_constant_override("outline_size", 6)
		_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fade_layer.add_child(_stats_label)
	var fps := Engine.get_frames_per_second()
	var draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var objects := int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var frame_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var mem := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var vram := Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0
	var size := get_viewport().get_visible_rect().size
	_stats_label.text = "%d fps  %d draws  %d nodes\nframe %.1f ms  physics %.1f ms\nmem %.0f MB  textures %.0f MB" % [fps, draws, nodes, frame_ms, physics_ms, mem, vram]
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.tatoStats={fps:%d,draws:%d,objects:%d,nodes:%d,frameMs:%.2f,physicsMs:%.2f,memMB:%.1f,texMB:%.1f,view:[%d,%d]}" % [fps, draws, objects, nodes, frame_ms, physics_ms, mem, vram, int(size.x), int(size.y)], true)
		var scene := get_tree().current_scene
		var debug := {"paused": get_tree().paused, "scene": scene.scene_file_path if scene != null else "", "x": -1.0, "hearts": GameState.hearts, "power": ""}
		if scene is Level and scene.player != null:
			debug["x"] = scene.player.position.x
			debug["power"] = str(scene.player.power.power)
		JavaScriptBridge.eval("window.tatoDebug=" + JSON.stringify(debug), true)


func goto(path: String, args: Dictionary = {}) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	scene_args = args
	scene_changing.emit(path)
	var quick := headless_test or DisplayServer.get_name() == "headless"
	var first := _first_scene
	_first_scene = false
	if first:
		# the loading page is still covering the game: no fade needed
		_fade_rect.color.a = 0.0
	elif not quick:
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
	if first:
		await get_tree().process_frame
		_tell_page_ready()
	elif not quick:
		var t2 := create_tween()
		t2.tween_property(_fade_rect, "color:a", 0.0, 0.26)
		await t2.finished
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false


## Web: lets the loading page (web/shell.html) know the first screen is drawn.
func _tell_page_ready() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.tatoReady && window.tatoReady()", true)


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


## Capture/debug options apply from an autoload, which survives the boot scene.
func configure_debug_stage(power: String, panel: String, scale_proof: bool = false) -> void:
	while is_transitioning:
		await get_tree().process_frame
	var stage := get_tree().current_scene as Level
	if stage == null:
		return
	if power != "" and FoodDB.food(StringName(power)) != null:
		stage.player.power.pick_up(StringName(power))
	if scale_proof:
		stage.hud._banner.visible = false
		var cell := stage.cell_at(stage.player.position - Vector2(220, 1))
		var enemy := EntityFactory.create(stage, {"type": "rock_golem", "cell": cell, "args": [], "params": {}}) as Enemy
		stage.entities.add_child(enemy)
		enemy.global_position = stage.player.position - Vector2(220, 0)
		var caption := Label.new()
		caption.text = "Scale QA: Rock Golem 86px · Tato ~102px · Boss " + str(int(stage.boss.height)) + "px" if stage.boss != null else "Scale QA"
		caption.position = Vector2(24, 230)
		caption.add_theme_font_size_override("font_size", 18)
		caption.add_theme_color_override("font_color", Color.WHITE)
		caption.add_theme_color_override("font_outline_color", Color("301444"))
		caption.add_theme_constant_override("outline_size", 4)
		stage.hud.root.add_child(caption)
	if panel in ["pause", "journal", "settings", "map"]:
		stage._pause_menu.open("" if panel == "pause" else panel)
