extends TestCase


func test_outcome_thresholds() -> void:
	var cfg := fresh_config()
	check_eq(MinigameRules.outcome_for(cfg, 0.6), Defs.OUTCOME_VICTORY, "0.6")
	check_eq(MinigameRules.outcome_for(cfg, 0.59), Defs.OUTCOME_LIGHT, "0.59")
	check_eq(MinigameRules.outcome_for(cfg, 0.3), Defs.OUTCOME_LIGHT, "0.3")
	check_eq(MinigameRules.outcome_for(cfg, 0.29), Defs.OUTCOME_MEDIUM, "0.29")
	check_eq(MinigameRules.outcome_for(cfg, 0.1), Defs.OUTCOME_MEDIUM, "0.1")
	check_eq(MinigameRules.outcome_for(cfg, 0.09), Defs.OUTCOME_HEAVY, "0.09")


func test_force_zone_grows_with_strength() -> void:
	var cfg := fresh_config()
	var weak := MinigameRules.force_params(cfg, 3, 3)
	var strong := MinigameRules.force_params(cfg, 8, 3)
	check(strong["zone_half_width"] > weak["zone_half_width"], "zona più larga con più Forza")
	var hard := MinigameRules.force_params(cfg, 3, 5)
	check(hard["needle_speed"] > weak["needle_speed"], "ago più veloce con più intensità")


func test_force_score() -> void:
	var cfg := fresh_config()
	check_eq(MinigameRules.force_score(cfg, 0.5, 0.1), 1.0, "centro")
	check(is_equal_approx(MinigameRules.force_score(cfg, 0.6, 0.1), 0.6), "bordo della zona = vittoria minima")
	check(MinigameRules.force_score(cfg, 0.61, 0.1) < 0.6, "appena fuori = sconfitta")
	check_eq(MinigameRules.force_score(cfg, 1.0, 0.1), 0.0, "lontanissimo")


func test_wealth() -> void:
	var cfg := fresh_config()
	check_eq(MinigameRules.wealth_score(cfg, 6, 6), 1.0, "soglia raggiunta")
	check_eq(MinigameRules.wealth_score(cfg, 9, 6), 1.0, "sopra soglia: vince, spreca")
	check(MinigameRules.wealth_score(cfg, 5, 6) < 0.6, "sotto soglia: sconfitta")
	check_eq(MinigameRules.wealth_score(cfg, 0, 6), 0.0, "niente offerta")
	var rng := RandomNumberGenerator.new()
	for n in 50:
		var t := MinigameRules.wealth_threshold(cfg, 3, rng)
		check(t >= 5 and t <= 7, "soglia intensità 3: 6 ± 1, ottenuto %d" % t)


func test_charm() -> void:
	var cfg := fresh_config()
	check_eq(MinigameRules.charm_score(cfg, "rabbia", "rabbia", 3), 1.0, "risposta giusta")
	var low := MinigameRules.charm_score(cfg, "paura", "rabbia", 3)
	var high := MinigameRules.charm_score(cfg, "paura", "rabbia", 9)
	check_eq(MinigameRules.outcome_for(cfg, low), Defs.OUTCOME_MEDIUM, "sbagliata con Fascino 3")
	check_eq(MinigameRules.outcome_for(cfg, high), Defs.OUTCOME_LIGHT, "sbagliata con Fascino 9")
	check(not MinigameRules.charm_hints(cfg, 3)["discard_wrong_phrase"], "nessun indizio a 3")
	check(MinigameRules.charm_hints(cfg, 5)["discard_wrong_phrase"], "frase scartata a 5")
	check(MinigameRules.charm_hints(cfg, 8)["highlight_keyword"], "parola chiave a 8")


func test_needle_bounces() -> void:
	check_eq(MinigameRules.needle_position(0.0, 1.0), 0.0, "parte da sinistra")
	check(is_equal_approx(MinigameRules.needle_position(0.5, 1.0), 0.5), "a metà corsa")
	check(is_equal_approx(MinigameRules.needle_position(1.5, 1.0), 0.5), "torna indietro")
	check(is_equal_approx(MinigameRules.needle_position(2.0, 1.0), 0.0), "di nuovo a sinistra")
	check(is_equal_approx(MinigameRules.needle_position(0.5, 2.0), 1.0), "più veloce, arriva in fondo prima")


func test_charm_round_without_hints() -> void:
	var cfg := fresh_config()
	var rng := RandomNumberGenerator.new()
	var r := MinigameRules.charm_round(cfg, "paura", MinigameRules.charm_hints(cfg, 3), rng)
	var moods: Array = r["options"].map(func(o): return o["mood"])
	moods.sort()
	check_eq(moods, ["orgoglio", "paura", "rabbia"], "una frase per umore")
	check_eq(r["discarded"], -1, "nessuna frase scartata")
	check(r["cry"].is_empty(), "nessun grido")


func test_charm_round_hints() -> void:
	var cfg := fresh_config()
	var rng := RandomNumberGenerator.new()
	for seed_value in 30:
		rng.seed = seed_value
		var r := MinigameRules.charm_round(cfg, "orgoglio", MinigameRules.charm_hints(cfg, 8), rng)
		check(r["discarded"] >= 0, "frase scartata")
		check(r["options"][r["discarded"]]["mood"] != "orgoglio", "mai la frase giusta")
		check(String(r["cry"]["text"]).contains(r["cry"]["keyword"]), "grido con parola chiave")
