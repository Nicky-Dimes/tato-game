extends Node
## First scene. Reads optional command-line switches (after "--"), then opens
## the title screen.
##   --level=W1-L1     jump straight into a stage (throwaway profile)
##   --test            mark the run as an automated test (no fades, no prompts)

var _shot_taker: ShotTaker


func _shots() -> ShotTaker:
	if _shot_taker == null:
		_shot_taker = ShotTaker.new()
		get_tree().root.add_child.call_deferred(_shot_taker)
	return _shot_taker


func _ready() -> void:
	var level := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			level = arg.substr(8)
		elif arg.begins_with("--at="):
			Game.debug_column = arg.substr(5).to_int()
		elif arg == "--test":
			Game.headless_test = true
		elif arg == "--fps":
			Game.show_stats = true
		elif arg.begins_with("--shot="):
			_shots().path = arg.substr(7)
		elif arg.begins_with("--shot-after="):
			_shots().after = arg.substr(13).to_int()
		elif arg.begins_with("--shot-count="):
			_shots().count = arg.substr(13).to_int()
		elif arg.begins_with("--shot-every="):
			_shots().every = arg.substr(13).to_int()
		elif arg.begins_with("--press="):
			_shots().press = arg.substr(8).split(",")
	# web builds can use ?level=W1-L1 for quick checks
	if OS.has_feature("web"):
		var q: Variant = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('level') || ''", true)
		if typeof(q) == TYPE_STRING and q != "":
			level = q
		var at: Variant = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('at') || ''", true)
		if typeof(at) == TYPE_STRING and (at as String).is_valid_int():
			Game.debug_column = (at as String).to_int()
	var map := ""
	if OS.has_feature("web"):
		if str(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('fps') || ''", true)) != "":
			Game.show_stats = true
		var m: Variant = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('map') || ''", true)
		if typeof(m) == TYPE_STRING:
			map = m
	await get_tree().process_frame
	if map != "":
		# ?map=W3 : look at a world's stage list (throwaway save, everything open)
		GameState.use_temp_profile()
		for id in LevelDB.all_stage_ids():
			if LevelDB.world_index(id) < LevelDB.world_index(map + "-L1") or id == map + "-L1":
				GameState.mark_cleared(id, {"notes_found": 2, "notes_total": 3})
		Game.goto_world_map(map)
	elif level != "":
		GameState.use_temp_profile()
		Game.start_level(level)
	else:
		Game.goto_title()
