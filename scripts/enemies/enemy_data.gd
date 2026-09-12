class_name EnemyData
extends Resource


var enemy_name: String = ""

var max_hp: int = 25
var attack_damage: int = 6
var move_range: int = 1

var body_parts: Dictionary = {}


func _init(
	new_enemy_name: String = "",
	new_max_hp: int = 25,
	new_attack_damage: int = 6,
	new_move_range: int = 1,
	new_body_parts: Dictionary = {}
) -> void:
	enemy_name = new_enemy_name
	max_hp = new_max_hp
	attack_damage = new_attack_damage
	move_range = new_move_range

	body_parts = new_body_parts.duplicate(
		true
	)
