extends TestCase


func _confront(e: TurnEngine, o: Outbreak, approach: String, score: float, coins := 0) -> Dictionary:
	e.begin_confront(o.id, approach)
	var r := e.resolve_confront(score, coins)
	e.answer_court(false)
	return r


func test_victory_reduces_by_two() -> void:
	var cfg := fresh_config()
	cfg.balance["outbreaks"]["rancor"]["chance_on_force_win"] = 0.0
	var e := empty_engine(cfg)
	var o := add_outbreak(e, 4, Defs.NATURE_TRAPPOLA, Defs.FORZA)
	add_outbreak(e, 1, Defs.NATURE_TRAPPOLA)
	var r := _confront(e, o, Defs.FASCINO, 0.6)
	check_eq(r["outcome"], Defs.OUTCOME_VICTORY, "0.6 è vittoria")
	check_eq(o.intensity, 2, "vittoria: -2")


func test_victory_on_weakness_reduces_by_three() -> void:
	var e := empty_engine()
	var o := add_outbreak(e, 4, Defs.NATURE_ESTINGUE, Defs.FASCINO)
	add_outbreak(e, 1, Defs.NATURE_TRAPPOLA)
	_confront(e, o, Defs.FASCINO, 1.0)
	check_eq(o.intensity, 1, "debolezza: -3")


func test_victory_extinguishes() -> void:
	var e := empty_engine()
	var o := add_outbreak(e, 2, Defs.NATURE_ESTINGUE, Defs.FASCINO)
	add_outbreak(e, 1, Defs.NATURE_TRAPPOLA)
	var r := _confront(e, o, Defs.FASCINO, 0.9)
	check(r["extinguished"], "spento")
	check(not o.is_active(), "non più attivo")


func test_defeat_extra_days() -> void:
	var cases := {0.45: 1, 0.2: 2, 0.05: 3}
	for score in cases:
		var e := empty_engine()
		var o := add_outbreak(e, 2, Defs.NATURE_TRAPPOLA, Defs.FASCINO)
		_confront(e, o, Defs.FASCINO, score)
		check_eq(e.state.day, 1 + cases[score], "punteggio %s" % score)
		check_eq(o.intensity, 2, "la sconfitta non riduce")


func test_extra_days_apply_damage_each_day() -> void:
	var e := empty_engine()
	var o := add_outbreak(e, 3, Defs.NATURE_TRAPPOLA, Defs.FASCINO)
	_confront(e, o, Defs.FASCINO, 0.0)
	check_eq(e.state.stability, 60 - 9, "sconfitta netta: 3 giorni di danni")


func test_trap_wrong_approach_spawns() -> void:
	var e := empty_engine()
	var o := add_outbreak(e, 3, Defs.NATURE_TRAPPOLA, Defs.FASCINO)
	var r := _confront(e, o, Defs.RICCHEZZA, 1.0, 6)
	check_eq(r["spawned"].size(), 1, "un nuovo focolaio")
	var spawned := e.state.get_outbreak(r["spawned"][0])
	check_eq(spawned.intensity, 2, "intensità 2")
	check_eq(spawned.origin, "trappola", "origine")


func test_trap_right_approach_no_spawn() -> void:
	var e := empty_engine()
	var o := add_outbreak(e, 3, Defs.NATURE_TRAPPOLA, Defs.FASCINO)
	var r := _confront(e, o, Defs.FASCINO, 0.1)
	check_eq(r["spawned"].size(), 0, "nessun nuovo focolaio")


func test_force_victory_rancor() -> void:
	var cfg := fresh_config()
	cfg.balance["outbreaks"]["rancor"]["chance_on_force_win"] = 1.0
	var e := empty_engine(cfg)
	var o := add_outbreak(e, 4, Defs.NATURE_ESTINGUE, Defs.FORZA)
	var r := _confront(e, o, Defs.FORZA, 1.0)
	check_eq(r["spawned"].size(), 1, "rancore generato")
	var rancor := e.state.get_outbreak(r["spawned"][0])
	check_eq(rancor.type_id, "rancore", "tipo")
	check_eq(rancor.intensity, 1, "intensità 1")


func test_force_defeat_no_rancor() -> void:
	var cfg := fresh_config()
	cfg.balance["outbreaks"]["rancor"]["chance_on_force_win"] = 1.0
	var e := empty_engine(cfg)
	var o := add_outbreak(e, 4, Defs.NATURE_ESTINGUE, Defs.FORZA)
	var r := _confront(e, o, Defs.FORZA, 0.4)
	check_eq(r["spawned"].size(), 0, "niente rancore da una sconfitta")


func test_rancor_rate_close_to_config() -> void:
	var spawned := 0
	for seed_value in 400:
		var e := empty_engine(fresh_config(), seed_value)
		var o := add_outbreak(e, 4, Defs.NATURE_ESTINGUE, Defs.FASCINO)
		spawned += _confront(e, o, Defs.FORZA, 1.0)["spawned"].size()
	check(spawned > 80 and spawned < 160, "~30%% di 400, ottenuto %d" % spawned)


func test_max_active_cap() -> void:
	var cfg := fresh_config()
	cfg.balance["outbreaks"]["max_active"] = 2
	var e := empty_engine(cfg)
	var o := add_outbreak(e, 3, Defs.NATURE_TRAPPOLA, Defs.FASCINO)
	add_outbreak(e, 3, Defs.NATURE_TRAPPOLA)
	var r := _confront(e, o, Defs.FORZA, 0.0)
	check_eq(r["spawned"].size(), 0, "tetto raggiunto")


func test_wealth_spends_coins_even_on_failure() -> void:
	var e := empty_engine()
	var o := add_outbreak(e, 3, Defs.NATURE_ESTINGUE)
	_confront(e, o, Defs.RICCHEZZA, 0.0, 4)
	check_eq(e.state.queen.coins, 6, "monete perse comunque")


func test_cannot_use_wealth_without_coins() -> void:
	var e := empty_engine()
	var o := add_outbreak(e, 3, Defs.NATURE_ESTINGUE)
	e.state.queen.coins = 0
	check(not e.can_confront(o.id, Defs.RICCHEZZA), "senza monete niente Ricchezza")
	check(e.can_confront(o.id, Defs.FORZA), "la Forza resta disponibile")


func test_observe_reveals() -> void:
	var e := empty_engine()
	var o := add_outbreak(e, 3, Defs.NATURE_CRESCE, Defs.RICCHEZZA)
	var r := e.observe(o.id)
	check_eq(r["outbreak"]["nature"], Defs.NATURE_CRESCE, "natura rivelata")
	check_eq(r["outbreak"]["weakness"], Defs.RICCHEZZA, "debolezza rivelata")
	check(not r["reveals_next_card"], "Saggezza 3 non rivela la carta")
