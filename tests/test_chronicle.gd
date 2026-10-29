extends TestCase


func _finished_game(seed_value: int, respond: bool) -> TurnEngine:
	var e := TurnEngine.new(fresh_config(), seed_value)
	var guard := 0
	while not e.state.is_over() and guard < 60:
		guard += 1
		var active := e.state.active_outbreaks()
		if active.is_empty():
			e.wait_day()
			continue
		e.begin_confront(active[0].id, Defs.FASCINO)
		e.resolve_confront(1.0 if guard % 2 == 0 else 0.4)
		if not e.state.is_over():
			e.answer_court(respond)
	return e


func test_chronicle_has_three_or_four_lines() -> void:
	for seed_value in 40:
		var e := _finished_game(seed_value, seed_value % 2 == 0)
		var lines := Chronicle.generate(e.cfg, e.state)
		check(lines.size() >= 3 and lines.size() <= 4, "seed %d: %d righe" % [seed_value, lines.size()])
		for line in lines:
			check(not line.contains("{"), "seed %d: segnaposto non sostituito in '%s'" % [seed_value, line])
			check(line.left(1) == line.left(1).to_upper(), "seed %d: maiuscola iniziale in '%s'" % [seed_value, line])
			check(not line.left(1).is_valid_int(), "seed %d: inizia con una cifra: '%s'" % [seed_value, line])


func test_chronicle_is_stable_for_a_seed() -> void:
	var a := _finished_game(9, true)
	var b := _finished_game(9, true)
	check_eq(Chronicle.generate(a.cfg, a.state), Chronicle.generate(b.cfg, b.state), "stesso seme, stessa cronaca")


func test_chronicle_never_judges() -> void:
	# Il tema non va mai dichiarato: nessuna parola di giudizio nei frammenti.
	var text := JSON.stringify(fresh_config().chronicle).to_lower()
	for word in ["saggia", "saggiamente", "giusto", "sbagli", "errore", "avresti", "lezione"]:
		check(not text.contains(word), "parola di giudizio nella cronaca: %s" % word)
