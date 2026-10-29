# Realm of Choice

Gioco strategico a turni per Android (Godot 4, GDScript).

Una regina ha 12 giorni per salvare il regno in rivolta: non può spegnere tutti i focolai, deve scegliere quali battaglie combattere.

## Struttura

- `data/` — tutto ciò che si bilancia o si scrive senza toccare il codice
  - `balance.json`: valori iniziali, soglie, probabilità, durate
  - `outbreak_types.json`: tipi di focolaio
  - `disturber_cards.json`: proposte del disturbatore
- `scripts/core/` — logica pura (nessun nodo, testabile senza grafica). `TurnEngine` è il punto d'ingresso.
- `tests/` — test headless, senza dipendenze esterne
- `tools/simulate.gd` — simulatore di bilanciamento

## Comandi

Richiede Godot 4.7.

```sh
godot --headless --path . --import                 # la prima volta, genera la cache delle classi
godot --headless --path . -s tests/run_tests.gd    # test
godot --headless --path . -s tools/simulate.gd -- 3000                                  # bilanciamento
godot --headless --path . -s tools/simulate.gd -- 3000 stability.daily_damage_multiplier=0.5   # prova una modifica
```

Il simulatore gioca migliaia di partite con strategie automatiche (passiva, casuale, avida, saggia, selettiva) e stampa vittorie, crolli e stabilità finale. Serve a confrontare configurazioni, non a prevedere il risultato di un giocatore umano.
