class_name MinigameRules
extends RefCounted
## Formule dei minigiochi, separate dalla grafica per poterle testare e simulare.
## Ogni minigioco produce un punteggio 0..1; Resolution lo trasforma in esito.


static func outcome_for(cfg: GameConfig, score: float) -> String:
	if score >= cfg.f("resolution.victory_score"):
		return Defs.OUTCOME_VICTORY
	if score >= cfg.f("resolution.light_defeat_score"):
		return Defs.OUTCOME_LIGHT
	if score >= cfg.f("resolution.medium_defeat_score"):
		return Defs.OUTCOME_MEDIUM
	return Defs.OUTCOME_HEAVY


# --- Forza: barra a tempo -------------------------------------------------

## Zona verde centrata a 0.5 su una barra 0..1. Più Forza = zona più larga; più intensità = ago più veloce.
static func force_params(cfg: GameConfig, forza: int, intensity: int) -> Dictionary:
	return {
		"zone_center": 0.5,
		"zone_half_width": cfg.f("minigames.force.zone_half_width_base") + cfg.f("minigames.force.zone_half_width_per_point") * forza,
		"needle_speed": cfg.f("minigames.force.needle_speed_base") + cfg.f("minigames.force.needle_speed_per_intensity") * intensity,
		"duration_seconds": cfg.f("minigames.force.duration_seconds"),
	}


## Posizione dell'ago (0..1) dopo `t` secondi: va e viene lungo la barra.
static func needle_position(t: float, speed: float) -> float:
	var p := fmod(t * speed, 2.0)
	return p if p <= 1.0 else 2.0 - p


## Dentro la zona: da 0.6 sul bordo a 1.0 al centro. Fuori: scende fino a 0 entro "falloff".
static func force_score(cfg: GameConfig, hit_pos: float, zone_half_width: float) -> float:
	var victory := cfg.f("resolution.victory_score")
	var d := absf(hit_pos - 0.5)
	if d <= zone_half_width:
		return victory + (1.0 - victory) * (1.0 - d / zone_half_width)
	var falloff := cfg.f("minigames.force.falloff")
	return victory * maxf(0.0, 1.0 - (d - zone_half_width) / falloff)


# --- Ricchezza: offerta ----------------------------------------------------

static func wealth_threshold(cfg: GameConfig, intensity: int, rng: RandomNumberGenerator) -> int:
	var variance := cfg.i("minigames.wealth.threshold_variance")
	var base := intensity * cfg.i("minigames.wealth.threshold_per_intensity")
	return maxi(1, base + rng.randi_range(-variance, variance))


## Raggiunta la soglia si vince (l'eccesso è sprecato). Sotto, il rapporto decide quanto è grave.
static func wealth_score(cfg: GameConfig, offer: int, threshold: int) -> float:
	if offer >= threshold:
		return 1.0
	return cfg.f("resolution.victory_score") * float(maxi(offer, 0)) / float(threshold)


# --- Fascino: risposta giusta ---------------------------------------------

## Con Fascino alto la regina riceve indizi sull'umore del focolaio.
static func charm_hints(cfg: GameConfig, fascino: int) -> Dictionary:
	return {
		"discard_wrong_phrase": fascino >= cfg.i("minigames.charm.hint_discard_min_fascino"),
		"highlight_keyword": fascino >= cfg.i("minigames.charm.hint_keyword_min_fascino"),
	}


## Risposta giusta = vittoria piena. Risposta sbagliata: il Fascino attutisce la sconfitta.
static func charm_score(cfg: GameConfig, chosen_mood: String, true_mood: String, fascino: int) -> float:
	if chosen_mood == true_mood:
		return 1.0
	return cfg.f("minigames.charm.wrong_answer_base") + cfg.f("minigames.charm.wrong_answer_per_point") * fascino


## Prepara un round: una frase per ciascun umore, in ordine casuale, più gli indizi concessi dal Fascino.
## "discarded" è l'indice di una frase sbagliata da scartare (-1 se nessuna);
## "cry" è il grido della folla con la parola chiave (vuoto se l'indizio non spetta).
static func charm_round(cfg: GameConfig, mood: String, hints: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var options: Array[Dictionary] = []
	for m in Defs.MOODS:
		var pool: Array = cfg.charm["phrases"][m]
		options.append({"mood": m, "text": pool[rng.randi_range(0, pool.size() - 1)]["text"]})
	for n in range(options.size() - 1, 0, -1):
		var j := rng.randi_range(0, n)
		var tmp := options[n]
		options[n] = options[j]
		options[j] = tmp

	var discarded := -1
	if hints.get("discard_wrong_phrase", false):
		var wrong: Array[int] = []
		for n in options.size():
			if options[n]["mood"] != mood:
				wrong.append(n)
		discarded = wrong[rng.randi_range(0, wrong.size() - 1)]

	var cry := {}
	if hints.get("highlight_keyword", false):
		var cries: Array = cfg.charm["crowd_cries"][mood]
		cry = cries[rng.randi_range(0, cries.size() - 1)]
	return {"options": options, "discarded": discarded, "cry": cry}
