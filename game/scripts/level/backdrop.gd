class_name Backdrop
extends Node2D
## The scenery behind a stage: a sky gradient, drifting clouds and two or
## three parallax layers per world theme. A handful of big quads, so it is
## cheap to draw on phones.

const SKIES := {
	"picnic": [Color("7cc7f5"), Color("d9f3ff")],
	"nest": [Color("8fd0f5"), Color("fff0d9")],
	"farm": [Color("f7b267"), Color("ffe9b8")],
	"fair": [Color("6f8fd9"), Color("e3ecff")],
	"market": [Color("56b7c9"), Color("ffe6c7")],
	"marsh": [Color("1d1f4a"), Color("3f4a8c")],
	"kitchen": [Color("4a3566"), Color("c98f6a")],
}

var theme := "picnic"


func setup(theme_name: String, level_size: Vector2) -> void:
	theme = theme_name
	z_index = -50
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	add_child(sky_layer)
	var colors: Array = SKIES.get(theme, SKIES["picnic"])
	var grad := Gradient.new()
	grad.set_color(0, colors[0])
	grad.set_color(1, colors[1])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 4
	tex.height = 128
	var rect := TextureRect.new()
	rect.texture = tex
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky_layer.add_child(rect)

	_add_layer("bg/%s_clouds" % theme, Vector2(0.06, 0.04), level_size.y - 760.0, 1.4, Vector2(-7.0, 0.0))
	_add_layer("bg/%s_far" % theme, Vector2(0.16, 0.5), level_size.y - 560.0, 1.5, Vector2.ZERO)
	_add_layer("bg/%s_mid" % theme, Vector2(0.36, 0.75), level_size.y - 430.0, 1.3, Vector2.ZERO)


func _add_layer(short: String, scroll: Vector2, top_y: float, scale_by: float, autoscroll: Vector2) -> void:
	var tex := Art.tex(short)
	if tex == null:
		return
	var px := Parallax2D.new()
	px.scroll_scale = scroll
	px.repeat_size = Vector2(tex.get_width() * scale_by, 0)
	px.repeat_times = 4
	if autoscroll != Vector2.ZERO and not Settings.flag("reduced_motion"):
		px.autoscroll = autoscroll
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.scale = Vector2(scale_by, scale_by)
	# keep each layer sitting at the bottom of the stage whatever its parallax
	s.position = Vector2(0, top_y * scroll.y)
	px.add_child(s)
	add_child(px)
