class_name UITheme
extends RefCounted
## One look for every menu: rounded cream panels, plum outlines, warm buttons.
## Built in code so the whole UI shares the same recipe and scales cleanly.

const PLUM := Color("301444")
const PLUM_SOFT := Color("5b3a78")
const CREAM := Color("fff9ef")
const CREAM_DARK := Color("f3e6d2")
const PEACH := Color("ffd9a8")
const ORANGE := Color("ff9a1f")
const ORANGE_DARK := Color("e8721a")
const YELLOW := Color("ffcf3f")
const PINK := Color("f5a2a8")
const LILAC := Color("dcc7f0")
const SKY := Color("8fd0f5")
const GREEN := Color("6fc96a")
const RED := Color("f0452e")
const WHITE := Color(1, 1, 1)

const FONT_PATH := "res://assets/fonts/Fredoka.ttf"

static var _theme: Theme
static var _font_regular: Font
static var _font_bold: Font
static var _font_title: Font


static func _make_font(weight: int) -> Font:
	if not ResourceLoader.exists(FONT_PATH):
		return ThemeDB.fallback_font
	var base := load(FONT_PATH) as Font
	if base == null:
		return null
	var fv := FontVariation.new()
	fv.base_font = base
	var tag := TextServerManager.get_primary_interface().name_to_tag("wght")
	fv.variation_opentype = {tag: weight}
	return fv


static func font_regular() -> Font:
	if _font_regular == null:
		_font_regular = _make_font(500)
	return _font_regular


static func font_bold() -> Font:
	if _font_bold == null:
		_font_bold = _make_font(600)
	return _font_bold


static func font_title() -> Font:
	if _font_title == null:
		_font_title = _make_font(700)
	return _font_title


static func box(bg: Color, border: Color = PLUM, radius: int = 18, border_w: int = 4, shadow: bool = true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 18.0
	sb.content_margin_right = 18.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	sb.anti_aliasing = true
	if shadow:
		sb.shadow_color = Color(PLUM.r, PLUM.g, PLUM.b, 0.28)
		sb.shadow_size = 0
		sb.shadow_offset = Vector2(0, 5)
		sb.border_width_bottom = border_w + 3
	return sb


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	var regular := font_regular()
	var bold := font_bold()
	if regular:
		t.default_font = regular
	t.default_font_size = 24

	# Labels
	t.set_color("font_color", "Label", PLUM)
	t.set_font_size("font_size", "Label", 24)

	# Buttons
	var normal := box(YELLOW)
	var hover := box(Color("ffe07a"))
	var pressed := box(ORANGE)
	pressed.border_width_bottom = 4
	pressed.content_margin_top = 13.0
	pressed.content_margin_bottom = 7.0
	var focus := box(Color(0, 0, 0, 0), Color("ffffff"), 20, 4, false)
	focus.draw_center = false
	focus.expand_margin_left = 4.0
	focus.expand_margin_right = 4.0
	focus.expand_margin_top = 4.0
	focus.expand_margin_bottom = 4.0
	var disabled := box(Color("e6dccb"), Color("a99bb8"))
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_color("font_color", "Button", PLUM)
	t.set_color("font_hover_color", "Button", PLUM)
	t.set_color("font_pressed_color", "Button", PLUM)
	t.set_color("font_focus_color", "Button", PLUM)
	t.set_color("font_disabled_color", "Button", Color("9b8fa6"))
	t.set_font_size("font_size", "Button", 28)
	if bold:
		t.set_font("font", "Button", bold)

	# Panels
	t.set_stylebox("panel", "PanelContainer", box(CREAM, PLUM, 26, 5))
	t.set_stylebox("panel", "Panel", box(CREAM, PLUM, 26, 5))

	# CheckButton / CheckBox reuse button fonts
	for cls: String in ["CheckButton", "CheckBox", "OptionButton"]:
		t.set_color("font_color", cls, PLUM)
		t.set_color("font_hover_color", cls, PLUM)
		t.set_color("font_pressed_color", cls, PLUM)
		t.set_color("font_focus_color", cls, PLUM)
		t.set_font_size("font_size", cls, 24)
		t.set_stylebox("focus", cls, focus)
	t.set_stylebox("normal", "OptionButton", box(CREAM_DARK, PLUM, 14, 3, false))
	t.set_stylebox("hover", "OptionButton", box(PEACH, PLUM, 14, 3, false))
	t.set_stylebox("pressed", "OptionButton", box(PEACH, PLUM, 14, 3, false))

	# Sliders
	var groove := StyleBoxFlat.new()
	groove.bg_color = Color("e2d3c0")
	groove.set_corner_radius_all(8)
	groove.content_margin_top = 8.0
	groove.content_margin_bottom = 8.0
	groove.border_color = PLUM
	groove.set_border_width_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ORANGE
	fill.set_corner_radius_all(8)
	fill.border_color = PLUM
	fill.set_border_width_all(3)
	t.set_stylebox("slider", "HSlider", groove)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)

	# Scroll / tabs / progress
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color("e2d3c0")
	bar_bg.set_corner_radius_all(10)
	bar_bg.border_color = PLUM
	bar_bg.set_border_width_all(3)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = GREEN
	bar_fill.set_corner_radius_all(10)
	bar_fill.border_color = PLUM
	bar_fill.set_border_width_all(3)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	t.set_stylebox("fill", "ProgressBar", bar_fill)
	t.set_color("font_color", "ProgressBar", PLUM)

	t.set_stylebox("panel", "TooltipPanel", box(CREAM, PLUM, 10, 3, false))
	t.set_color("font_color", "TooltipLabel", PLUM)

	t.set_color("default_color", "RichTextLabel", PLUM)
	t.set_font_size("normal_font_size", "RichTextLabel", 24)
	t.set_font_size("bold_font_size", "RichTextLabel", 24)
	if regular:
		t.set_font("normal_font", "RichTextLabel", regular)
	if bold:
		t.set_font("bold_font", "RichTextLabel", bold)

	_theme = t
	return t


## A heading label with the chunky outlined look of the logo.
static func title_label(text: String, size: int = 44, color: Color = YELLOW) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", PLUM)
	l.add_theme_constant_override("outline_size", maxi(3, int(size * 0.12)))
	if font_title():
		l.add_theme_font_override("font", font_title())
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


static func label(text: String, size: int = 24, color: Color = PLUM, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold and font_bold():
		l.add_theme_font_override("font", font_bold())
	return l


## White text with a plum outline: readable over any gameplay background.
static func outlined_label(text: String, size: int = 24, color: Color = WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", PLUM)
	l.add_theme_constant_override("outline_size", maxi(3, int(size * 0.15)))
	if font_bold():
		l.add_theme_font_override("font", font_bold())
	return l


static func button(text: String, min_size: Vector2 = Vector2(280, 64)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			b.grab_focus())
	b.focus_entered.connect(func() -> void: AudioService.ui("ui_move", -10.0))
	b.pressed.connect(func() -> void: AudioService.ui("ui_select"))
	return b


static func small_button(text: String) -> Button:
	var b := button(text, Vector2(120, 52))
	b.add_theme_font_size_override("font_size", 22)
	return b


static func panel(bg: Color = CREAM) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, PLUM, 26, 5))
	return p
