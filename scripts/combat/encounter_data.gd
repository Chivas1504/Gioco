class_name EncounterData
extends Resource


class EncounterEnemy:
	var enemy_id: String = ""
	var spawn_cell: Vector2i = Vector2i.ZERO

	func _init(
		new_enemy_id: String = "",
		new_spawn_cell: Vector2i = Vector2i.ZERO
	) -> void:
		enemy_id = new_enemy_id
		spawn_cell = new_spawn_cell


var encounter_id: String = ""
var encounter_name: String = ""

var enemies: Array[EncounterEnemy] = []


func _init(
	new_encounter_id: String = "",
	new_encounter_name: String = ""
) -> void:
	encounter_id = new_encounter_id
	encounter_name = new_encounter_name


func add_enemy(
	enemy_id: String,
	spawn_cell: Vector2i
) -> void:
	var enemy_entry: EncounterEnemy = (
		EncounterEnemy.new(
			enemy_id,
			spawn_cell
		)
	)

	enemies.append(
		enemy_entry
	)


func get_enemy_count() -> int:
	return enemies.size()


func get_enemy(
	index: int
) -> EncounterEnemy:
	if index < 0:
		return null

	if index >= enemies.size():
		return null

	return enemies[index]
