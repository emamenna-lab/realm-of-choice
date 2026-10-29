# Realm of Choice

Gioco strategico a turni per Android (Godot 4, GDScript).

Una regina ha 12 giorni per salvare il regno in rivolta: non può spegnere tutti i focolai, deve scegliere quali battaglie combattere.

## Struttura

- `data/` — tutto ciò che si bilancia o si scrive senza toccare il codice
  - `balance.json`: valori iniziali, soglie, probabilità, durate
  - `outbreak_types.json`: tipi di focolaio
  - `disturber_cards.json`: proposte del disturbatore
  - `charm_phrases.json`: frasi della regina e grida della folla per il minigioco del Fascino
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

## Interfaccia

`scenes/main.tscn` è la scena principale. Le schermate (`scripts/ui/`) sono costruite da codice e leggono lo stato dal `TurnEngine`. I minigiochi sono intercambiabili: ognuno riceve i parametri da `begin_confront()` ed emette `finished(score, coins_spent)`; la tabella `MINIGAMES` in `main.gd` dice quale usare per ogni approccio. Stanno in `scripts/ui/minigames/`:

- **Forza** (`force_bar.gd`): un ago va e viene; si tocca quando è nella zona dorata. Zona più larga con più Forza, ago più veloce con più intensità. Allo scadere del tempo è una disfatta.
- **Ricchezza** (`wealth_offer.gd`): si sceglie quante monete offrire contro una soglia nascosta (intensità × 2 ± 1).
- **Fascino** (`charm_answer.gd`): tre frasi, una per umore. Con Fascino ≥ 5 una frase sbagliata viene scartata; con Fascino ≥ 8 si sente il grido della folla con la parola chiave in evidenza.

```sh
godot --headless --path . -s tools/ui_smoke.gd        # percorre tutte le schermate fino a fine partita
godot --path . --resolution 720x1280 -s tools/ui_smoke.gd -- /cartella/screenshot   # idem, con screenshot
```
