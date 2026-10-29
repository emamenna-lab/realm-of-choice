extends Control
## La città: giorno, stabilità, statistiche, resoconto della notte e focolai.
## Toccare un focolaio apre il pannello delle azioni.

signal observe_requested(outbreak_id: int)
signal confront_requested(outbreak_id: int, approach: String)
signal wait_requested

var engine: TurnEngine
var report: Array[String] = []
var _sheet: Control


func setup(e: TurnEngine, night_report: Array[String]) -> void:
	engine = e
	report = night_report


func _ready() -> void:
	var s := engine.state
	var col := UiKit.screen_column(self, true)

	var header := HBoxContainer.new()
	header.add_child(UiKit.label("Giorno %d di %d" % [s.day, engine.cfg.i("days_total")], UiKit.FONT_TITLE, UiKit.GOLD))
	var seed_label := UiKit.label("seme %d" % s.seed_value, UiKit.FONT_SMALL, UiKit.DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	seed_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(seed_label)
	col.add_child(header)

	col.add_child(_stability_panel())
	col.add_child(_stats_label())

	if not report.is_empty():
		var p := UiKit.panel(UiKit.PARCHMENT)
		var v := UiKit.vbox(8)
		for line in report:
			v.add_child(UiKit.label(line, UiKit.FONT_SMALL, UiKit.INK))
		p.add_child(v)
		col.add_child(p)

	col.add_child(UiKit.label("I focolai", UiKit.FONT_BODY, UiKit.GOLD))
	var active := s.active_outbreaks()
	if active.is_empty():
		col.add_child(UiKit.label("Per ora la città tace.", UiKit.FONT_BODY, UiKit.DIM))
		col.add_child(UiKit.button("Attendi l'alba", func(): wait_requested.emit()))
	for o in active:
		col.add_child(_outbreak_card(o))


func _stability_panel() -> Control:
	var s := engine.state
	var v := UiKit.vbox(6)
	var threshold := engine.cfg.i("stability.win_threshold")
	var color := UiKit.INK if s.stability >= threshold else UiKit.DANGER
	v.add_child(UiKit.label("Stabilità del regno: %d   (soglia %d)" % [s.stability, threshold], UiKit.FONT_BODY, color))
	var bar := ProgressBar.new()
	bar.max_value = engine.cfg.i("stability.max")
	bar.value = s.stability
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 28)
	v.add_child(bar)
	return v


func _stats_label() -> Label:
	var q := engine.state.queen
	var parts: Array[String] = []
	for stat in [Defs.FORZA, Defs.FASCINO, Defs.SAGGEZZA]:
		var bonus := q.get_stat(stat) - clampi(q.base[stat], q.stat_min, q.stat_max)
		parts.append("%s %d%s" % [UiKit.APPROACH_NAMES[stat], q.get_stat(stat), " (+%d)" % bonus if bonus > 0 else ""])
	parts.append("Monete %d" % q.coins)
	return UiKit.label("  ·  ".join(parts), UiKit.FONT_SMALL, UiKit.DIM)


func _outbreak_card(o: Outbreak) -> Control:
	# Un pulsante che contiene un'intera scheda: tutta la superficie è toccabile.
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# PASS: il trascinamento arriva anche allo ScrollContainer, così la lista scorre al tocco.
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.pressed.connect(_open_sheet.bind(o.id))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	var v := UiKit.vbox(6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(UiKit.label(UiKit.type_name(engine.cfg, o.type_id), UiKit.FONT_BODY, UiKit.GOLD))
	v.add_child(UiKit.intensity_row(o.intensity))
	if o.revealed:
		v.add_child(UiKit.label("%s · debolezza: %s" % [UiKit.NATURE_NAMES[o.nature], UiKit.APPROACH_NAMES[o.weakness]], UiKit.FONT_SMALL, UiKit.DIM))
	else:
		v.add_child(UiKit.label("Natura e debolezza ignote", UiKit.FONT_SMALL, UiKit.DIM))
	margin.add_child(v)
	b.add_child(margin)
	# Il pulsante non dimensiona i figli: gli diamo l'altezza del contenuto.
	b.custom_minimum_size = Vector2(0, 200 if o.revealed else 190)
	return b


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
