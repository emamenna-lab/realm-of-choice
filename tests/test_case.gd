class_name TestCase
extends RefCounted
## Base minima per i test: niente dipendenze esterne.

var failures: Array[String] = []
var _current := ""


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append("%s: %s" % [_current, message])


func check_eq(actual: Variant, expected: Variant, message := "") -> void:
	if actual != expected:
		failures.append("%s: %s atteso %s, ottenuto %s" % [_current, message, str(expected), str(actual)])


## Configurazione fresca, modificabile dal singolo test senza toccare gli altri.
## I valori di bilanciamento che i test usano nei calcoli sono fissati qui: i test verificano
## le regole, non la taratura corrente di balance.json.
func fresh_config() -> GameConfig:
	var cfg := GameConfig.load_default()
	cfg.balance = cfg.balance.duplicate(true)
	cfg.balance["stability"]["daily_damage_multiplier"] = 1.0
	cfg.balance["stability"]["recover_on_extinguish"] = 0
	cfg.balance["resolution"]["victory_reduction"] = 2
	cfg.balance["resolution"]["weakness_victory_reduction"] = 3
	return cfg


## Partita senza focolai casuali, per costruire scenari precisi.
func empty_engine(cfg: GameConfig = null, seed_value := 1) -> TurnEngine:
	return TurnEngine.new(cfg if cfg else fresh_config(), seed_value, false)


func add_outbreak(engine: TurnEngine, intensity: int, nature: String, weakness := Defs.FASCINO) -> Outbreak:
	var o := engine.factory.create(engine.state, intensity, "test")
	o.nature = nature
	o.weakness = weakness
	engine.state.outbreaks.append(o)
	return o


## Forza in deck una carta specifica come prossima pescata.
func force_next_card(engine: TurnEngine, card_id: String) -> void:
	for c in engine.cfg.cards:
		if c["id"] == card_id:
			engine.deck._draw_pile.append(c)
			return
	failures.append("%s: carta %s non trovata" % [_current, card_id])
