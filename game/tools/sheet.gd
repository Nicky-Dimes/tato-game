extends SceneTree
## Dev helper: montage of SVG/PNG pictures onto one sheet for review.
##   godot --headless --path game -s res://tools/sheet.gd -- <out.png> <cell> <cols> <bg hex> <folder> [name filter]

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var out := a[0]
	var cell := a[1].to_int()
	var cols := a[2].to_int()
	var bg := Color(a[3])
	# a[4] is a folder (res:// or absolute); optional a[5] = text the file name must contain
	var files: Array = []
	var dir := a[4]
	var needle := a[5] if a.size() > 5 else ""
	var names := Array(DirAccess.get_files_at(dir))
	names.sort()
	for n: String in names:
		if (n.ends_with(".svg") or n.ends_with(".png")) and (needle == "" or n.contains(needle)):
			files.append(dir.path_join(n))
	var rows := int(ceil(files.size() / float(cols)))
	var sheet := Image.create(cols * cell, rows * cell, false, Image.FORMAT_RGBA8)
	sheet.fill(bg)
	for i in files.size():
		var img := Image.new()
		var path: String = files[i]
		var err := OK
		if path.ends_with(".svg"):
			err = img.load_svg_from_buffer(FileAccess.get_file_as_bytes(path), 1.0)
		else:
			err = img.load(path)
		if err != OK:
			print("skip ", path)
			continue
		img.convert(Image.FORMAT_RGBA8)
		var k := minf(float(cell - 8) / img.get_width(), float(cell - 8) / img.get_height())
		if k < 1.0:
			img.resize(int(img.get_width() * k), int(img.get_height() * k), Image.INTERPOLATE_LANCZOS)
		var pos := Vector2i((i % cols) * cell + (cell - img.get_width()) / 2, (i / cols) * cell + (cell - img.get_height()) / 2)
		sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), pos)
	sheet.save_png(out)
	print("wrote ", out)
	quit(0)
