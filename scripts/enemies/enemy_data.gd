class_name EnemyData
extends Resource


const PERCEPTION_SIGHT: String = "sight"
const PERCEPTION_NOISE: String = "noise"


var enemy_name: String = ""

var max_hp: int = 25
var attack_damage: int = 6
var move_range: int = 1

var body_parts: Dictionary = {}


var special_ability: String = ""
var special_range: int = 0
var special_pull_distance: int = 0
var special_required_part: String = ""


var detection_mode: String = PERCEPTION_SIGHT
var detection_range: float = 150.0


func _init(
	new_enemy_name: String = "",
	new_max_hp: int = 25,
	new_attack_damage: int = 6,
	new_move_range: int = 1,
	new_body_parts: Dictionary = {},
	new_special_ability: String = "",
	new_special_range: int = 0,
	new_special_pull_distance: int = 0,
	new_special_required_part: String = "",
	new_detection_mode: String = PERCEPTION_SIGHT,
	new_detection_range: float = 150.0
) -> void:
	enemy_name = new_enemy_name

	max_hp = new_max_hp
	attack_damage = new_attack_damage
	move_range = new_move_range

	body_parts = new_body_parts.duplicate(
		true
	)

	special_ability = new_special_ability
	special_range = new_special_range
	special_pull_distance = new_special_pull_distance
	special_required_part = new_special_required_part

	detection_mode = new_detection_mode
	detection_range = new_detection_range
