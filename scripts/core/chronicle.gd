class_name Chronicle
extends RefCounted
## Cronaca finale: 3-4 righe epiche costruite dal registro degli eventi.
## Racconta cosa è accaduto; non giudica mai. I frammenti stanno in data/chronicle.json.


static func generate(cfg: GameConfig, state: GameState) -> Array[String]:
	var rng := RandomNumberGenerator.new()
	rng.seed = state.seed_value  # stessa partita, stessa cronaca
	var c := cfg.chronicle
	var lines: Array[String] = []

	lines.append(_pick(rng, c["opening"][state.result]).format({"giorno": state.day}))

	# Le vittorie della regina: si racconta la prima, si contano le altre.
	var won := state.events.filter(func(e): return e["kind"] == "scontro" and e["extinguished"])
	if won.is_empty():
		lines.append(_pick(rng, c["no_victories"]))
	else:
		var first: Dictionary = won[0]
		var line := _pick(rng, c["victory_by_hand"][first["approach"]]).format({"nome": _name(cfg, first["type_id"])})
		if won.size() == 2:
			line += _pick(rng, c["more_victories_one"])
		elif won.size() > 2:
			line += _pick(rng, c["more_victories"]).format({"n": _words(won.size() - 1)})
		lines.append(line)

	# Ciò che non è stato combattuto: il fuoco più alto rimasto, o uno spento da sé.
	var burning := state.active_outbreaks()
	burning.sort_custom(func(a, b): return a.intensity > b.intensity)
	var alone := state.events.filter(func(e): return e["kind"] == "spento" and e["how"] == "da_solo")
	if not burning.is_empty():
		lines.append(_pick(rng, c["still_burning"]).format({"nome": _name(cfg, burning[0].type_id)}))
	elif not alone.is_empty():
		lines.append(_pick(rng, c["extinguished_alone"]).format({"nome": _name(cfg, alone[0]["type_id"])}))

	var accepted := state.events.filter(func(e): return e["kind"] == "proposta" and e["responded"]).size()
	if accepted == 0:
		lines.append(_pick(rng, c["court_none"]))
	elif accepted == 1:
		lines.append(_pick(rng, c["court_accepted_once"]))
	else:
		lines.append(_pick(rng, c["court_accepted"]).format({"n": _words(accepted)}))
	var result: Array[String] = []
	for l in lines:
		result.append(l.left(1).to_upper() + l.substr(1))
	return result


## I numeri piccoli in lettere: una cronaca non scrive "3 volte".
static func _words(n: int) -> String:
	const WORDS := ["zero", "uno", "due", "tre", "quattro", "cinque", "sei", "sette", "otto", "nove", "dieci", "undici", "dodici"]
	return WORDS[n] if n < WORDS.size() else str(n)


static func _pick(rng: RandomNumberGenerator, options: Array) -> String:
	return options[rng.randi_range(0, options.size() - 1)]


static func _name(cfg: GameConfig, type_id: String) -> String:
	return cfg.type_name(type_id, true)
