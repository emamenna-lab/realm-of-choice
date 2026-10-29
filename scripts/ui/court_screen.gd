extends Control
## Esito dello scontro, poi il disturbatore a corte con la sua proposta,\n## sotto la scena della sala del trono.

signal answered(respond: bool)

var engine: TurnEngine
var result: Dictionary


func setup(e: TurnEngine, confront_result: Dictionary) -> void:
	engine = e
	result = confront_result


## Altezza della scena della sala del trono rispetto allo schermo.
const SCENE_HEIGHT := 0.36


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiKit.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	add_child(_scene())

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.anchor_top = SCENE_HEIGHT - 0.03
	margin.offset_top = 0
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, UiKit.GUTTER)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(sc)
	var col := UiKit.vbox(20)
	sc.add_child(col)

	col.add_child(_outcome_panel())
	var intros: Array = engine.cfg.court["intros"]
	# Scelta stabile per carta e giorno, così rigiocare un seme mostra le stesse scene.
	var intro: String = intros[absi(hash([result["card"]["id"], engine.state.day])) % intros.size()]
	col.add_child(UiKit.label(intro, UiKit.FONT_SMALL, UiKit.DIM))

	var card: Dictionary = result["card"]
	var p := UiKit.panel(UiKit.PARCHMENT)
	var v := UiKit.vbox(12)
	v.add_child(UiKit.label("«%s»" % card["text"], UiKit.FONT_BODY, UiKit.INK))
	if card["label"] != "":
		v.add_child(UiKit.label("La tua saggezza vede oltre le parole: è %s." % UiKit.CARD_LABEL_NAMES[card["label"]], UiKit.FONT_SMALL, UiKit.GOLD))
	p.add_child(v)
	col.add_child(p)

	var cost := engine.cfg.i("disturber.respond_day_cost")
	col.add_child(UiKit.button("Accogli la proposta (costa %d giorno)" % cost, func(): answered.emit(true)))
	col.add_child(UiKit.button("Congedalo", func(): answered.emit(false)))


## La sala del trono in alto, con il Cortigiano che si inchina e gesticola; sfuma nello sfondo.
func _scene() -> Control:
	var area := Control.new()
	area.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	area.anchor_bottom = SCENE_HEIGHT
	area.clip_contents = true
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(Art.cover(Art.COURT))

	var tex := Art.texture(Art.COURTIER)
	if tex:
		var courtier := TextureRect.new()
		courtier.texture = tex
		courtier.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		courtier.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		courtier.mouse_filter = Control.MOUSE_FILTER_IGNORE
		courtier.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		courtier.anchor_top = 0.18
		courtier.anchor_left = 0.2
		courtier.anchor_right = 1.06
		courtier.anchor_bottom = 1.04
		area.add_child(courtier)
		courtier.resized.connect(func(): courtier.pivot_offset = Vector2(courtier.size.x * 0.5, courtier.size.y))
		# Un lieve ondeggiare, come chi parla con le mani.
		var sway := courtier.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		sway.tween_property(courtier, "rotation", 0.012, 1.4)
		sway.tween_property(courtier, "rotation", -0.008, 1.6)

	var fade := Art.fade(UiKit.BG, 0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	fade.anchor_top = 0.72
	fade.offset_top = 0
	area.add_child(fade)
	return area


func _outcome_panel() -> Control:
	var o := engine.state.get_outbreak(result["outbreak_id"])
	var name := UiKit.type_name(engine.cfg, o.type_id)
	var outcome: String = result["outcome"]
	var won := outcome == Defs.OUTCOME_VICTORY
	var p := UiKit.panel()
	var v := UiKit.vbox(10)
	v.add_child(UiKit.label(UiKit.OUTCOME_NAMES[outcome], UiKit.FONT_TITLE, UiKit.GOOD if won else UiKit.DANGER))
	if won:
		if result["extinguished"]:
			v.add_child(UiKit.label("%s si spegne." % name))
		else:
			v.add_child(UiKit.label("%s perde vigore: intensità %d di 5." % [name, o.intensity]))
	else:
		var extra := int(engine.cfg.value("resolution.extra_days")[outcome])
		var text := "%s resiste." % name
		if extra > 0:
			text += " Lo scontro ti costa %d giorn%s in più." % [extra, "o" if extra == 1 else "i"]
		v.add_child(UiKit.label(text))
	for id in result["spawned"]:
		var spawned := engine.state.get_outbreak(id)
		v.add_child(UiKit.label("Divampa %s." % UiKit.type_name(engine.cfg, spawned.type_id, true), UiKit.FONT_BODY, UiKit.DANGER))
	p.add_child(v)
	return p
