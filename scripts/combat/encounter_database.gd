class_name EncounterDatabase
extends RefCounted


const LIMBO_TEST := "limbo_test"


static func get_encounter(
	encounter_id: String
) -> EncounterData:
	match encounter_id:
		LIMBO_TEST:
			return _create_limbo_test()

		_:
			push_error(
				"Encounter sconosciuto: "
				+ encounter_id
			)

			return null


static func _create_limbo_test() -> EncounterData:
	var encounter := EncounterData.new(
		LIMBO_TEST,
		"Limbo - Incontro di test"
	)

	encounter.add_enemy(
		EnemyDatabase.SENZA_VOLTO,
		Vector2i(6, 4)
	)

	encounter.add_enemy(
		EnemyDatabase.SENZA_VOLTO,
		Vector2i(7, 7)
	)

	return encounter
