class_name EncounterData
extends Resource


class EncounterEnemy:
	var enemy_id: String = ""
	var spawn_cell: Vector2i = Vector2i.ZERO

	var room_id: String = ""
	var combat_group_id: String = ""

	func _init(
		new_enemy_id: String = "",
		new_spawn_cell: Vector2i = Vector2i.ZERO,
		new_room_id: String = "",
		new_combat_group_id: String = ""
	) -> void:
		enemy_id = new_enemy_id
		spawn_cell = new_spawn_cell

		room_id = new_room_id
		combat_group_id = new_combat_group_id


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
	spawn_cell: Vector2i,
	room_id: String = "",
	combat_group_id: String = ""
) -> void:
	var encounter_enemy := EncounterEnemy.new(
		enemy_id,
		spawn_cell,
		room_id,
		combat_group_id
	)

	enemies.append(
		encounter_enemy
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
