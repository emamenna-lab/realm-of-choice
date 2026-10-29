extends "res://scripts/ui/minigames/minigame_base.gd"
## Fascino: la folla ha un umore (rabbia, paura, orgoglio) e la regina sceglie una di tre frasi.
## Con Fascino alto: una frase sbagliata viene scartata, e poi si sente il grido della folla
## con la parola chiave in evidenza.


func _ready() -> void:
	var col := UiKit.screen_column(self, true)
	col.add_child(UiKit.title("Prova di Fascino"))
	col.add_child(UiKit.label("Contro %s" % outbreak_name(), UiKit.FONT_BODY, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))

	var round_data: Dictionary = params["round"]
	var cry: Dictionary = round_data["cry"]
	if not cry.is_empty():
		var rich := RichTextLabel.new()
		rich.bbcode_enabled = true
		rich.fit_content = true
		rich.scroll_active = false
		rich.add_theme_font_size_override("normal_font_size", UiKit.FONT_BODY)
		rich.add_theme_color_override("default_color", UiKit.INK)
		var text: String = cry["text"]
		var keyword: String = cry["keyword"]
		rich.text = "Dalla folla si leva un grido: «%s»" % text.replace(keyword, "[color=#%s][b]%s[/b][/color]" % [UiKit.GOLD.to_html(false), keyword])
		col.add_child(rich)
	else:
		col.add_child(UiKit.label("La folla ti fissa in silenzio. Cosa le dirai?", UiKit.FONT_BODY, UiKit.INK))

	var options: Array = round_data["options"]
	for n in options.size():
		var text: String = "«%s»" % options[n]["text"]
		var b := UiKit.button(text, _choose.bind(options[n]["mood"]))
		b.custom_minimum_size = Vector2(0, 190)
		b.add_theme_font_size_override("font_size", UiKit.FONT_SMALL + 2)
		if n == round_data["discarded"]:
			b.disabled = true
			b.tooltip_text = "Il tuo istinto la scarta."
		col.add_child(b)
	if round_data["discarded"] >= 0:
		col.add_child(UiKit.label("Il tuo istinto scarta una delle risposte.", UiKit.FONT_SMALL, UiKit.DIM))
	col.add_child(make_result_label())


func _choose(mood: String) -> void:
	if _done:
		return
	var right: bool = mood == params["mood"]
	var score := MinigameRules.charm_score(cfg, mood, params["mood"], params["fascino"])
	finish(score, 0, "La folla ascolta." if right else "Le parole cadono nel vuoto.")


func auto_play() -> void:
	_choose(params["mood"])
