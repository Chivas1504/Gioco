# Inferno Roguelike

Prototipo Godot 4 per un roguelike deckbuilding 2D senza pesca, con carte sempre disponibili come build da combattimento.

## Regole implementate

- Vita e stamina partono da 30.
- Il gioco parte da un menu iniziale con Nuova run e Run corrente.
- La finestra parte massimizzata, e ridimensionabile, usa stretch canvas e puoi alternare fullscreen con `F11`, `Alt+Invio` o il bottone Schermo intero.
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
- La paura va da 0 a 100 e cresce se resti troppo senza salire di livello o se la vita scende sotto il 30%.
- Quando muori, la build corrente diventa un Boss Ombra che custodisce le anime perdute.
- Il primo incontro con l'Ombra e opzionale: puoi fuggire, ma la paura aumenta di 50.
- Se fuggi, l'Ombra puo tornare quando la paura arriva a 90; nel secondo incontro non puoi fuggire.
- Sconfiggere l'Ombra recupera le anime perdute e assegna un potenziamento speciale.
- Dopo una vittoria passi alla schermata Falò / Shop.
- La run usa una mappa a griglia: dal Falò/Shop puoi muoverti a nord, sud, est o ovest.
- Ogni nodo della griglia puo contenere combattimenti, eventi, mini-boss, boss o il boss finale della classe.
- La run parte dal punto A `(0,0)` e il prototipo mette il boss finale al punto B `(6,6)`.

## File principali

- `scripts/data/card_rules.gd`: costanti di gioco, rarita, limiti e penalita.
- `scripts/data/game_database.gd`: carte, classi, consumabili, manufatti e nemico prototipo.
- `scripts/run/run_state.gd`: stato persistente della run.
- `scripts/combat/combat_state.gd`: logica del combattimento a intenti.
- `scripts/main.gd`: UI di test per provare il loop.
