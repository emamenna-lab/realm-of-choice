class_name OutbreakFactory
extends RefCounted
## Genera focolai casuali combinando tipo, natura nascosta e debolezza nascosta.

var cfg: GameConfig
var rng: RandomNumberGenerator


func _init(config: GameConfig, random: RandomNumberGenerator) -> void:
	cfg = config
	rng = random


func create(state: GameState, intensity: int, origin: String, type_id := "") -> Outbreak:
	var o := Outbreak.new()
	o.id = state.next_outbreak_id
	state.next_outbreak_id += 1
	var type_def: Dictionary = cfg.type_by_id(type_id) if type_id != "" else _pick(cfg.spawnable_types())
	o.type_id = type_def["id"]
	o.nature = _weighted_nature()
	o.weakness = _pick(Defs.APPROACHES)
	o.mood = _pick(type_def["moods"])
	o.intensity = clampi(intensity, 1, cfg.i("outbreaks.intensity_max"))
	o.origin = origin
	return o


func create_initial(state: GameState) -> Array[Outbreak]:
	var result: Array[Outbreak] = []
	var count := rng.randi_range(cfg.i("outbreaks.initial_count_min"), cfg.i("outbreaks.initial_count_max"))
	var used_types := {}
	for n in count:
		# Tipi diversi finché possibile: una città con tre rivolte del pane è meno leggibile.
		var available := cfg.spawnable_types().filter(func(t): return not used_types.has(t["id"]))
		if available.is_empty():
			available = cfg.spawnable_types()
		var t: Dictionary = _pick(available)
		used_types[t["id"]] = true
		var intensity := rng.randi_range(cfg.i("outbreaks.initial_intensity_min"), cfg.i("outbreaks.initial_intensity_max"))
		result.append(create(state, intensity, "iniziale", t["id"]))
	return result


func create_rancor(state: GameState) -> Outbreak:
	var o := create(state, cfg.i("outbreaks.rancor.intensity"), "rancore", cfg.value("outbreaks.rancor.type"))
	o.nature = cfg.value("outbreaks.rancor.nature")
	o.weakness = cfg.value("outbreaks.rancor.weakness")
	return o


func _weighted_nature() -> String:
	var weights: Dictionary = cfg.value("outbreaks.nature_weights")
	var total := 0.0
	for n in Defs.NATURES:
		total += float(weights.get(n, 0))
	var roll := rng.randf() * total
	for n in Defs.NATURES:
		roll -= float(weights.get(n, 0))
		if roll < 0.0:
			return n
	return Defs.NATURES[-1]


func _pick(items: Array) -> Variant:
	return items[rng.randi_range(0, items.size() - 1)]
