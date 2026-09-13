class_name CardDatabase
extends RefCounted


const MANNAIA_DEL_CARNEFICE := "mannaia_del_carnefice"
const CHIODO_DEL_GIUDIZIO := "chiodo_del_giudizio"
const MAGLIO_DELLA_PENA := "maglio_della_pena"
const BENDE_DEL_VIANDANTE := "bende_del_viandante"
const CATENA_DEL_CONTRAPPASSO := "catena_del_contrappasso"
const PARATA_DEI_CONDANNATI := "parata_dei_condannati"
const ESECUZIONE := "esecuzione"


static func get_card(
	card_id: String
) -> CardData:
	match card_id:
		MANNAIA_DEL_CARNEFICE:
			return _create_mannaia_del_carnefice()

		CHIODO_DEL_GIUDIZIO:
			return _create_chiodo_del_giudizio()

		MAGLIO_DELLA_PENA:
			return _create_maglio_della_pena()

		BENDE_DEL_VIANDANTE:
			return _create_bende_del_viandante()

		CATENA_DEL_CONTRAPPASSO:
			return _create_catena_del_contrappasso()

		PARATA_DEI_CONDANNATI:
			return _create_parata_dei_condannati()

		ESECUZIONE:
			return _create_esecuzione()

		_:
			push_error(
				"Carta non trovata nel CardDatabase: "
				+ card_id
			)

			return null


static func get_all_card_ids() -> Array[String]:
	return [
		MANNAIA_DEL_CARNEFICE,
		CHIODO_DEL_GIUDIZIO,
		MAGLIO_DELLA_PENA,
		BENDE_DEL_VIANDANTE,
		CATENA_DEL_CONTRAPPASSO,
		PARATA_DEI_CONDANNATI,
		ESECUZIONE
	]


static func _create_mannaia_del_carnefice() -> CardData:
	var tags: Array[String] = [
		"Taglio",
		"Mischia"
	]

	var card: CardData = CardData.new(
		"Mannaia del Carnefice",
		1,
		1,
		7,
		0,
		tags
	)

	card.status_to_apply = (
		StatusManager.BLEEDING
	)

	card.status_duration = 3
	card.status_stacks = 1
	card.status_chance = 0.15
	card.marked_status_bonus = 0.10
	card.conditional_status_name = StatusManager.BLEEDING
	card.conditional_status_bonus = 0.05

	return card


static func _create_chiodo_del_giudizio() -> CardData:
	var tags: Array[String] = [
		"Perforazione",
		"Distanza",
		"Mira"
	]

	var card: CardData = CardData.new(
		"Chiodo del Giudizio",
		1,
		1,
		5,
		0,
		tags
	)

	card.status_to_apply = (
		StatusManager.MARKED
	)

	card.status_duration = -1
	card.status_stacks = 1
	card.status_chance = 0.80

	return card


static func _create_maglio_della_pena() -> CardData:
	var tags: Array[String] = [
		"Impatto",
		"Mischia",
		"Pesante"
	]

	var card: CardData = CardData.new(
		"Maglio della Pena",
		2,
		2,
		10,
		0,
		tags
	)

	card.fracture_selected_part = true

	return card


static func _create_bende_del_viandante() -> CardData:
	var tags: Array[String] = [
		"Cura",
		"Supporto"
	]

	return CardData.new(
		"Bende del Viandante",
		2,
		-1,
		0,
		6,
		tags
	)


static func _create_catena_del_contrappasso() -> CardData:
	var tags: Array[String] = [
		"Impatto",
		"Distanza",
		"Controllo",
		"Tiro"
	]

	var card: CardData = CardData.new(
		"Catena del Contrappasso",
		2,
		1,
		6,
		0,
		tags
	)

	card.status_to_apply = (
		StatusManager.SLOWED
	)

	card.status_duration = 2
	card.status_stacks = 1
	card.status_chance = 0.35
	card.marked_status_bonus = 0.10

	return card


static func _create_parata_dei_condannati() -> CardData:
	var tags: Array[String] = [
		"Difesa",
		"Reazione",
		"Supporto"
	]

	var card: CardData = CardData.new(
		"Parata dei Condannati",
		1,
		0,
		0,
		0,
		tags
	)

	card.reaction_block = 5
	card.reaction_effort_relief = 1

	return card


static func _create_esecuzione() -> CardData:
	var tags: Array[String] = [
		"Finisher",
		"Pesante"
	]

	var card: CardData = CardData.new(
		"Esecuzione",
		3,
		3,
		22,
		0,
		tags
	)

	card.low_vitality_required_ratio = 0.20

	return card
