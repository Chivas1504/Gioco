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
		EnemyDatabase.TRASCINATO,
		Vector2i(3, 0)
	)

	encounter.add_enemy(
		EnemyDatabase.VEGLIANTE,
		Vector2i(6, 4)
	)

	encounter.add_enemy(
		EnemyDatabase.SORDO,
		Vector2i(8, 8)
	)

	return encounter
