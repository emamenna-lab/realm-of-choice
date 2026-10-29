class_name Outbreak
extends RefCounted
## Un focolaio di rivolta. Natura, debolezza e umore sono nascosti finché non viene osservato.

var id: int
var type_id: String
var nature: String
var weakness: String
var mood: String
var intensity: int
var revealed := false
## Da dove è nato: "iniziale", "trappola", "rancore", "veleno".
var origin := "iniziale"
var confronted_today := false
## Giorni consecutivi in cui è stato ignorato (serve alla natura "cresce").
var ignored_days := 0
## Giorno in cui si è spento, -1 se ancora attivo.
var extinguished_day := -1


func is_active() -> bool:
	return intensity > 0


## Vista per la UI: nasconde ciò che la regina non sa.
func to_view() -> Dictionary:
	return {
		"id": id,
		"type_id": type_id,
		"intensity": intensity,
		"revealed": revealed,
		"nature": nature if revealed else "",
		"weakness": weakness if revealed else "",
		"active": is_active(),
	}
