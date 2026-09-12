class_name CardDatabase
extends RefCounted


const MANNAIA_DEL_CARNEFICE := "mannaia_del_carnefice"
const CHIODO_DEL_GIUDIZIO := "chiodo_del_giudizio"
const MAGLIO_DELLA_PENA := "maglio_della_pena"
const BENDE_DEL_VIANDANTE := "bende_del_viandante"
const CATENA_DEL_CONTRAPPASSO := "catena_del_contrappasso"
const SPINTA_DEI_CONDANNATI := "spinta_dei_condannati"


static func get_card(card_id: String) -> CardData:
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

		SPINTA_DEI_CONDANNATI:
			return _create_spinta_dei_condannati()

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
		SPINTA_DEI_CONDANNATI
	]


static func _create_mannaia_del_carnefice() -> CardData:
	var tags: Array[String] = [
		"Taglio",
		"Mischia"
	]

	return CardData.new(
		"Mannaia del Carnefice",
		1,
		7,
		0,
		1,
		0,
		0,
		tags
	)


static func _create_chiodo_del_giudizio() -> CardData:
	var tags: Array[String] = [
		"Perforazione",
		"Distanza",
		"Mira"
	]

	return CardData.new(
		"Chiodo del Giudizio",
		1,
		6,
		0,
		5,
		0,
		0,
		tags
	)


static func _create_maglio_della_pena() -> CardData:
	var tags: Array[String] = [
		"Impatto",
		"Mischia",
		"Pesante"
	]

	return CardData.new(
		"Maglio della Pena",
		2,
		10,
		0,
		1,
		0,
		0,
		tags
	)


static func _create_bende_del_viandante() -> CardData:
	var tags: Array[String] = [
		"Cura",
		"Supporto"
	]

	return CardData.new(
		"Bende del Viandante",
		1,
		0,
		6,
		0,
		0,
		0,
		tags
	)


static func _create_catena_del_contrappasso() -> CardData:
	var tags: Array[String] = [
		"Impatto",
		"Distanza",
		"Controllo",
		"Tiro"
	]

	return CardData.new(
		"Catena del Contrappasso",
		1,
		4,
		0,
		3,
		1,
		0,
		tags
	)


static func _create_spinta_dei_condannati() -> CardData:
	var tags: Array[String] = [
		"Impatto",
		"Mischia",
		"Controllo",
		"Spinta"
	]

	return CardData.new(
		"Spinta dei Condannati",
		1,
		3,
		0,
		1,
		0,
		1,
		tags
	)
