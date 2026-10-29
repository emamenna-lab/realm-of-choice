extends SceneTree
## Percorre l'interfaccia da capo a fine partita e salva uno screenshot per schermata.
## Serve a verificare che nessuna schermata vada in errore.
##
##   godot --path . --resolution 720x1280 -s tools/ui_smoke.gd -- <cartella_screenshot>
## (con rendering; su un server senza schermo: xvfb-run ... --rendering-driver opengl3)

var out_dir := ""
var main: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ""
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _run() -> void:
	await _shot("01_menu")
	main.start_game(77)
	await _shot("02_mappa")
	var first: Outbreak = main.engine.state.active_outbreaks()[0]
	main._screen._open_sheet(first.id)
	await _shot("03_azioni")
	main._on_confront(first.id, Defs.FASCINO)
	await _shot("04_fascino")
	await _auto_play()
	await _shot("05_corte")
	main._screen.answered.emit(false)
	await _shot("06_mappa_resoconto")

	# Uno screenshot per ciascuno degli altri due minigiochi.
	var approaches := [Defs.FORZA, Defs.RICCHEZZA, Defs.FASCINO]
	for step in [[Defs.FORZA, "08_forza"], [Defs.RICCHEZZA, "09_ricchezza"]]:
		var active: Array[Outbreak] = main.engine.state.active_outbreaks()
		if main.engine.state.is_over() or active.is_empty() or not main.engine.can_confront(active[0].id, step[0]):
			continue
		main._on_confront(active[0].id, step[0])
		await _shot(step[1])
		await _auto_play()
		main._screen.answered.emit(false)
		await process_frame

	# Poi gioca fino alla fine alternando osservazioni e scontri con tutti e tre i minigiochi.
	var turns := 0
	while not main.engine.state.is_over() and turns < 40:
		turns += 1
		var active: Array[Outbreak] = main.engine.state.active_outbreaks()
		if active.is_empty():
			main._screen.wait_requested.emit()
		elif turns % 3 == 0 and not active[0].revealed:
			main._screen.observe_requested.emit(active[0].id)
		else:
			var approach: String = approaches[turns % 3]
			if not main.engine.can_confront(active[0].id, approach):
				approach = Defs.FORZA
			main._on_confront(active[0].id, approach)
			await _auto_play()
			main._screen.answered.emit(turns % 2 == 0)
		await process_frame
	await _shot("07_fine")
	print("UI percorsa: %d turni, esito %s" % [turns, main.engine.state.result])
	quit()


## Fa giocare da solo il minigioco aperto e attende che emetta il risultato.
func _auto_play() -> void:
	var minigame: Control = main._screen
	minigame.auto_play()
	await minigame.finished
	await process_frame


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	# In headless non si disegna nulla: frame_post_draw non arriverebbe mai.
	if out_dir == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
