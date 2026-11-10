extends Node
## First scene. Reads optional command-line switches (after "--"), then opens
## the title screen.
##   --level=W1-L1     jump straight into a stage (throwaway profile)
##   --test            mark the run as an automated test (no fades, no prompts)

func _ready() -> void:
	var level := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			level = arg.substr(8)
		elif arg == "--test":
			Game.headless_test = true
	# web builds can use ?level=W1-L1 for quick checks
	if OS.has_feature("web"):
		var q: Variant = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('level') || ''", true)
		if typeof(q) == TYPE_STRING and q != "":
			level = q
	await get_tree().process_frame
	if level != "":
		GameState.use_temp_profile()
		Game.start_level(level)
	else:
		Game.goto_title()
