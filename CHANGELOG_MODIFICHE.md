# Changelog modifiche combat

- Rimossa la griglia tattica dal combattimento, insieme al click-to-move e ai riferimenti a path/celle nella scena principale.
- Il combattimento ora usa una disposizione scenica laterale: giocatore e nemici vengono messi in posa all'inizio dello scontro e tornano alle posizioni di esplorazione alla fine.
- Le carte sono l'unico sistema di azione in combattimento e restano sempre disponibili quando i requisiti sono soddisfatti.
- Aggiunti 3 Punti Azione per turno, sistema Sforzo, recupero di Sforzo a inizio turno e penalita ai PA quando il personaggio e affaticato.
- Trasformati gli effetti delle carte in logica senza griglia: probabilita di Sanguinamento, Marcato, Rallentato, Frattura condizionale e finisher Esecuzione sotto il 20% Vitalita.
- Aggiunta la carta Reazione "Parata dei Condannati", preparabile nel turno del giocatore senza QTE o finestre di timing.
- Il targeting anatomico si applica solo alle carte appropriate, come Chiodo del Giudizio e Maglio della Pena.
- Gli status anatomici e generali non sono piu garantiti: usano probabilita e bonus condizionali, per esempio bersaglio Marcato o gia Sanguinante.
- Aggiornata la UI per mostrare PA, Sforzo, Reazione pronta, Vitalita bersaglio, mira anatomica e status.
- Aggiunti log di combattimento e intento del nemico selezionato per rendere chiari danni, cure, reazioni e status riusciti o mancati.
- Mantenuti esplorazione, stanze, rilevamento nemici, gruppi di combattimento, anatomia, status e dati degli incontri.
