class_name EnemyDatabase
extends RefCounted


const TEST_ENEMY := "test_enemy"
const SENZA_VOLTO := "senza_volto"
const TRASCINATO := "trascinato"


static func get_enemy(
	enemy_id: String
) -> EnemyData:
	match enemy_id:
		TEST_ENEMY:
			return _create_test_enemy()

		SENZA_VOLTO:
			return _create_senza_volto()

		TRASCINATO:
			return _create_trascinato()

		_:
			push_error(
				"Nemico sconosciuto: "
				+ enemy_id
			)

			return null


static func get_all_enemy_ids() -> Array[String]:
	return [
		TEST_ENEMY,
		SENZA_VOLTO,
		TRASCINATO
	]


static func _create_test_enemy() -> EnemyData:
	return EnemyData.new(
		"Nemico Test",
		25,
		6,
		1,
		{
			"Testa": 10,
			"Torso": 18,
			"Braccia": 12,
			"Gambe": 14
		}
	)


static func _create_senza_volto() -> EnemyData:
	return EnemyData.new(
		"Senza Volto",
		25,
		6,
		1,
		{
			"Testa": 10,
			"Torso": 18,
			"Gambe": 14
		}
	)


static func _create_trascinato() -> EnemyData:
	return EnemyData.new(
		"Il Trascinato",
		22,
		5,
		2,
		{
			"Torso": 16,
			"Braccia": 14,
			"Gambe": 12
		},
		"chain_pull",
		3,
		1,
		"Braccia"
	)
