class_name EnemyDatabase
extends RefCounted


const TEST_ENEMY := "test_enemy"
const SENZA_VOLTO := "senza_volto"


static func get_enemy(
	enemy_id: String
) -> EnemyData:
	match enemy_id:
		TEST_ENEMY:
			return _create_test_enemy()

		SENZA_VOLTO:
			return _create_senza_volto()

		_:
			push_error(
				"Nemico non trovato nel database: "
				+ enemy_id
			)

			return null


static func get_all_enemy_ids() -> Array[String]:
	return [
		TEST_ENEMY,
		SENZA_VOLTO
	]


static func _create_test_enemy() -> EnemyData:
	return EnemyData.new(
		"Nemico Test",
		25,
		6,
		1,
		10,
		18,
		12,
		14
	)


static func _create_senza_volto() -> EnemyData:
	return EnemyData.new(
		"Senza Volto",
		25,
		6,
		1,
		10,
		18,
		12,
		14
	)
