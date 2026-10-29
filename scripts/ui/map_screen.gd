extends Control
## La città vista dal balcone: la regina, i focolai sul dipinto, in alto giorno e stabilità,
## in basso il resoconto della notte. Toccare un emblema apre il pannello delle azioni.

signal observe_requested(outbreak_id: int)
signal confront_requested(outbreak_id: int, approach: String)
signal wait_requested

const OutbreakMarker := preload("res://scripts/ui/outbreak_marker.gd")
const QueenShader := preload("res://scripts/ui/queen_idle.gdshader")

## Posti dei focolai sul dipinto della città, in coordinate 0..1 dell'immagine.
## Evitano il cielo sotto la barra in alto, la regina in basso a sinistra e il balcone.
const SLOTS: Array[Vector2] = [
	Vector2(0.60, 0.60), Vector2(0.20, 0.40), Vector2(0.84, 0.46), Vector2(0.50, 0.26),
	Vector2(0.84, 0.68), Vector2(0.38, 0.52), Vector2(0.15, 0.24), Vector2(0.84, 0.29),
]
## Altezza della regina rispetto allo schermo.
const QUEEN_HEIGHT := 0.40

var engine: TurnEngine
var report: Array[String] = []
var _sheet: Control
var _markers: Array[Control] = []
var _queen: TextureRect
var _map_size := Vector2(768, 1376)


func setup(e: TurnEngine, night_report: Array[String]) -> void:
	engine = e
	report = night_report


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiKit.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var map := Art.cover(Art.MAP)
	if map.texture:
		_map_size = map.texture.get_size()
	add_child(map)

	var slots := _assign_slots()
	for o in engine.state.active_outbreaks():
		var m: Control = OutbreakMarker.new()
		m.setup(engine.cfg, o)
		m.set_meta("slot", slots[o.id])
		m.tapped.connect(_open_sheet)
		add_child(m)
		_markers.append(m)

	var queen_tex := Art.texture(Art.QUEEN)
	if queen_tex:
		_queen = TextureRect.new()
		_queen.texture = queen_tex
		_queen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_queen.stretch_mode = TextureRect.STRETCH_SCALE
		_queen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = QueenShader
		mat.set_shader_parameter("aspect", queen_tex.get_width() / float(queen_tex.get_height()))
		_queen.material = mat
		add_child(_queen)

	add_child(_hud())
	add_child(_bottom())
	resized.connect(_layout)
	_layout()


## Ogni focolaio tiene lo stesso posto per tutta la partita: preferisce il posto id % 8,
## altrimenti il primo libero dopo di esso.
func _assign_slots() -> Dictionary:
	var taken := {}
	var result := {}
	for o in engine.state.active_outbreaks():
		var i := o.id % SLOTS.size()
		while taken.has(i):
			i = (i + 1) % SLOTS.size()
		taken[i] = true
		result[o.id] = i
	return result


func _layout() -> void:
	for m in _markers:
		m.position = Art.cover_point(_map_size, size, SLOTS[m.get_meta("slot")])
	if _queen:
		var h := size.y * QUEEN_HEIGHT
		var w := h * _queen.texture.get_width() / _queen.texture.get_height()
		_queen.size = Vector2(w, h)
		_queen.position = Vector2(0, size.y - h)


func _hud() -> Control:
	var s := engine.state
	var p := UiKit.panel(Color(0.07, 0.05, 0.04, 0.78))
	p.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	p.offset_left = UiKit.GUTTER / 2
	p.offset_right = -UiKit.GUTTER / 2
	p.offset_top = 24
	var v := UiKit.vbox(8)
	var header := HBoxContainer.new()
	header.add_child(UiKit.label("Giorno %d di %d" % [s.day, engine.cfg.i("days_total")], UiKit.FONT_BODY + 4, UiKit.GOLD))
	var seed_label := UiKit.label("seme %d" % s.seed_value, UiKit.FONT_SMALL - 4, UiKit.DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	seed_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(seed_label)
	v.add_child(header)
	v.add_child(_stability_panel())
	v.add_child(_stats_label())
	p.add_child(v)
	return p


## Resoconto della notte sul balcone, a destra della regina; si chiude toccandolo.
## Se la città tace, al suo posto c'è il comando per attendere.
func _bottom() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.anchor_left = 0.36
	box.offset_left = 0
	box.offset_right = -UiKit.GUTTER / 2
	box.offset_bottom = -32
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not report.is_empty():
		var p := UiKit.panel(Color(0.07, 0.05, 0.04, 0.82))
		var v := UiKit.vbox(8)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for line in report:
			v.add_child(UiKit.label(line, UiKit.FONT_SMALL - 2, UiKit.INK))
		v.add_child(UiKit.label("tocca per chiudere", UiKit.FONT_SMALL - 6, UiKit.DIM, HORIZONTAL_ALIGNMENT_RIGHT))
		p.add_child(v)
		p.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed:
				var fade := p.create_tween()
				fade.tween_property(p, "modulate:a", 0.0, 0.25)
				fade.tween_callback(p.queue_free))
		box.add_child(p)
	if engine.state.active_outbreaks().is_empty():
		box.add_child(Art.shadowed_label("Per ora la città tace.", UiKit.FONT_BODY, UiKit.INK))
		box.add_child(UiKit.button("Attendi l'alba", func(): wait_requested.emit()))
	return box


func _stability_panel() -> Control:
	var s := engine.state
	var v := UiKit.vbox(6)
	var threshold := engine.cfg.i("stability.win_threshold")
	var color := UiKit.INK if s.stability >= threshold else UiKit.DANGER
	v.add_child(UiKit.label("Stabilità del regno: %d   (soglia %d)" % [s.stability, threshold], UiKit.FONT_SMALL, color))
	var bar := ProgressBar.new()
	bar.max_value = engine.cfg.i("stability.max")
	bar.value = s.stability
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 20)
	v.add_child(bar)
	return v


func _stats_label() -> Label:
	var q := engine.state.queen
	var parts: Array[String] = []
	for stat in [Defs.FORZA, Defs.FASCINO, Defs.SAGGEZZA]:
		var bonus := q.get_stat(stat) - clampi(q.base[stat], q.stat_min, q.stat_max)
		parts.append("%s %d%s" % [UiKit.APPROACH_NAMES[stat], q.get_stat(stat), " (+%d)" % bonus if bonus > 0 else ""])
	parts.append("Monete %d" % q.coins)
	return UiKit.label("  ·  ".join(parts), UiKit.FONT_SMALL - 2, UiKit.DIM)


func _open_sheet(outbreak_id: int) -> void:
	var o := engine.state.get_outbreak(outbreak_id)
	var q := engine.state.queen
	_sheet = Control.new()
	_sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sheet.add_child(shade)

	var p := UiKit.panel(UiKit.PARCHMENT)
	p.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var v := UiKit.vbox(16)
	var type_def := engine.cfg.type_by_id(o.type_id)
	v.add_child(UiKit.label(type_def.get("name", o.type_id), UiKit.FONT_TITLE, UiKit.GOLD))
	v.add_child(UiKit.label(type_def.get("description", ""), UiKit.FONT_BODY, UiKit.INK))
	v.add_child(UiKit.intensity_row(o.intensity))

	v.add_child(UiKit.label("Affrontalo con…", UiKit.FONT_SMALL, UiKit.DIM))
	v.add_child(UiKit.button("Forza (%d)" % q.get_stat(Defs.FORZA), _confront.bind(o.id, Defs.FORZA), engine.can_confront(o.id, Defs.FORZA)))
	v.add_child(UiKit.button("Ricchezza (%d monete)" % q.coins, _confront.bind(o.id, Defs.RICCHEZZA), engine.can_confront(o.id, Defs.RICCHEZZA)))
	v.add_child(UiKit.button("Fascino (%d)" % q.get_stat(Defs.FASCINO), _confront.bind(o.id, Defs.FASCINO), engine.can_confront(o.id, Defs.FASCINO)))
	v.add_child(UiKit.label("…oppure", UiKit.FONT_SMALL, UiKit.DIM))
	var observe_text := "Osserva con Saggezza (%d)" % q.get_stat(Defs.SAGGEZZA)
	v.add_child(UiKit.button(observe_text if not o.revealed else "Già osservato", _observe.bind(o.id), not o.revealed))
	v.add_child(UiKit.button("Indietro", _close_sheet))
	p.add_child(v)
	_sheet.add_child(p)
	add_child(_sheet)


func _close_sheet() -> void:
	if _sheet:
		_sheet.queue_free()
		_sheet = null


func _confront(outbreak_id: int, approach: String) -> void:
	confront_requested.emit(outbreak_id, approach)


func _observe(outbreak_id: int) -> void:
	observe_requested.emit(outbreak_id)
