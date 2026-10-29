extends Control
## Esito dello scontro, poi il disturbatore a corte con la sua proposta.

signal answered(respond: bool)

var engine: TurnEngine
var result: Dictionary


func setup(e: TurnEngine, confront_result: Dictionary) -> void:
	engine = e
	result = confront_result


func _ready() -> void:
	var col := UiKit.screen_column(self, true)
	col.add_child(_outcome_panel())
	col.add_child(UiKit.label("A corte", UiKit.FONT_BODY, UiKit.GOLD))
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
			v.add_child(UiKit.label("%s perde vigore: intensità %s." % [name, UiKit.pips(o.intensity)]))
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
