extends Control
## Base comune dei minigiochi. Ognuno riceve i parametri da TurnEngine.begin_confront()
## ed emette `finished` una sola volta, dopo aver mostrato l'esito per un istante.

signal finished(score: float, coins_spent: int)

const RESULT_PAUSE := 1.4

var cfg: GameConfig
var params: Dictionary
var _done := false
var _result_label: Label


func setup(config: GameConfig, confront_params: Dictionary) -> void:
	cfg = config
	params = confront_params


## Il nome del focolaio affrontato, per i titoli.
func outbreak_name() -> String:
	return UiKit.type_name(cfg, params["type_id"])


func make_result_label() -> Label:
	_result_label = UiKit.label("", UiKit.FONT_TITLE, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_result_label.custom_minimum_size = Vector2(0, 120)
	return _result_label


## Chiude il minigioco: mostra l'esito, attende, poi emette `finished`.
func finish(score: float, coins_spent := 0, note := "") -> void:
	if _done:
		return
	_done = true
	var outcome := MinigameRules.outcome_for(cfg, score)
	if _result_label:
		_result_label.text = UiKit.OUTCOME_NAMES[outcome] + ("\n" + note if note != "" else "")
		_result_label.add_theme_color_override("font_color", UiKit.GOOD if outcome == Defs.OUTCOME_VICTORY else UiKit.DANGER)
	await get_tree().create_timer(RESULT_PAUSE).timeout
	finished.emit(score, coins_spent)


## Gioca da solo nel modo migliore. Solo per i test automatici dell'interfaccia.
func auto_play() -> void:
	pass
