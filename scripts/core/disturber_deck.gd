class_name DisturberDeck
extends RefCounted
## Mazzo delle proposte del disturbatore. Si pesca senza rimpiazzo; finito il mazzo, si rimescola.
## La composizione del file dati determina la distribuzione delle etichette.

var cfg: GameConfig
var rng: RandomNumberGenerator
var _draw_pile: Array = []


func _init(config: GameConfig, random: RandomNumberGenerator) -> void:
	cfg = config
	rng = random
	_reshuffle()


func draw() -> Dictionary:
	if _draw_pile.is_empty():
		_reshuffle()
	return _draw_pile.pop_back()


func _reshuffle() -> void:
	_draw_pile = cfg.cards.duplicate()
	# Fisher-Yates con l'RNG della partita, così il seed riproduce anche il mazzo.
	for n in range(_draw_pile.size() - 1, 0, -1):
		var j := rng.randi_range(0, n)
		var tmp = _draw_pile[n]
		_draw_pile[n] = _draw_pile[j]
		_draw_pile[j] = tmp
