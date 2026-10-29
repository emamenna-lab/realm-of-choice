class_name Art
extends RefCounted
## Immagini del gioco e piccoli costruttori grafici. I file in assets/ escono da
## tools/prepare_assets.py; se un'immagine manca la schermata funziona lo stesso, senza.

const MAP := "res://assets/bg_map.jpg"
const COURT := "res://assets/bg_court.jpg"
const COURTIER := "res://assets/courtier.png"
const QUEEN := "res://assets/queen.png"

static var _glow: Texture2D


static func texture(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


static func emblem(type_id: String) -> Texture2D:
	return texture("res://assets/outbreak_%s.png" % type_id)


## Sfondo che copre tutto il genitore senza deformarsi (i bordi in eccesso vengono tagliati).
static func cover(path: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = texture(path)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return r


## Dove cade, sullo schermo, il punto (u, v) di un'immagine disegnata con cover() in un'area grande view.
static func cover_point(image_size: Vector2, view: Vector2, uv: Vector2) -> Vector2:
	var s := maxf(view.x / image_size.x, view.y / image_size.y)
	var offset := (view - image_size * s) / 2
	return offset + uv * image_size * s


## Macchia di luce radiale, bianca: si colora con modulate.
static func glow_texture() -> Texture2D:
	if _glow == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1, 0.5)
		t.width = 128
		t.height = 128
		_glow = t
	return _glow


## Sfumatura verticale da trasparente a colore, per far sfumare un'immagine nello sfondo.
static func fade(color: Color, height: float, downward := true) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, Color(color, 0) if downward else color)
	g.set_color(1, color if downward else Color(color, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	t.width = 4
	t.height = 64
	var r := TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.custom_minimum_size = Vector2(0, height)
	return r


## Etichetta leggibile sopra un dipinto: contorno scuro attorno alle lettere.
static func shadowed_label(text: String, size := UiKit.FONT_SMALL, color := UiKit.INK) -> Label:
	var l := UiKit.label(text, size, color, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 8)
	return l


## Solo i cinque pallini dell'intensità, centrati e con un bordo scuro.
static func dots(intensity: int, max_value := 5) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for n in max_value:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(18, 18)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(9)
		style.bg_color = UiKit.GOLD if n < intensity else Color(0, 0, 0, 0.55)
		style.border_color = Color(0.08, 0.05, 0.03)
		style.set_border_width_all(2)
		dot.add_theme_stylebox_override("panel", style)
		row.add_child(dot)
	return row
