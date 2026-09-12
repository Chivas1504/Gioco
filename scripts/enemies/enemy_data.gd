class_name EnemyData
extends Resource


var enemy_name: String = ""

var max_hp: int = 25
var attack_damage: int = 6
var move_range: int = 1


var head_integrity: int = 10
var torso_integrity: int = 18
var arms_integrity: int = 12
var legs_integrity: int = 14


func _init(
	new_enemy_name: String = "",
	new_max_hp: int = 25,
	new_attack_damage: int = 6,
	new_move_range: int = 1,
	new_head_integrity: int = 10,
	new_torso_integrity: int = 18,
	new_arms_integrity: int = 12,
	new_legs_integrity: int = 14
) -> void:
	enemy_name = new_enemy_name

	max_hp = new_max_hp
	attack_damage = new_attack_damage
	move_range = new_move_range

	head_integrity = new_head_integrity
	torso_integrity = new_torso_integrity
	arms_integrity = new_arms_integrity
	legs_integrity = new_legs_integrity
