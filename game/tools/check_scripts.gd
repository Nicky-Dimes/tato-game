extends Node
## Loads every script, scene and resource in the project and reports the ones
## that fail to parse or load.  Exit code 1 on any failure.
## Runs as a scene (not with -s) so the autoload singletons exist:
##   godot --headless --path game res://tools/CheckScripts.tscn

var _bad := 0
var _count := 0


func _ready() -> void:
	_scan("res://")
	print("checked %d files, %d problem(s)" % [_count, _bad])
	get_tree().quit(1 if _bad > 0 else 0)


func _scan(dir: String) -> void:
	for sub in DirAccess.get_directories_at(dir):
		if sub.begins_with("."):
			continue
		_scan(dir.path_join(sub))
	for file in DirAccess.get_files_at(dir):
		var ext := file.get_extension()
		if ext in ["gd", "tscn", "tres"]:
			_count += 1
			var path := dir.path_join(file)
			var res: Resource = load(path)
			if res == null:
				_bad += 1
				print("FAILED: ", path)
			elif res is GDScript and not (res as GDScript).can_instantiate():
				_bad += 1
				print("CANNOT INSTANTIATE: ", path)
