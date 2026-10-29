class_name GameConfig
extends RefCounted
## Carica e valida i file dati. Tutti i numeri di bilanciamento passano da qui.

const BALANCE_PATH := "res://data/balance.json"
const OUTBREAK_TYPES_PATH := "res://data/outbreak_types.json"
const CARDS_PATH := "res://data/disturber_cards.json"

## Chiavi che devono esistere in balance.json. Un errore qui è meglio di un crash a metà partita.
const REQUIRED_KEYS: Array[String] = [
	"days_total",
	"stability.initial", "stability.max", "stability.win_threshold",
	"stability.daily_damage_multiplier", "stability.recover_on_extinguish",
	"queen.initial.forza", "queen.initial.fascino", "queen.initial.saggezza", "queen.initial.ricchezza",
	"queen.stat_min", "queen.stat_max",
	"outbreaks.initial_count_min", "outbreaks.initial_count_max",
	"outbreaks.initial_intensity_min", "outbreaks.initial_intensity_max",
	"outbreaks.intensity_max", "outbreaks.max_active", "outbreaks.nature_weights",
	"outbreaks.estingue_decay_per_day", "outbreaks.cresce_growth", "outbreaks.cresce_every_days",
	"outbreaks.trap_spawn_intensity",
	"outbreaks.rancor.type", "outbreaks.rancor.chance_on_force_win", "outbreaks.rancor.intensity",
	"outbreaks.rancor.nature", "outbreaks.rancor.weakness",
	"resolution.victory_score", "resolution.light_defeat_score", "resolution.medium_defeat_score",
	"resolution.victory_reduction", "resolution.weakness_victory_reduction", "resolution.extra_days",
	"observe.reveal_card_min_saggezza",
	"minigames.force.zone_half_width_base", "minigames.force.zone_half_width_per_point",
	"minigames.force.falloff", "minigames.force.needle_speed_base",
	"minigames.force.needle_speed_per_intensity", "minigames.force.duration_seconds",
	"minigames.wealth.threshold_per_intensity", "minigames.wealth.threshold_variance",
	"minigames.charm.hint_discard_min_fascino", "minigames.charm.hint_keyword_min_fascino",
	"minigames.charm.wrong_answer_base", "minigames.charm.wrong_answer_per_point",
	"disturber.respond_day_cost", "disturber.ignore_day_cost", "disturber.useful_bonus",
	"disturber.flattery_bonus", "disturber.flattery_days", "disturber.poisoned_bonus",
	"disturber.poisoned_delay_days", "disturber.poisoned_stat_penalty",
	"disturber.poisoned_outbreak_intensity", "disturber.poisoned_outbreak_chance",
	"disturber.provocation_ignore_fascino_loss", "disturber.provocation_respond_forza_gain",
	"disturber.coins_per_wealth_point",
]

var balance: Dictionary = {}
var outbreak_types: Array = []
var cards: Array = []
var errors: Array[String] = []


static func load_default() -> GameConfig:
	var cfg := GameConfig.new()
	cfg.balance = _load_json(BALANCE_PATH, cfg.errors)
	cfg.outbreak_types = _load_json(OUTBREAK_TYPES_PATH, cfg.errors).get("types", [])
	cfg.cards = _load_json(CARDS_PATH, cfg.errors).get("cards", [])
	cfg.validate()
	for e in cfg.errors:
		push_error(e)
	return cfg


static func _load_json(path: String, errors: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		errors.append("File dati mancante: %s" % path)
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		errors.append("JSON non valido: %s" % path)
		return {}
	return data


func is_valid() -> bool:
	return errors.is_empty()


func validate() -> void:
	for key in REQUIRED_KEYS:
		if _lookup(key) == null:
			errors.append("balance.json: manca '%s'" % key)

	var type_ids := {}
	for t in outbreak_types:
		for field in ["id", "name", "description", "moods", "spawnable"]:
			if not t.has(field):
				errors.append("outbreak_types.json: tipo senza '%s': %s" % [field, t])
		for mood in t.get("moods", []):
			if not Defs.MOODS.has(mood):
				errors.append("outbreak_types.json: umore sconosciuto '%s'" % mood)
		type_ids[t.get("id", "")] = true
	if spawnable_types().is_empty():
		errors.append("outbreak_types.json: nessun tipo con spawnable=true")
	var rancor_type = _lookup("outbreaks.rancor.type")
	if rancor_type != null and not type_ids.has(rancor_type):
		errors.append("outbreak_types.json: manca il tipo del rancore '%s'" % rancor_type)

	if cards.is_empty():
		errors.append("disturber_cards.json: mazzo vuoto")
	for c in cards:
		var label = c.get("label", "")
		var stat = c.get("stat", "")
		if not Defs.CARD_LABELS.has(label):
			errors.append("disturber_cards.json: etichetta sconosciuta in %s" % c.get("id", "?"))
		if not (Defs.SCORE_STATS.has(stat) or stat == Defs.RICCHEZZA):
			errors.append("disturber_cards.json: stat sconosciuta in %s" % c.get("id", "?"))
		if label == Defs.CARD_FLATTERY and stat == Defs.RICCHEZZA:
			errors.append("disturber_cards.json: una lusinga non può riguardare la ricchezza (%s)" % c.get("id", "?"))
		if not c.has("text"):
			errors.append("disturber_cards.json: carta senza testo %s" % c.get("id", "?"))


## Legge un valore con un percorso a punti, es. "outbreaks.rancor.intensity".
func value(path: String) -> Variant:
	var v = _lookup(path)
	if v == null:
		push_error("balance.json: manca '%s'" % path)
	return v


func i(path: String) -> int:
	return int(value(path))


func f(path: String) -> float:
	return float(value(path))


func _lookup(path: String) -> Variant:
	var node: Variant = balance
	for key in path.split("."):
		if not (node is Dictionary and node.has(key)):
			return null
		node = node[key]
	return node


func type_by_id(type_id: String) -> Dictionary:
	for t in outbreak_types:
		if t["id"] == type_id:
			return t
	return {}


func spawnable_types() -> Array:
	return outbreak_types.filter(func(t): return t.get("spawnable", false))
