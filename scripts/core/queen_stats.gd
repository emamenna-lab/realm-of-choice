class_name QueenStats
extends RefCounted
## Statistiche della regina: valori base, modificatori temporanei e riserva di monete.

var base := {}
var coins := 0
## Modificatori temporanei: {"stat": String, "amount": int, "days_left": int}
var modifiers: Array[Dictionary] = []
var stat_min := 1
var stat_max := 10


func _init(cfg: GameConfig) -> void:
	stat_min = cfg.i("queen.stat_min")
	stat_max = cfg.i("queen.stat_max")
	for s in Defs.SCORE_STATS:
		base[s] = cfg.i("queen.initial." + s)
	coins = cfg.i("queen.initial.ricchezza")


func get_stat(stat: String) -> int:
	if stat == Defs.RICCHEZZA:
		return coins
	var total: int = base[stat]
	for m in modifiers:
		if m["stat"] == stat:
			total += m["amount"]
	return clampi(total, stat_min, stat_max)


func add_base(stat: String, amount: int) -> void:
	if stat == Defs.RICCHEZZA:
		coins = maxi(0, coins + amount)
	else:
		base[stat] = clampi(base[stat] + amount, stat_min, stat_max)


func add_modifier(stat: String, amount: int, days: int) -> void:
	modifiers.append({"stat": stat, "amount": amount, "days_left": days})


## Chiamato a fine giornata. Restituisce i modificatori scaduti.
func tick() -> Array[Dictionary]:
	var expired: Array[Dictionary] = []
	for m in modifiers:
		m["days_left"] -= 1
		if m["days_left"] <= 0:
			expired.append(m)
	for m in expired:
		modifiers.erase(m)
	return expired


func to_view() -> Dictionary:
	var v := {Defs.RICCHEZZA: coins}
	for s in Defs.SCORE_STATS:
		v[s] = get_stat(s)
	return v
