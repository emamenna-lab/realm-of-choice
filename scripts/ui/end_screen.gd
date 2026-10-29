extends Control
## Fine partita. La cronaca epica arriva nella fase 5; per ora un riepilogo asciutto.

signal restart_requested

const TITLES := {
	"vittoria": "Il regno resiste",
	"sconfitta_crollo": "Il regno è caduto",
	"sconfitta_regno_debole": "Il regno sopravvive, spezzato",
}

var engine: TurnEngine


func setup(e: TurnEngine) -> void:
	engine = e


func _ready() -> void:
	var s := engine.state
	var col := UiKit.screen_column(self)
	col.add_child(UiKit.spacer())
	col.add_child(UiKit.title(TITLES[s.result]))
	var extinguished := s.events.filter(func(e): return e["kind"] == "spento").size()
	var lines := [
		"Giorno %d. Stabilità %d." % [s.day, s.stability],
		"Focolai spenti: %d. Ancora accesi: %d." % [extinguished, s.active_outbreaks().size()],
		"Seme della partita: %d" % s.seed_value,
	]
	for line in lines:
		col.add_child(UiKit.label(line, UiKit.FONT_BODY, UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(UiKit.spacer())
	col.add_child(UiKit.button("Nuova partita", func(): restart_requested.emit()))
