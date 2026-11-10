extends Node
## Runs every test script under res://tests/{unit,integration,smoke}.
##   godot --headless --fixed-fps 60 --path game res://tests/TestRunner.tscn
## (--fixed-fps lets the headless run go faster than real time)
## Optional after "--":  --only=<text in file name>   --group=unit|integration|smoke
## Exit code is 0 only when every test passes.

var _passed := 0
var _failed := 0
var _report: Array[String] = []
var _limit_seconds := 1500.0        # real seconds; --timeout=<seconds> changes it
var _deadline_ms := 0
var _errors := ErrorCatcher.new()


## Collects every script error and engine error printed while tests run, so
## a test fails if the game logs one (a wrong dictionary key, a null call...).
class ErrorCatcher extends Logger:
	var seen: Array[String] = []
	var _lock := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_lock.lock()
		seen.append("%s  (%s:%d in %s)" % [rationale if rationale != "" else code, file.get_file(), line, function])
		_lock.unlock()

	func take() -> Array[String]:
		_lock.lock()
		var out := seen.duplicate()
		seen.clear()
		_lock.unlock()
		return out


## Safety net measured in real time (tests may run with --fixed-fps, where
## game time races ahead): a stuck test must not hang CI forever.
func _process(_delta: float) -> void:
	if _deadline_ms > 0 and Time.get_ticks_msec() > _deadline_ms:
		_deadline_ms = 0
		print("")
		for line in _report:
			print(line)
		print("TESTS: timed out after %.0fs" % _limit_seconds)
		get_tree().quit(2)


func _ready() -> void:
	Game.headless_test = true
	OS.add_logger(_errors)
	var only := ""
	var group := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.substr(7)
		elif arg.begins_with("--group="):
			group = arg.substr(8)
		elif arg.begins_with("--timeout="):
			_limit_seconds = float(arg.substr(10))
	# Stay alive across the scene changes tests make: this node stops being
	# "the current scene", so change_scene_to_file() leaves it alone.
	await get_tree().process_frame
	get_tree().current_scene = null
	var started := Time.get_ticks_msec()
	_deadline_ms = started + int(_limit_seconds * 1000.0)
	for folder: String in ["unit", "integration", "smoke"]:
		if group != "" and group != folder:
			continue
		var dir := "res://tests/" + folder
		var files := Array(DirAccess.get_files_at(dir))
		files.sort()
		for file: String in files:
			if not file.ends_with(".gd") or (only != "" and not file.contains(only)):
				continue
			await _run_file(dir.path_join(file))
	var seconds := (Time.get_ticks_msec() - started) / 1000.0
	print("")
	for line in _report:
		print(line)
	print("")
	print("TESTS: %d passed, %d failed  (%.1fs)" % [_passed, _failed, seconds])
	get_tree().quit(0 if _failed == 0 else 1)


func _run_file(path: String) -> void:
	var script := load(path) as GDScript
	if script == null:
		_failed += 1
		_report.append("FAIL  %s  (script did not load)" % path)
		return
	var probe: Object = script.new()
	var methods: Array[String] = []
	for m: Dictionary in probe.get_method_list():
		var mname: String = m["name"]
		if mname.begins_with("test_") and not methods.has(mname):
			methods.append(mname)
	probe.free()
	for mname in methods:
		var tc: TestCase = script.new()
		tc.runner = self
		add_child(tc)
		_errors.take()
		await tc.before_each()
		await tc.call(mname)
		await tc.after_each()
		tc.release_all()
		Engine.time_scale = 1.0
		get_tree().paused = false
		Game.headless_test = true
		var logged := _errors.take()
		if not tc.expects_errors:
			for i in mini(logged.size(), 6):
				tc.failures.append("logged an error: " + logged[i])
			if logged.size() > 6:
				tc.failures.append("... and %d more errors" % (logged.size() - 6))
		var label := "%s :: %s" % [path.get_file().get_basename(), mname]
		if tc.failures.is_empty():
			_passed += 1
			_report.append("PASS  %s  (%d checks)" % [label, tc.checks])
		else:
			_failed += 1
			_report.append("FAIL  %s" % label)
			for f in tc.failures:
				_report.append("        - " + f)
		tc.queue_free()
		await get_tree().process_frame
