extends Control
## Regia delle schermate. Tiene la partita in corso e passa da una schermata all'altra
## in base alla fase del TurnEngine.

const MenuScreen := preload("res://scripts/ui/menu_screen.gd")
const MapScreen := preload("res://scripts/ui/map_screen.gd")
const CourtScreen := preload("res://scripts/ui/court_screen.gd")
const EndScreen := preload("res://scripts/ui/end_screen.gd")

## Minigioco per ciascun approccio.
const MINIGAMES := {
	"forza": preload("res://scripts/ui/minigames/force_bar.gd"),
	"ricchezza": preload("res://scripts/ui/minigames/wealth_offer.gd"),
	"fascino": preload("res://scripts/ui/minigames/charm_answer.gd"),
}

var cfg: GameConfig
var engine: TurnEngine
var _screen: Control
## Indice del primo evento non ancora raccontato sulla mappa.
var _event_cursor := 0


func _ready() -> void:
	theme = UiKit.make_theme()
	cfg = GameConfig.load_default()
	show_menu()


func show_menu() -> void:
	var s: Control = MenuScreen.new()
	s.start_requested.connect(start_game)
	_show(s)


func start_game(seed_value: int) -> void:
	engine = TurnEngine.new(cfg, seed_value)
	_event_cursor = engine.state.events.size()
	show_map()


func show_map() -> void:
	if engine.state.is_over():
		show_end()
		return
	var s: Control = MapScreen.new()
	s.setup(engine, _take_report())
	s.observe_requested.connect(func(id): engine.observe(id); show_map())
	s.wait_requested.connect(func(): engine.wait_day(); show_map())
	s.confront_requested.connect(_on_confront)
	_show(s)


func _on_confront(outbreak_id: int, approach: String) -> void:
	var params := engine.begin_confront(outbreak_id, approach)
	var s: Control = MINIGAMES[approach].new()
	s.setup(cfg, params)
	s.finished.connect(_on_minigame_finished)
	_show(s)


func _on_minigame_finished(score: float, coins_spent: int) -> void:
	var result := engine.resolve_confront(score, coins_spent)
	var s: Control = CourtScreen.new()
	s.setup(engine, result)
	s.answered.connect(func(respond): engine.answer_court(respond); show_map())
	_show(s)


func show_end() -> void:
	var s: Control = EndScreen.new()
	s.setup(engine)
	s.restart_requested.connect(show_menu)
	_show(s)


func _take_report() -> Array[String]:
	var fresh := engine.state.events.slice(_event_cursor)
	_event_cursor = engine.state.events.size()
	return EventText.describe_all(cfg, fresh)


func _show(screen: Control) -> void:
	if _screen:
		_screen.queue_free()
	_screen = screen
	add_child(screen)
