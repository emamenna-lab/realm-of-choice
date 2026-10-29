extends Control
## Fine partita: titolo, cronaca epica della partita, seme per rigiocarla.

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
	col.add_child(UiKit.label("Giorno %d · stabilità %d" % [s.day, s.stability], UiKit.FONT_SMALL, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var p := UiKit.panel(UiKit.PARCHMENT)
	var v := UiKit.vbox(16)
	for line in Chronicle.generate(engine.cfg, s):
		v.add_child(UiKit.label(line, UiKit.FONT_BODY, UiKit.INK))
	p.add_child(v)
	col.add_child(p)
	col.add_child(UiKit.label("Seme della partita: %d" % s.seed_value, UiKit.FONT_SMALL, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(UiKit.spacer())
	col.add_child(UiKit.button("Nuova partita", func(): restart_requested.emit()))
