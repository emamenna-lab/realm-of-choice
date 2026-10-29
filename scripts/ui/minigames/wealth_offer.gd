extends "res://scripts/ui/minigames/minigame_base.gd"
## Ricchezza: si sceglie quante monete offrire. Sotto la soglia nascosta si fallisce,
## sopra si spreca. Le monete offerte sono perse in ogni caso.

var _offer := 0
var _offer_label: Label
var _offer_button: Button


func _ready() -> void:
	var col := UiKit.screen_column(self)
	col.add_child(UiKit.title("Prova di Ricchezza"))
	col.add_child(UiKit.label("Contro %s" % outbreak_name(), UiKit.FONT_BODY, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(UiKit.spacer())
	col.add_child(UiKit.label("Quanto oro basterà a comprare la pace?", UiKit.FONT_BODY, UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(UiKit.label("Intensità  " + UiKit.pips(params["intensity"]), UiKit.FONT_BODY, UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER))

	_offer_label = UiKit.label("", 96, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(_offer_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	var minus := UiKit.button("−", _change.bind(-1))
	var plus := UiKit.button("+", _change.bind(1))
	for b in [minus, plus]:
		b.custom_minimum_size = Vector2(0, 140)
		b.add_theme_font_size_override("font_size", 64)
		row.add_child(b)
	col.add_child(row)
	col.add_child(UiKit.label("Nel tesoro: %d monete" % params["coins"], UiKit.FONT_SMALL, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(make_result_label())
	col.add_child(UiKit.spacer())

	_offer_button = UiKit.button("", _confirm)
	col.add_child(_offer_button)
	_refresh()


func _change(delta: int) -> void:
	if _done:
		return
	_offer = clampi(_offer + delta, 0, params["coins"])
	_refresh()


func _refresh() -> void:
	_offer_label.text = str(_offer)
	_offer_button.text = "Offri %d monet%s" % [_offer, "a" if _offer == 1 else "e"]
	_offer_button.disabled = _offer == 0


func _confirm() -> void:
	if _done:
		return
	var score := MinigameRules.wealth_score(cfg, _offer, params["threshold"])
	var note := "L'oro placa la folla." if score >= 1.0 else "L'oro non basta."
	finish(score, _offer, note)


func auto_play() -> void:
	_offer = mini(params["coins"], params["threshold"])
	_confirm()
