extends Control
## Segnaposto della fase 2: al posto del minigioco si sceglie il punteggio a mano.
## Stessa interfaccia dei minigiochi veri: setup() prima di entrare in scena, poi `finished`.

signal finished(score: float, coins_spent: int)

const TITLES := {"forza": "Prova di Forza", "ricchezza": "Prova di Ricchezza", "fascino": "Prova di Fascino"}

var cfg: GameConfig
var params: Dictionary
var _slider: HSlider
var _value_label: Label


func setup(config: GameConfig, confront_params: Dictionary) -> void:
	cfg = config
	params = confront_params


func _ready() -> void:
	var col := UiKit.screen_column(self)
	var approach: String = params["approach"]
	col.add_child(UiKit.title(TITLES[approach]))
	col.add_child(UiKit.label("Minigioco segnaposto.", UiKit.FONT_SMALL, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(UiKit.spacer())

	_slider = HSlider.new()
	_slider.custom_minimum_size = Vector2(0, 80)
	_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if approach == Defs.RICCHEZZA:
		col.add_child(UiKit.label("Quante monete offri? Ne hai %d." % params["coins"], UiKit.FONT_BODY))
		col.add_child(UiKit.label("(debug) soglia nascosta: %d" % params["threshold"], UiKit.FONT_SMALL, UiKit.DIM))
		_slider.min_value = 0
		_slider.max_value = params["coins"]
		_slider.step = 1
		_slider.value = mini(params["coins"], params["threshold"])
	else:
		col.add_child(UiKit.label("Scegli il punteggio dello scontro.", UiKit.FONT_BODY))
		if approach == Defs.FASCINO:
			col.add_child(UiKit.label("(debug) umore del focolaio: %s" % params["mood"], UiKit.FONT_SMALL, UiKit.DIM))
		_slider.min_value = 0.0
		_slider.max_value = 1.0
		_slider.step = 0.05
		_slider.value = 0.6
	col.add_child(_slider)
	_value_label = UiKit.label("", UiKit.FONT_BODY, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(_value_label)
	_slider.value_changed.connect(func(_v): _refresh())
	_refresh()

	col.add_child(UiKit.spacer())
	col.add_child(UiKit.button("Conferma", _confirm))


func _score() -> float:
	if params["approach"] == Defs.RICCHEZZA:
		return MinigameRules.wealth_score(cfg, int(_slider.value), params["threshold"])
	return _slider.value


func _refresh() -> void:
	var score := _score()
	var outcome: String = UiKit.OUTCOME_NAMES[MinigameRules.outcome_for(cfg, score)]
	if params["approach"] == Defs.RICCHEZZA:
		_value_label.text = "%d monete → %s" % [int(_slider.value), outcome]
	else:
		_value_label.text = "%.2f → %s" % [score, outcome]


func _confirm() -> void:
	var coins := int(_slider.value) if params["approach"] == Defs.RICCHEZZA else 0
	finished.emit(_score(), coins)
