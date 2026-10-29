extends TestCase


func test_daily_damage_equals_total_intensity() -> void:
	var e := empty_engine()
	add_outbreak(e, 3, Defs.NATURE_TRAPPOLA)
	var target := add_outbreak(e, 2, Defs.NATURE_TRAPPOLA)
	e.observe(target.id)
	check_eq(e.state.stability, 55, "60 - (3+2)")
	check_eq(e.state.day, 2, "osservare consuma un giorno")


func test_damage_multiplier() -> void:
	var cfg := fresh_config()
	cfg.balance["stability"]["daily_damage_multiplier"] = 0.5
	var e := empty_engine(cfg)
	var o := add_outbreak(e, 4, Defs.NATURE_TRAPPOLA)
	e.observe(o.id)
	check_eq(e.state.stability, 58, "4 x 0.5")


func test_nature_extinguishes() -> void:
	var e := empty_engine()
	var o := add_outbreak(e, 2, Defs.NATURE_ESTINGUE)
	var other := add_outbreak(e, 1, Defs.NATURE_TRAPPOLA)
	e.observe(other.id)
	check_eq(o.intensity, 1, "-1 al giorno se ignorato")
	e.observe(other.id)
	check(not o.is_active(), "si spegne da solo")
	check_eq(o.extinguished_day, 2, "giorno di estinzione")


func test_nature_grows_every_two_days() -> void:
	var e := empty_engine()
	var o := add_outbreak(e, 2, Defs.NATURE_CRESCE)
	var other := add_outbreak(e, 1, Defs.NATURE_TRAPPOLA)
	e.observe(other.id)
	check_eq(o.intensity, 2, "dopo 1 giorno ignorato")
	e.observe(other.id)
	check_eq(o.intensity, 3, "dopo 2 giorni ignorato")
	e.observe(other.id)
	e.observe(other.id)
	check_eq(o.intensity, 4, "dopo 4 giorni ignorato")


func test_growth_capped_at_max() -> void:
	var e := empty_engine()
	var o := add_outbreak(e, 5, Defs.NATURE_CRESCE)
	e.observe(o.id)
	e.observe(o.id)
	check_eq(o.intensity, 5, "intensità massima 5")


func test_trap_stable_when_ignored() -> void:
	var e := empty_engine()
	var o := add_outbreak(e, 3, Defs.NATURE_TRAPPOLA)
	for n in 4:
		e.observe(o.id)
	check_eq(o.intensity, 3, "la trappola ignorata resta stabile")


func test_confronting_resets_growth_counter() -> void:
	var e := empty_engine()
	var o := add_outbreak(e, 3, Defs.NATURE_CRESCE, Defs.FASCINO)
	var other := add_outbreak(e, 1, Defs.NATURE_TRAPPOLA)
	e.observe(other.id)
	check_eq(o.ignored_days, 1, "un giorno ignorato")
	e.begin_confront(o.id, Defs.FORZA)
	e.resolve_confront(0.4)
	e.answer_court(false)
	check_eq(o.ignored_days, 0, "affrontato oggi: contatore azzerato")
	check_eq(o.intensity, 3, "affrontato, non cresce")
