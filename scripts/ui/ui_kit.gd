class_name UiKit
extends RefCounted
## Tema, colori e piccoli costruttori di nodi condivisi da tutte le schermate.
## L'interfaccia è costruita da codice: scene minime, niente da sincronizzare a mano nell'editor.

const BG := Color("1b1511")
const PANEL := Color("2a211a")
const PARCHMENT := Color("3a2e22")
const GOLD := Color("d9b35b")
const INK := Color("f2e8d5")
const DIM := Color("a89f8e")
const DANGER := Color("d0654c")
const GOOD := Color("8fbf6f")

const FONT_BODY := 30
const FONT_SMALL := 24
const FONT_TITLE := 44
const BUTTON_HEIGHT := 104
const GUTTER := 32

const APPROACH_NAMES := {"forza": "Forza", "ricchezza": "Ricchezza", "fascino": "Fascino", "saggezza": "Saggezza"}
const NATURE_NAMES := {"estingue": "Si estingue da sé", "cresce": "Cresce se ignorato", "trappola": "Trappola"}
const OUTCOME_NAMES := {
	"vittoria": "Vittoria",
	"sconfitta_lieve": "Sconfitta lieve",
	"sconfitta_media": "Sconfitta",
	"sconfitta_netta": "Disfatta",
}
const CARD_LABEL_NAMES := {
	"utile": "un consiglio sincero",
	"lusinga": "una lusinga che svanirà presto",
	"avvelenata": "un dono avvelenato",
	"provocazione": "una provocazione",
}


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = FONT_BODY

	t.set_stylebox("normal", "Button", _box(Color("4a3a2a"), GOLD, 2))
	t.set_stylebox("hover", "Button", _box(Color("5a4732"), GOLD, 2))
	t.set_stylebox("pressed", "Button", _box(Color("6b5539"), GOLD, 3))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	t.set_stylebox("disabled", "Button", _box(Color("2e261f"), Color("5a4d3c"), 2))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(state, "Button", INK)
	t.set_color("font_disabled_color", "Button", Color("6e6455"))

	t.set_color("font_color", "Label", INK)
	t.set_stylebox("panel", "PanelContainer", _box(PANEL, Color("4d3d2c"), 1))

	t.set_stylebox("normal", "LineEdit", _box(Color("120e0b"), Color("5a4d3c"), 2))
	t.set_stylebox("focus", "LineEdit", _box(Color("120e0b"), GOLD, 2))
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_placeholder_color", "LineEdit", Color("6e6455"))

	var bar_bg := _box(Color("120e0b"), Color("5a4d3c"), 1)
	var bar_fill := _box(GOLD, GOLD, 0)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	t.set_stylebox("fill", "ProgressBar", bar_fill)

	t.set_stylebox("slider", "HSlider", _box(Color("120e0b"), Color("5a4d3c"), 1, 8))
	t.set_constant("center_grabber", "HSlider", 1)
	return t


static func _box(bg: Color, border: Color, border_width: int, padding := 20) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(14)
	s.set_content_margin_all(padding)
	return s


## Sfondo + margini + colonna verticale. Restituisce la colonna in cui aggiungere i contenuti.
static func screen_column(screen: Control, scroll := false) -> VBoxContainer:
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", GUTTER)
	margin.add_theme_constant_override("margin_right", GUTTER)
	margin.add_theme_constant_override("margin_top", 56)
	margin.add_theme_constant_override("margin_bottom", 40)
	screen.add_child(margin)

	var column := vbox(20)
	if scroll:
		var sc := ScrollContainer.new()
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		margin.add_child(sc)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(column)
	else:
		margin.add_child(column)
	return column


static func label(text: String, size := FONT_BODY, color := INK, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func title(text: String) -> Label:
	var l := label(text, FONT_TITLE, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	return l


static func button(text: String, on_pressed: Callable, enabled := true) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.disabled = not enabled
	b.pressed.connect(on_pressed)
	return b


static func panel(bg := PANEL) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(bg, Color("4d3d2c"), 1, 24))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


static func vbox(separation := 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separation)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return v


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


## "Intensità" seguita da cinque pallini disegnati (non glifi: il font web non li ha).
static func intensity_row(intensity: int, max_value := 5, centered := false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if centered:
		row.alignment = BoxContainer.ALIGNMENT_CENTER
	var l := label("Intensità ", FONT_BODY, INK)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(l)
	for n in max_value:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(24, 24)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(12)
		style.bg_color = INK if n < intensity else Color(0, 0, 0, 0)
		style.border_color = INK
		style.set_border_width_all(2)
		dot.add_theme_stylebox_override("panel", style)
		row.add_child(dot)
	return row


static func type_name(cfg: GameConfig, type_id: String, inline := false) -> String:
	return cfg.type_name(type_id, inline)
