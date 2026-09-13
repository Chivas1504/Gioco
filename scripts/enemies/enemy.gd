class_name EnemyUnit
extends Node2D


var enemy_data: EnemyData

var current_hp: int = 0

var body_integrity: Dictionary = {}
var body_max_integrity: Dictionary = {}

var status_manager: StatusManager = StatusManager.new()


func _ready() -> void:
	queue_redraw()


func setup(
	data: EnemyData
) -> void:
	enemy_data = data

	current_hp = enemy_data.max_hp

	body_integrity = enemy_data.body_parts.duplicate(
		true
	)

	body_max_integrity = enemy_data.body_parts.duplicate(
		true
	)

	status_manager = StatusManager.new()

	queue_redraw()


func _draw() -> void:
	draw_circle(
		Vector2.ZERO,
		20.0,
		Color(
			0.75,
			0.08,
			0.08
		)
	)


func get_enemy_name() -> String:
	if enemy_data == null:
		return "Nemico"

	return enemy_data.enemy_name


func get_hp() -> int:
	return current_hp


func get_max_hp() -> int:
	if enemy_data == null:
		return 0

	return enemy_data.max_hp


func is_dead() -> bool:
	return current_hp <= 0


func take_vitality_damage(
	damage: int
) -> int:
	if damage <= 0:
		return 0

	if is_dead():
		return 0

	var old_hp: int = current_hp

	current_hp -= damage

	if current_hp < 0:
		current_hp = 0

	return old_hp - current_hp


func modify_incoming_attack_damage(
	damage: int
) -> int:
	var result: float = float(
		damage
	)

	if _is_part_destroyed(
		"Torso"
	):
		result *= 1.25

	if status_manager.has_fracture(
		"Torso"
	):
		result *= 1.10

	return maxi(
		roundi(
			result
		),
		0
	)


func take_part_damage(
	part_name: String,
	damage: int
) -> Dictionary:
	if not body_integrity.has(
		part_name
	):
		return {
			"part_damage": 0,
			"vitality_damage": 0,
			"destroyed": false
		}

	if damage <= 0:
		return {
			"part_damage": 0,
			"vitality_damage": 0,
			"destroyed": _is_part_destroyed(
				part_name
			)
		}

	var old_integrity: int = int(
		body_integrity[
			part_name
		]
	)

	var new_integrity: int = maxi(
		old_integrity - damage,
		0
	)

	body_integrity[
		part_name
	] = new_integrity

	var actual_part_damage: int = (
		old_integrity - new_integrity
	)

	var transfer_ratio: float = (
		_get_vitality_transfer_ratio(
			part_name
		)
	)

	var vitality_damage: int = roundi(
		float(
			actual_part_damage
		)
		* transfer_ratio
	)

	vitality_damage = take_vitality_damage(
		vitality_damage
	)

	return {
		"part_damage": actual_part_damage,
		"vitality_damage": vitality_damage,
		"destroyed": new_integrity <= 0
	}


func apply_fracture(
	part_name: String
) -> void:
	if not body_integrity.has(
		part_name
	):
		return

	status_manager.add_fracture(
		part_name
	)


func begin_activation() -> Dictionary:
	var result: Dictionary = (
		status_manager.begin_activation()
	)

	var burn_damage: int = int(
		result.get(
			"burn_damage",
			0
		)
	)

	if burn_damage > 0:
		var damage_done: int = (
			take_vitality_damage(
				burn_damage
			)
		)

		result[
			"burn_damage_applied"
		] = damage_done

	return result


func end_activation() -> Dictionary:
	var result: Dictionary = (
		status_manager.end_activation()
	)

	var bleeding_damage: int = int(
		result.get(
			"bleeding_damage",
			0
		)
	)

	if bleeding_damage > 0:
		var damage_done: int = (
			take_vitality_damage(
				bleeding_damage
			)
		)

		result[
			"bleeding_damage_applied"
		] = damage_done

	return result


func get_body_part_names() -> Array[String]:
	var result: Array[String] = []

	for part_name in body_integrity.keys():
		result.append(
			str(
				part_name
			)
		)

	return result


func get_part_integrity(
	part_name: String
) -> int:
	if not body_integrity.has(
		part_name
	):
		return 0

	return int(
		body_integrity[
			part_name
		]
	)


func get_part_max_integrity(
	part_name: String
) -> int:
	if not body_max_integrity.has(
		part_name
	):
		return 0

	return int(
		body_max_integrity[
			part_name
		]
	)


func get_move_range() -> int:
	if enemy_data == null:
		return 0

	if status_manager.is_immobilized():
		return 0

	if _is_part_destroyed(
		"Gambe"
	):
		return 0

	var result: int = enemy_data.move_range

	if status_manager.has_fracture(
		"Gambe"
	):
		result -= 1

	if status_manager.is_slowed():
		result -= 1

	return maxi(
		result,
		0
	)


func can_move() -> bool:
	return get_move_range() > 0


func get_attack_damage() -> int:
	if enemy_data == null:
		return 0

	var result: int = (
		enemy_data.attack_damage
	)

	if _is_part_destroyed(
		"Testa"
	):
		result = mini(
			result,
			4
		)

	if _is_part_destroyed(
		"Braccia"
	):
		result = mini(
			result,
			3
		)

	if status_manager.has_fracture(
		"Testa"
	):
		result -= 1

	if status_manager.has_fracture(
		"Braccia"
	):
		result -= 2

	return maxi(
		result,
		0
	)


func get_special_ability() -> String:
	if enemy_data == null:
		return ""

	return enemy_data.special_ability


func get_special_range() -> int:
	if enemy_data == null:
		return 0

	return enemy_data.special_range


func get_special_pull_distance() -> int:
	if enemy_data == null:
		return 0

	return enemy_data.special_pull_distance


func can_use_special_ability() -> bool:
	if enemy_data == null:
		return false

	if enemy_data.special_ability.is_empty():
		return false

	if enemy_data.special_required_part.is_empty():
		return true

	return not _is_part_destroyed(
		enemy_data.special_required_part
	)


func get_detection_mode() -> String:
	if enemy_data == null:
		return EnemyData.PERCEPTION_SIGHT

	return enemy_data.detection_mode


func get_detection_range() -> float:
	if enemy_data == null:
		return 0.0

	return enemy_data.detection_range


func _is_part_destroyed(
	part_name: String
) -> bool:
	if not body_integrity.has(
		part_name
	):
		return false

	return int(
		body_integrity[
			part_name
		]
	) <= 0


func _get_vitality_transfer_ratio(
	part_name: String
) -> float:
	match part_name:
		"Testa":
			return 1.0

		"Occhio":
			return 1.0

		"Torso":
			return 0.80

		"Braccia":
			return 0.65

		"Gambe":
			return 0.60

		_:
			return 0.50
