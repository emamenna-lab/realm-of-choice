class_name TurnEngine
extends RefCounted
## Le regole del gioco. La UI chiama questi metodi nell'ordine dettato da `phase`:
##
##   CHOOSE_ACTION --observe()--------------------------------> (giorni avanzano) CHOOSE_ACTION
##   CHOOSE_ACTION --begin_confront()--> MINIGAME --resolve_confront()--> COURT --answer_court()--> CHOOSE_ACTION
##
## Ogni giorno consumato applica la fine giornata; la partita può finire in qualunque momento (GAME_OVER).

enum Phase { CHOOSE_ACTION, MINIGAME, COURT, GAME_OVER }

var cfg: GameConfig
var rng := RandomNumberGenerator.new()
var state := GameState.new()
var factory: OutbreakFactory
var deck: DisturberDeck
var phase := Phase.CHOOSE_ACTION
## Il confronto in corso, impostato da begin_confront().
var confront: Dictionary = {}
## La carta del disturbatore in attesa di risposta.
var current_card: Dictionary = {}
var _card_revealed := false
var _days_to_consume := 0
## Se false, la partita parte senza focolai (utile nei test).
var _generate_outbreaks := true


func _init(config: GameConfig, seed_value: int = -1, generate_outbreaks := true) -> void:
	cfg = config
	_generate_outbreaks = generate_outbreaks
	if seed_value < 0:
		rng.randomize()
		# Seed corto: deve essere leggibile a schermo e facile da ridigitare.
		seed_value = rng.randi_range(0, 999_999)
	state.seed_value = seed_value
	rng.seed = seed_value
	factory = OutbreakFactory.new(cfg, rng)
	deck = DisturberDeck.new(cfg, rng)
	state.queen = QueenStats.new(cfg)
	state.stability = cfg.i("stability.initial")
	if _generate_outbreaks:
		state.outbreaks = factory.create_initial(state)
	state.log_event("inizio", {"outbreaks": state.outbreaks.size()})


# --- Azioni ----------------------------------------------------------------

func can_confront(outbreak_id: int, approach: String) -> bool:
	if phase != Phase.CHOOSE_ACTION or not Defs.APPROACHES.has(approach):
		return false
	var o := state.get_outbreak(outbreak_id)
	if o == null or not o.is_active():
		return false
	if approach == Defs.RICCHEZZA and state.queen.coins <= 0:
		return false
	return true


## Osservare con la Saggezza: rivela natura e debolezza. Consuma il giorno, niente disturbatore.
func observe(outbreak_id: int) -> Dictionary:
	assert(phase == Phase.CHOOSE_ACTION, "observe() fuori fase")
	var o := state.get_outbreak(outbreak_id)
	assert(o != null and o.is_active(), "observe(): focolaio non valido")
	o.revealed = true
	var reveals_card := state.queen.get_stat(Defs.SAGGEZZA) >= cfg.i("observe.reveal_card_min_saggezza")
	if reveals_card:
		state.reveal_next_card = true
	state.log_event("osservato", {"outbreak_id": o.id, "type_id": o.type_id})
	var result := {"outbreak": o.to_view(), "reveals_next_card": reveals_card}
	_consume_days(1)
	return result


## Lascia passare il giorno senza agire. Serve quando non resta nessun focolaio da affrontare.
func wait_day() -> void:
	assert(phase == Phase.CHOOSE_ACTION, "wait_day() fuori fase")
	state.log_event("attesa")
	_consume_days(1)


## Prepara il minigioco. Restituisce i parametri che la scena del minigioco deve usare.
func begin_confront(outbreak_id: int, approach: String) -> Dictionary:
	assert(can_confront(outbreak_id, approach), "begin_confront(): azione non valida")
	var o := state.get_outbreak(outbreak_id)
	confront = {"outbreak_id": o.id, "type_id": o.type_id, "approach": approach, "intensity": o.intensity}
	match approach:
		Defs.FORZA:
			confront.merge(MinigameRules.force_params(cfg, state.queen.get_stat(Defs.FORZA), o.intensity))
		Defs.RICCHEZZA:
			confront["threshold"] = MinigameRules.wealth_threshold(cfg, o.intensity, rng)
			confront["coins"] = state.queen.coins
		Defs.FASCINO:
			confront["mood"] = o.mood
			confront["fascino"] = state.queen.get_stat(Defs.FASCINO)
			confront["hints"] = MinigameRules.charm_hints(cfg, state.queen.get_stat(Defs.FASCINO))
			confront["round"] = MinigameRules.charm_round(cfg, o.mood, confront["hints"], rng)
	phase = Phase.MINIGAME
	return confront.duplicate(true)


## Applica il risultato del minigioco. `coins_spent` conta solo per la Ricchezza.
func resolve_confront(score: float, coins_spent := 0) -> Dictionary:
	assert(phase == Phase.MINIGAME, "resolve_confront() fuori fase")
	var o := state.get_outbreak(confront["outbreak_id"])
	var approach: String = confront["approach"]
	o.confronted_today = true

	if approach == Defs.RICCHEZZA:
		state.queen.coins -= clampi(coins_spent, 0, state.queen.coins)

	var outcome := MinigameRules.outcome_for(cfg, clampf(score, 0.0, 1.0))
	var hit_weakness := approach == o.weakness
	var result := {
		"outbreak_id": o.id, "approach": approach, "score": score, "outcome": outcome,
		"hit_weakness": hit_weakness, "reduction": 0, "extinguished": false, "spawned": [],
	}

	_days_to_consume = 1
	if outcome == Defs.OUTCOME_VICTORY:
		var reduction := cfg.i("resolution.weakness_victory_reduction") if hit_weakness else cfg.i("resolution.victory_reduction")
		o.intensity = maxi(0, o.intensity - reduction)
		result["reduction"] = reduction
		if not o.is_active():
			_on_extinguished(o, "vinto")
			result["extinguished"] = true
		if approach == Defs.FORZA and rng.randf() < cfg.f("outbreaks.rancor.chance_on_force_win"):
			_spawn(factory.create_rancor(state), result)
	else:
		_days_to_consume += int(cfg.value("resolution.extra_days")[outcome])

	if o.nature == Defs.NATURE_TRAPPOLA and not hit_weakness:
		_spawn(factory.create(state, cfg.i("outbreaks.trap_spawn_intensity"), "trappola"), result)

	state.log_event("scontro", {
		"outbreak_id": o.id, "type_id": o.type_id, "approach": approach,
		"outcome": outcome, "extinguished": result["extinguished"],
	})

	current_card = deck.draw()
	_card_revealed = state.reveal_next_card
	state.reveal_next_card = false
	result["card"] = court_view()
	phase = Phase.COURT
	return result


## Cosa vede la regina della proposta in corso. L'etichetta compare solo se rivelata dalla Saggezza.
func court_view() -> Dictionary:
	if current_card.is_empty():
		return {}
	return {
		"id": current_card["id"],
		"text": current_card["text"],
		"label": current_card["label"] if _card_revealed else "",
	}


## Rispondere costa un giorno e applica la proposta; ignorare non costa nulla
## (salvo l'orgoglio ferito di una provocazione).
func answer_court(respond: bool) -> Dictionary:
	assert(phase == Phase.COURT, "answer_court() fuori fase")
	var card := current_card
	var stat: String = card["stat"]
	var effect := {"card_id": card["id"], "label": card["label"], "responded": respond}
	var before := state.queen.to_view()
	match card["label"]:
		Defs.CARD_USEFUL:
			if respond:
				_boost(stat, cfg.i("disturber.useful_bonus"))
		Defs.CARD_FLATTERY:
			if respond:
				state.queen.add_modifier(stat, cfg.i("disturber.flattery_bonus"), cfg.i("disturber.flattery_days"))
		Defs.CARD_POISONED:
			if respond:
				_boost(stat, cfg.i("disturber.poisoned_bonus"))
				state.pending_effects.append(_poison_effect(card))
		Defs.CARD_PROVOCATION:
			if respond:
				state.queen.add_base(Defs.FORZA, cfg.i("disturber.provocation_respond_forza_gain"))
			else:
				state.queen.add_base(Defs.FASCINO, -cfg.i("disturber.provocation_ignore_fascino_loss"))
	# Variazioni visibili subito. Gli effetti ritardati del veleno restano nascosti.
	var changes := {}
	var after := state.queen.to_view()
	for k in after:
		if after[k] != before[k]:
			changes[k] = after[k] - before[k]
	effect["changes"] = changes
	state.log_event("proposta", effect)
	current_card = {}
	confront = {}
	var cost := cfg.i("disturber.respond_day_cost") if respond else cfg.i("disturber.ignore_day_cost")
	_consume_days(_days_to_consume + cost)
	_days_to_consume = 0
	return effect


# --- Fine giornata ---------------------------------------------------------

func _consume_days(count: int) -> void:
	for n in count:
		_end_of_day()
		if state.is_over():
			phase = Phase.GAME_OVER
			return
	phase = Phase.CHOOSE_ACTION


func _end_of_day() -> void:
	# 1. Danni: ogni focolaio attivo sottrae la propria intensità.
	var damage := roundi(state.total_intensity() * cfg.f("stability.daily_damage_multiplier"))
	state.stability = clampi(state.stability - damage, 0, cfg.i("stability.max"))
	state.log_event("fine_giorno", {"damage": damage, "stability": state.stability})
	if state.stability <= 0:
		state.result = Defs.RESULT_COLLAPSE
		state.log_event("fine", {"result": state.result})
		return

	# 2. Evoluzione secondo la natura, solo per i focolai ignorati oggi.
	for o in state.active_outbreaks():
		if o.confronted_today:
			o.ignored_days = 0
		else:
			o.ignored_days += 1
			_evolve(o)
		o.confronted_today = false

	# 3. Effetti a tempo.
	for m in state.queen.tick():
		state.log_event("lusinga_svanita", {"stat": m["stat"]})
	_tick_pending_effects()

	# 4. Avanza il calendario.
	state.day += 1
	if state.day > cfg.i("days_total"):
		state.day = cfg.i("days_total")
		var won := state.stability >= cfg.i("stability.win_threshold")
		state.result = Defs.RESULT_WIN if won else Defs.RESULT_WEAK
		state.log_event("fine", {"result": state.result})


func _evolve(o: Outbreak) -> void:
	match o.nature:
		Defs.NATURE_ESTINGUE:
			o.intensity = maxi(0, o.intensity - cfg.i("outbreaks.estingue_decay_per_day"))
			if not o.is_active():
				_on_extinguished(o, "da_solo")
		Defs.NATURE_CRESCE:
			if o.ignored_days % cfg.i("outbreaks.cresce_every_days") == 0:
				o.intensity = mini(cfg.i("outbreaks.intensity_max"), o.intensity + cfg.i("outbreaks.cresce_growth"))
		Defs.NATURE_TRAPPOLA:
			pass


func _tick_pending_effects() -> void:
	var fired: Array[Dictionary] = []
	for e in state.pending_effects:
		e["days_left"] -= 1
		if e["days_left"] <= 0:
			fired.append(e)
	for e in fired:
		state.pending_effects.erase(e)
		if e["kind"] == "focolaio":
			_spawn(factory.create(state, cfg.i("disturber.poisoned_outbreak_intensity"), "veleno"), {})
		else:
			state.queen.add_base(e["stat"], -cfg.i("disturber.poisoned_stat_penalty"))
		state.log_event("veleno", {"effect": e["kind"], "stat": e["stat"], "card_id": e["card_id"]})


# --- Utilità ---------------------------------------------------------------

func _boost(stat: String, amount: int) -> void:
	if stat == Defs.RICCHEZZA:
		amount *= cfg.i("disturber.coins_per_wealth_point")
	state.queen.add_base(stat, amount)


func _poison_effect(card: Dictionary) -> Dictionary:
	var effect := {"days_left": cfg.i("disturber.poisoned_delay_days"), "card_id": card["id"], "kind": "stat", "stat": ""}
	if rng.randf() < cfg.f("disturber.poisoned_outbreak_chance"):
		effect["kind"] = "focolaio"
	else:
		var others := Defs.SCORE_STATS.filter(func(s): return s != card["stat"])
		effect["stat"] = others[rng.randi_range(0, others.size() - 1)]
	return effect


## Aggiunge un focolaio, rispettando il tetto massimo di focolai attivi.
func _spawn(o: Outbreak, result: Dictionary) -> void:
	if state.active_outbreaks().size() >= cfg.i("outbreaks.max_active"):
		state.log_event("focolaio_evitato", {"origin": o.origin})
		return
	state.outbreaks.append(o)
	state.log_event("nuovo_focolaio", {"outbreak_id": o.id, "type_id": o.type_id, "origin": o.origin})
	if result.has("spawned"):
		result["spawned"].append(o.id)


func _on_extinguished(o: Outbreak, how: String) -> void:
	o.extinguished_day = state.day
	state.stability = mini(cfg.i("stability.max"), state.stability + cfg.i("stability.recover_on_extinguish"))
	state.log_event("spento", {"outbreak_id": o.id, "type_id": o.type_id, "how": how})


## Vista sintetica per la UI e per il debug.
func to_view() -> Dictionary:
	return {
		"seed": state.seed_value,
		"day": state.day,
		"days_total": cfg.i("days_total"),
		"stability": state.stability,
		"queen": state.queen.to_view(),
		"outbreaks": state.active_outbreaks().map(func(o: Outbreak): return o.to_view()),
		"phase": phase,
		"result": state.result,
	}
