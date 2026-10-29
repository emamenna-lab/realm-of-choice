class_name GameState
extends RefCounted
## Tutto lo stato di una partita. Nessuna regola qui: le regole stanno in TurnEngine.

var seed_value: int
var day := 1
var stability := 0
var queen: QueenStats
var outbreaks: Array[Outbreak] = []
var next_outbreak_id := 1
## Effetti ritardati delle carte avvelenate: {"days_left", "kind", "stat", "amount", "card_id"}
var pending_effects: Array[Dictionary] = []
## Impostato da un'osservazione con Saggezza alta: la prossima carta mostra la sua etichetta.
var reveal_next_card := false
var result := Defs.RESULT_NONE
## Registro degli eventi, base per la cronaca finale.
var events: Array[Dictionary] = []


func active_outbreaks() -> Array[Outbreak]:
	return outbreaks.filter(func(o: Outbreak): return o.is_active())


func get_outbreak(id: int) -> Outbreak:
	for o in outbreaks:
		if o.id == id:
			return o
	return null


func total_intensity() -> int:
	var total := 0
	for o in active_outbreaks():
		total += o.intensity
	return total


func is_over() -> bool:
	return result != Defs.RESULT_NONE


func log_event(kind: String, data: Dictionary = {}) -> void:
	var e := data.duplicate()
	e["kind"] = kind
	e["day"] = day
	events.append(e)
