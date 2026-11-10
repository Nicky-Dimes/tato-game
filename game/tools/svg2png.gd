extends SceneTree
## Dev helper: rasterise an SVG to PNG so generated art can be looked at.
##   godot --headless --path game -s res://tools/svg2png.gd -- <in.svg> <out.png> [scale]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("usage: -- <in.svg> <out.png> [scale]")
		quit(1)
		return
	var scale := 1.0
	if args.size() >= 3:
		scale = args[2].to_float()
	var bytes := FileAccess.get_file_as_bytes(args[0])
	var img := Image.new()
	var err := img.load_svg_from_buffer(bytes, scale)
	if err != OK:
		print("failed to load svg: ", error_string(err))
		quit(1)
		return
	img.save_png(args[1])
	print("wrote ", args[1], " ", img.get_width(), "x", img.get_height())
	quit(0)
