extends SceneTree
## Simulatore di bilanciamento. Gioca molte partite con strategie automatiche e stampa le statistiche.
##
##   godot --headless --path . -s tools/simulate.gd -- [partite=2000] [chiave.di.balance=valore ...]
##
## Esempio: ... -- 5000 stability.daily_damage_multiplier=0.6
## Le abilità del giocatore (mira, intuito) sono modellate in modo semplice: servono a confrontare
## configurazioni tra loro, non a prevedere la percentuale esatta di un giocatore umano.

const FORCE_AIM_SIGMA := 0.12  # errore di mira medio sulla barra 0..1

var rng := RandomNumberGenerator.new()


func _init() -> void:
	var games := 2000
	var overrides := {}
	for arg in OS.get_cmdline_user_args():
		if arg.contains("="):
			var parts := arg.split("=")
			overrides[parts[0]] = float(parts[1])
		elif arg.is_valid_int():
			games = int(arg)

	var cfg := GameConfig.load_default()
	for key in overrides:
		_set_balance(cfg, key, overrides[key])
	if not overrides.is_empty():
		print("Modifiche: %s" % str(overrides))
	rng.seed = 12345

	print("%-10s %8s %8s %8s %10s %10s %10s" % ["strategia", "vittorie", "crollo", "debole", "stab.fin", "spenti", "focolai+"])
	for strategy in ["passiva", "casuale", "avida", "saggia", "selettiva"]:
		_run(cfg, strategy, games)
	quit()


func _run(cfg: GameConfig, strategy: String, games: int) -> void:
	var tally := {Defs.RESULT_WIN: 0, Defs.RESULT_COLLAPSE: 0, Defs.RESULT_WEAK: 0}
	var stability_sum := 0
	var extinguished_sum := 0
	var spawned_sum := 0
	for g in games:
		var e := TurnEngine.new(cfg, g)
		var guard := 0
		while not e.state.is_over() and guard < 100:
			guard += 1
			_play_turn(e, strategy)
		tally[e.state.result] += 1
		stability_sum += e.state.stability
		extinguished_sum += e.state.events.filter(func(ev): return ev["kind"] == "spento").size()
		spawned_sum += e.state.events.filter(func(ev): return ev["kind"] == "nuovo_focolaio").size()
	var pct := func(n: int) -> String: return "%5.1f%%" % (100.0 * n / games)
	print("%-10s %8s %8s %8s %10.1f %10.2f %10.2f" % [
		strategy, pct.call(tally[Defs.RESULT_WIN]), pct.call(tally[Defs.RESULT_COLLAPSE]),
		pct.call(tally[Defs.RESULT_WEAK]), float(stability_sum) / games,
		float(extinguished_sum) / games, float(spawned_sum) / games])


func _play_turn(e: TurnEngine, strategy: String) -> void:
	var active := e.state.active_outbreaks()
	if active.is_empty():
		e.wait_day()
		return
	match strategy:
		"passiva":
			e.observe(active[0].id)
		"casuale":
			var o: Outbreak = active[rng.randi_range(0, active.size() - 1)]
			var approaches := Defs.APPROACHES.filter(func(a): return e.can_confront(o.id, a))
			_confront(e, o, approaches[rng.randi_range(0, approaches.size() - 1)], rng.randf() < 0.5)
		"avida":
			var o := _strongest(active)
			_confront(e, o, _best_approach(e, o), false)
		"saggia":
			# Osserva i focolai forti e sconosciuti, poi colpisce la debolezza. Ignora il disturbatore.
			var o := _strongest(active)
			if not o.revealed and o.intensity >= 3:
				e.observe(o.id)
			else:
				_confront(e, o, _best_approach(e, o), false)
		"selettiva":
			# Sceglie le battaglie: lascia spegnere da soli i focolai che si estinguono,
			# osserva i forti sconosciuti, colpisce prima ciò che cresce.
			var worth := active.filter(func(o): return not (o.revealed and o.nature == Defs.NATURE_ESTINGUE))
			if worth.is_empty():
				e.wait_day()
				return
			var unknown := worth.filter(func(o): return not o.revealed and o.intensity >= 3)
			if not unknown.is_empty():
				e.observe(_strongest(unknown).id)
				return
			var growing := worth.filter(func(o): return o.revealed and o.nature == Defs.NATURE_CRESCE)
			var o := _strongest(growing if not growing.is_empty() else worth)
			_confront(e, o, _best_approach(e, o), false)


func _strongest(active: Array) -> Outbreak:
	var best: Outbreak = active[0]
	for o in active:
		if o.intensity > best.intensity:
			best = o
	return best


## La debolezza se nota e praticabile, altrimenti la statistica migliore.
func _best_approach(e: TurnEngine, o: Outbreak) -> String:
	if o.revealed and e.can_confront(o.id, o.weakness):
		if o.weakness != Defs.RICCHEZZA or e.state.queen.coins >= o.intensity * 2 + 1:
			return o.weakness
	var q := e.state.queen
	if q.coins >= o.intensity * 2 + 1:
		return Defs.RICCHEZZA
	return Defs.FORZA if q.get_stat(Defs.FORZA) >= q.get_stat(Defs.FASCINO) else Defs.FASCINO


func _confront(e: TurnEngine, o: Outbreak, approach: String, respond_to_court: bool) -> void:
	var setup := e.begin_confront(o.id, approach)
	var score := 0.0
	var coins := 0
	match approach:
		Defs.FORZA:
			var hit := 0.5 + rng.randfn(0.0, FORCE_AIM_SIGMA)
			score = MinigameRules.force_score(e.cfg, hit, setup["zone_half_width"])
		Defs.RICCHEZZA:
			# Offerta prudente: copre la soglia peggiore, se le monete bastano.
			coins = mini(e.state.queen.coins, o.intensity * 2 + 1)
			score = MinigameRules.wealth_score(e.cfg, coins, setup["threshold"])
		Defs.FASCINO:
			var hints: Dictionary = setup["hints"]
			var p_right := 1.0 / 3.0
			if hints["highlight_keyword"]:
				p_right = 0.9
			elif hints["discard_wrong_phrase"]:
				p_right = 0.5
			var chosen: String = setup["mood"] if rng.randf() < p_right else "?"
			score = MinigameRules.charm_score(e.cfg, chosen, setup["mood"], e.state.queen.get_stat(Defs.FASCINO))
	e.resolve_confront(score, coins)
	if not e.state.is_over() and e.phase == TurnEngine.Phase.COURT:
		e.answer_court(respond_to_court)


func _set_balance(cfg: GameConfig, path: String, v: float) -> void:
	var keys := path.split(".")
	var node: Dictionary = cfg.balance
	for k in keys.slice(0, keys.size() - 1):
		node = node[k]
	node[keys[-1]] = v
