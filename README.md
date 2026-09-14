# Inferno Roguelike

Prototipo Godot 4 per un roguelike deckbuilding 2D senza pesca, con carte sempre disponibili come build da combattimento.

## Regole implementate

- Vita e stamina partono da 30.
- Perdi se vita o stamina arrivano a 0.
- Loadout iniziale di 4 carte neutrali.
- Le carte usate tornano disponibili dopo la risoluzione dell'intento nemico.
- Collezione massima: 40 carte.
- Loadout: minimo 4, massimo 12 carte.
- Consumabili previsti: massimo 4.
- Acquisire la prima carta di classe assegna quella classe se sei ancora Senzaclasse.
- Le carte fuori classe costano stamina extra in base alla rarita.
- Il level up si compra con anime, aumenta vita e stamina di +5 fino a 100 e potenzia una carta di +1.
- La stessa carta puo essere potenziata infinite volte, un livello alla volta.
- I nemici scalano con il potere della collezione, non con il livello personaggio.

## File principali

- `scripts/data/card_rules.gd`: costanti di gioco, rarita, limiti e penalita.
- `scripts/data/game_database.gd`: carte, classi, consumabili, manufatti e nemico prototipo.
- `scripts/run/run_state.gd`: stato persistente della run.
- `scripts/combat/combat_state.gd`: logica del combattimento a intenti.
- `scripts/main.gd`: UI di test per provare il loop.
