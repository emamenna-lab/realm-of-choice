class_name EventText
extends RefCounted
## Trasforma gli eventi del registro in righe per il resoconto della notte sulla mappa.
## Racconta cosa è successo, mai se era giusto.


static func describe(cfg: GameConfig, e: Dictionary) -> String:
	match e["kind"]:
		"fine_giorno":
			return "Cala la notte sul giorno %d: la stabilità perde %d." % [e["day"], e["damage"]]
		"spento":
			var name := UiKit.type_name(cfg, e["type_id"])
			return ("%s si spegne." if e["how"] == "vinto" else "%s si spegne da sé.") % name
		"nuovo_focolaio":
			var name := UiKit.type_name(cfg, e["type_id"], true)
			match e["origin"]:
				"trappola":
					return "Dalle braci dello scontro divampa %s." % name
				"rancore":
					return "Dove è passato il ferro nasce %s." % name
				"veleno":
					return "Un dono di corte porta con sé %s." % name
			return "Divampa %s." % name
		"veleno":
			if e["effect"] == "stat":
				return "Un dono di corte mostra il suo prezzo: %s cala." % UiKit.APPROACH_NAMES[e["stat"]]
		"lusinga_svanita":
			return "Il fervore svanisce: %s torna com'era." % UiKit.APPROACH_NAMES[e["stat"]]
		"proposta":
			var parts: Array[String] = []
			for stat in e["changes"]:
				var delta: int = e["changes"][stat]
				var name: String = "Monete" if stat == Defs.RICCHEZZA else UiKit.APPROACH_NAMES[stat]
				parts.append("%s %s%d" % [name, "+" if delta > 0 else "-", absi(delta)])
			if e["responded"]:
				return "Hai accolto la proposta del Cortigiano." + (" " + ", ".join(parts) + "." if not parts.is_empty() else "")
			if not parts.is_empty():
				return "Hai congedato il Cortigiano, e l'offesa resta: " + ", ".join(parts) + "."
		"focolaio_evitato":
			return "La città è satura di fuochi: una nuova scintilla si perde nel caos."
	return ""


static func describe_all(cfg: GameConfig, events: Array) -> Array[String]:
	var lines: Array[String] = []
	for e in events:
		var line := describe(cfg, e)
		if line != "":
			lines.append(line)
	return lines
