extends TestCase


func test_config_is_valid() -> void:
	var cfg := GameConfig.load_default()
	check(cfg.is_valid(), "errori di configurazione: %s" % str(cfg.errors))
	check(cfg.cards.size() >= 20, "servono almeno 20 carte")


func test_initial_state() -> void:
	for seed_value in range(50):
		var e := TurnEngine.new(fresh_config(), seed_value)
		var n := e.state.outbreaks.size()
		check(n >= 4 and n <= 5, "seed %d: %d focolai" % [seed_value, n])
		for o in e.state.outbreaks:
			check(o.intensity >= 2 and o.intensity <= 4, "seed %d: intensità %d" % [seed_value, o.intensity])
			check(not o.revealed, "i focolai partono nascosti")
			check(o.type_id != "rancore", "il rancore non nasce a inizio partita")
	var e := TurnEngine.new(fresh_config(), 7)
	check_eq(e.state.stability, 60, "stabilità iniziale")
	check_eq(e.state.day, 1, "giorno iniziale")
	check_eq(e.state.queen.to_view(), {"ricchezza": 10, "forza": 3, "fascino": 3, "saggezza": 3}, "stat iniziali")


func test_same_seed_same_game() -> void:
	var a := TurnEngine.new(fresh_config(), 4242)
	var b := TurnEngine.new(fresh_config(), 4242)
	var describe := func(e: TurnEngine) -> Array:
		return e.state.outbreaks.map(func(o): return [o.type_id, o.nature, o.weakness, o.mood, o.intensity])
	check_eq(describe.call(a), describe.call(b), "stesso seed, stessi focolai")
	check_eq(a.deck.draw()["id"], b.deck.draw()["id"], "stesso seed, stesso mazzo")


func test_hidden_info_in_view() -> void:
	var e := empty_engine()
	var o := add_outbreak(e, 3, Defs.NATURE_TRAPPOLA, Defs.FORZA)
	check_eq(o.to_view()["nature"], "", "natura nascosta")
	check_eq(o.to_view()["weakness"], "", "debolezza nascosta")
