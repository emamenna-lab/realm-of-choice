extends "res://scripts/ui/minigames/minigame_base.gd"
## Forza: un ago corre avanti e indietro, si tocca quando è nella zona dorata.
## La zona si allarga con la Forza, l'ago accelera con l'intensità del focolaio.

const BAR_HEIGHT := 140.0

var _t := 0.0
var _bar: Control
var _time_label: Label


func _ready() -> void:
	var col := UiKit.screen_column(self)
	col.add_child(UiKit.title("Prova di Forza"))
	col.add_child(UiKit.label("Contro %s" % outbreak_name(), UiKit.FONT_BODY, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(UiKit.spacer())
	col.add_child(UiKit.label("Colpisci quando l'ago è nella zona dorata.", UiKit.FONT_BODY, UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER))

	_bar = Control.new()
	_bar.custom_minimum_size = Vector2(0, BAR_HEIGHT)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.draw.connect(_draw_bar)
	col.add_child(_bar)

	_time_label = UiKit.label("", UiKit.FONT_SMALL, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(_time_label)
	col.add_child(make_result_label())
	col.add_child(UiKit.spacer())

	var strike := UiKit.button("Colpisci!", _strike)
	strike.custom_minimum_size = Vector2(0, 240)
	strike.add_theme_font_size_override("font_size", UiKit.FONT_TITLE)
	col.add_child(strike)


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	var remaining: float = params["duration_seconds"] - _t
	_time_label.text = "%.1f s" % maxf(remaining, 0.0)
	_bar.queue_redraw()
	if remaining <= 0.0:
		finish(0.0, 0, "Il momento è passato.")


func _needle() -> float:
	return MinigameRules.needle_position(_t, params["needle_speed"])


func _strike() -> void:
	if not _done:
		finish(MinigameRules.force_score(cfg, _needle(), params["zone_half_width"]))


func _draw_bar() -> void:
	var w := _bar.size.x
	var h := _bar.size.y
	_bar.draw_rect(Rect2(0, h * 0.25, w, h * 0.5), Color("120e0b"))
	var half: float = params["zone_half_width"]
	var center: float = params["zone_center"]
	_bar.draw_rect(Rect2(w * (center - half), h * 0.25, w * half * 2.0, h * 0.5), UiKit.GOLD.darkened(0.25))
	_bar.draw_rect(Rect2(w * (center - half * 0.15), h * 0.25, w * half * 0.3, h * 0.5), UiKit.GOLD)
	var x := w * _needle()
	_bar.draw_line(Vector2(x, 0), Vector2(x, h), UiKit.INK, 8.0)


func auto_play() -> void:
	_t = params["zone_center"] / params["needle_speed"]
	_strike()
