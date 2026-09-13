class_name EnemyDatabase
extends RefCounted


const TEST_ENEMY := "test_enemy"

const SENZA_VOLTO := "senza_volto"
const TRASCINATO := "trascinato"
const VEGLIANTE := "vegliante"
const SORDO := "sordo"


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

		VEGLIANTE:
			return _create_vegliante()

		SORDO:
			return _create_sordo()

		_:
			push_error(
				"Nemico sconosciuto: "
				+ enemy_id
			)

			return null


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
		},
		"",
		0,
		"",
		EnemyData.PERCEPTION_SIGHT,
		150.0
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
		},
		"",
		0,
		"",
		EnemyData.PERCEPTION_SIGHT,
		150.0
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
		EnemyAbilitySystem.ACTION_CHAIN_PULL,
		3,
		"Braccia",
		EnemyData.PERCEPTION_SIGHT,
		130.0
	)


static func _create_vegliante() -> EnemyData:
	return EnemyData.new(
		"Il Vegliante",
		20,
		4,
		1,
		{
			"Occhio": 10,
			"Torso": 14,
			"Braccia": 10
		},
		EnemyAbilitySystem.ACTION_RANGED_ATTACK,
		5,
		"Occhio",
		EnemyData.PERCEPTION_SIGHT,
		230.0
	)


static func _create_sordo() -> EnemyData:
	return EnemyData.new(
		"Il Sordo",
		28,
		7,
		2,
		{
			"Testa": 12,
			"Torso": 18,
			"Braccia": 14,
			"Gambe": 16
		},
		"",
		0,
		"",
		EnemyData.PERCEPTION_NOISE,
		190.0
	)
