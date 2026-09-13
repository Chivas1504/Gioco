class_name RoomData
extends Resource


var room_id: String = ""
var room_name: String = ""

var combat_group_ids: Array[String] = []

var is_safe_room: bool = false
var is_boss_room: bool = false
var locks_during_combat: bool = true


func _init(
	new_room_id: String = "",
	new_room_name: String = "",
	new_combat_group_ids: Array[String] = [],
	new_is_safe_room: bool = false,
	new_is_boss_room: bool = false,
	new_locks_during_combat: bool = true
) -> void:
	room_id = new_room_id
	room_name = new_room_name

	combat_group_ids = (
		new_combat_group_ids.duplicate()
	)

	is_safe_room = new_is_safe_room
	is_boss_room = new_is_boss_room
	locks_during_combat = new_locks_during_combat


func contains_combat_group(
	combat_group_id: String
) -> bool:
	return combat_group_id in combat_group_ids
