class_name Defs
extends RefCounted
## Identificatori condivisi da logica, dati e UI.

const FORZA := "forza"
const RICCHEZZA := "ricchezza"
const FASCINO := "fascino"
const SAGGEZZA := "saggezza"

## Approcci con cui si può affrontare un focolaio.
const APPROACHES: Array[String] = [FORZA, RICCHEZZA, FASCINO]
## Statistiche a punteggio (1-10). La ricchezza è una riserva di monete, a parte.
const SCORE_STATS: Array[String] = [FORZA, FASCINO, SAGGEZZA]

const NATURE_ESTINGUE := "estingue"
const NATURE_CRESCE := "cresce"
const NATURE_TRAPPOLA := "trappola"
const NATURES: Array[String] = [NATURE_ESTINGUE, NATURE_CRESCE, NATURE_TRAPPOLA]

const MOODS: Array[String] = ["rabbia", "paura", "orgoglio"]

const OUTCOME_VICTORY := "vittoria"
const OUTCOME_LIGHT := "sconfitta_lieve"
const OUTCOME_MEDIUM := "sconfitta_media"
const OUTCOME_HEAVY := "sconfitta_netta"

const CARD_USEFUL := "utile"
const CARD_FLATTERY := "lusinga"
const CARD_POISONED := "avvelenata"
const CARD_PROVOCATION := "provocazione"
const CARD_LABELS: Array[String] = [CARD_USEFUL, CARD_FLATTERY, CARD_POISONED, CARD_PROVOCATION]

const RESULT_NONE := ""
const RESULT_WIN := "vittoria"
const RESULT_COLLAPSE := "sconfitta_crollo"
const RESULT_WEAK := "sconfitta_regno_debole"
