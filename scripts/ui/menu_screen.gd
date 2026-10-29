extends Control
## Schermata iniziale. Il seme è facoltativo: serve a rigiocare una partita identica nei test.

signal start_requested(seed_value: int)

var _seed_input: LineEdit


func _ready() -> void:
	var col := UiKit.screen_column(self)
	col.add_child(UiKit.spacer())
	col.add_child(UiKit.title("Realm of Choice"))
	col.add_child(UiKit.label("Il regno brucia. Hai dodici giorni.", UiKit.FONT_BODY, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(UiKit.spacer())
	col.add_child(UiKit.button("Nuova partita", func(): start_requested.emit(-1)))

	_seed_input = LineEdit.new()
	_seed_input.placeholder_text = "Seme (facoltativo)"
	_seed_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	_seed_input.custom_minimum_size = Vector2(0, UiKit.BUTTON_HEIGHT)
	_seed_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_seed_input)
	col.add_child(UiKit.button("Gioca con questo seme", _start_with_seed))


func _start_with_seed() -> void:
	var text := _seed_input.text.strip_edges()
	start_requested.emit(int(text) if text.is_valid_int() else -1)
