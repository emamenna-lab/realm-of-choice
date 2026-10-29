extends TestCase


func test_collapse_ends_immediately() -> void:
	var e := empty_engine()
	e.state.stability = 4
	var o := add_outbreak(e, 5, Defs.NATURE_TRAPPOLA)
	e.observe(o.id)
	check_eq(e.state.result, Defs.RESULT_COLLAPSE, "stabilità a 0")
	check_eq(e.phase, TurnEngine.Phase.GAME_OVER, "fase finale")
	check_eq(e.state.day, 1, "finisce subito, senza avanzare")


func test_collapse_during_extra_days() -> void:
	var e := empty_engine()
	e.state.stability = 7
	var o := add_outbreak(e, 3, Defs.NATURE_TRAPPOLA, Defs.FORZA)
	e.begin_confront(o.id, Defs.FASCINO)
	e.resolve_confront(0.0)
	e.answer_court(false)
	check_eq(e.state.result, Defs.RESULT_COLLAPSE, "crollo al terzo giorno di danni")


func test_win_after_day_twelve() -> void:
	var e := empty_engine()
	var o := add_outbreak(e, 1, Defs.NATURE_TRAPPOLA)
	for n in 11:
		e.observe(o.id)
		check_eq(e.state.result, Defs.RESULT_NONE, "partita in corso al giorno %d" % e.state.day)
	e.observe(o.id)
	check_eq(e.state.result, Defs.RESULT_WIN, "60 - 12 = 48 >= 30")
	check_eq(e.state.day, 12, "il calendario si ferma al 12")


func test_weak_kingdom_loses_on_day_twelve() -> void:
	var e := empty_engine()
	var o := add_outbreak(e, 3, Defs.NATURE_TRAPPOLA)
	for n in 12:
		e.observe(o.id)
	check_eq(e.state.result, Defs.RESULT_WEAK, "60 - 36 = 24 < 30")


func test_extra_days_past_twelve_end_the_game() -> void:
	var e := empty_engine()
	var o := add_outbreak(e, 1, Defs.NATURE_TRAPPOLA, Defs.FORZA)
	for n in 10:
		e.observe(o.id)
	e.begin_confront(o.id, Defs.FASCINO)
	e.resolve_confront(0.0)
	e.answer_court(true)
	check_eq(e.state.result, Defs.RESULT_WIN, "fine al giorno 12 anche con giorni extra")
	check_eq(e.state.day, 12, "giorno finale")


func _court(e: TurnEngine, card_id: String, respond: bool) -> Outbreak:
	var o := add_outbreak(e, 3, Defs.NATURE_TRAPPOLA, Defs.FASCINO)
	force_next_card(e, card_id)
	e.begin_confront(o.id, Defs.FASCINO)
	e.resolve_confront(0.45)
	e.answer_court(respond)
	return o


func test_ignore_costs_no_day_respond_costs_one() -> void:
	var a := empty_engine()
	_court(a, "c01", false)
	check_eq(a.state.day, 2, "ignorare: solo il giorno dell'azione")
	var b := empty_engine()
	_court(b, "c01", true)
	check_eq(b.state.day, 3, "rispondere: un giorno in più")


func test_useful_card() -> void:
	var e := empty_engine()
	_court(e, "c01", true)
	check_eq(e.state.queen.get_stat(Defs.FORZA), 5, "utile: +2 Forza")


func test_useful_wealth_card_gives_coins() -> void:
	var e := empty_engine()
	_court(e, "c04", true)
	check_eq(e.state.queen.coins, 12, "utile su Ricchezza: +2 monete")


func test_ignored_useful_card_does_nothing() -> void:
	var e := empty_engine()
	_court(e, "c01", false)
	check_eq(e.state.queen.get_stat(Defs.FORZA), 3, "ignorata: nessun effetto")


func test_flattery_fades_after_two_days() -> void:
	var e := empty_engine()
	var o := _court(e, "c08", true)
	# Rispondere consuma il giorno dell'azione e quello della risposta: la lusinga è già svanita.
	check_eq(e.state.queen.get_stat(Defs.FASCINO), 3, "dopo 2 giorni svanisce")
	var e2 := empty_engine()
	var o2 := add_outbreak(e2, 3, Defs.NATURE_TRAPPOLA)
	e2.state.queen.add_modifier(Defs.FASCINO, 1, 2)
	check_eq(e2.state.queen.get_stat(Defs.FASCINO), 4, "+1 temporaneo")
	e2.observe(o2.id)
	check_eq(e2.state.queen.get_stat(Defs.FASCINO), 4, "ancora attivo dopo 1 giorno")
	e2.observe(o2.id)
	check_eq(e2.state.queen.get_stat(Defs.FASCINO), 3, "svanito dopo 2 giorni")


func test_poisoned_card_strikes_after_two_days() -> void:
	var cfg := fresh_config()
	cfg.balance["disturber"]["poisoned_outbreak_chance"] = 0.0
	var e := empty_engine(cfg)
	_court(e, "c12", true)
	# L'avvelenata su Forza dà +2 subito; dopo 2 giorni un'altra stat cala di 2 (minimo 1).
	check_eq(e.state.queen.get_stat(Defs.FORZA), 5, "+2 Forza resta")
	var fasc := e.state.queen.get_stat(Defs.FASCINO)
	var sagg := e.state.queen.get_stat(Defs.SAGGEZZA)
	check(fasc == 1 or sagg == 1, "un'altra stat è calata: fascino %d, saggezza %d" % [fasc, sagg])
	check(e.state.pending_effects.is_empty(), "effetto consumato")


func test_poisoned_card_can_spawn_outbreak() -> void:
	var cfg := fresh_config()
	cfg.balance["disturber"]["poisoned_outbreak_chance"] = 1.0
	var e := empty_engine(cfg)
	_court(e, "c12", true)
	var poison := e.state.outbreaks.filter(func(o): return o.origin == "veleno")
	check_eq(poison.size(), 1, "nuovo focolaio dal veleno")


func test_provocation() -> void:
	var a := empty_engine()
	_court(a, "c17", false)
	check_eq(a.state.queen.get_stat(Defs.FASCINO), 2, "ignorata: -1 Fascino")
	var b := empty_engine()
	_court(b, "c17", true)
	check_eq(b.state.queen.get_stat(Defs.FORZA), 4, "risposta: +1 Forza")
	check_eq(b.state.day, 3, "risposta: perde il giorno")


func test_high_wisdom_reveals_next_card() -> void:
	var e := empty_engine()
	e.state.queen.base[Defs.SAGGEZZA] = 6
	var o := add_outbreak(e, 3, Defs.NATURE_TRAPPOLA, Defs.FASCINO)
	check(e.observe(o.id)["reveals_next_card"], "Saggezza 6 rivela")
	force_next_card(e, "c12")
	e.begin_confront(o.id, Defs.FASCINO)
	var r := e.resolve_confront(0.45)
	check_eq(r["card"]["label"], Defs.CARD_POISONED, "etichetta visibile")
	e.answer_court(false)
	force_next_card(e, "c12")
	e.begin_confront(o.id, Defs.FASCINO)
	check_eq(e.resolve_confront(0.45)["card"]["label"], "", "solo la carta successiva")


func test_card_label_hidden_by_default() -> void:
	var e := empty_engine()
	var o := add_outbreak(e, 3, Defs.NATURE_TRAPPOLA)
	e.begin_confront(o.id, Defs.FASCINO)
	check_eq(e.resolve_confront(0.45)["card"]["label"], "", "etichetta nascosta")
