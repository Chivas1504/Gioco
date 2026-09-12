class_name EnemyUnit
extends Node2D


const RADIUS := 20.0

const HEAD_BROKEN_ATTACK_DAMAGE := 4
const ARMS_BROKEN_ATTACK_DAMAGE := 3

const TORSO_DESTROYED_MULTIPLIER := 1.25
const TORSO_FRACTURED_MULTIPLIER := 1.10

const MARKED_DAMAGE_MULTIPLIER := 1.25


var enemy_data: EnemyData

var hp: int = 0

var status_manager: StatusManager = StatusManager.new()

var body_parts: Dictionary = {}


func _ready() -> void:
	queue_redraw()


func setup(
	data: EnemyData
) -> void:
	enemy_data = data

	hp = enemy_data.max_hp

	status_manager.clear_all()

	body_parts.clear()

	for part_name in enemy_data.body_parts.keys():
		var max_integrity: int = int(
			enemy_data.body_parts[
				part_name
			]
		)

		body_parts[
			part_name
		] = {
			"integrity": max_integrity,
			"max_integrity": max_integrity
		}

	queue_redraw()


func _draw() -> void:
	draw_circle(
		Vector2.ZERO,
		RADIUS,
		Color(0.75, 0.1, 0.1)
	)


func get_enemy_name() -> String:
	if enemy_data == null:
		return "Nemico"

	return enemy_data.enemy_name


func get_hp() -> int:
	return hp


func get_max_hp() -> int:
	if enemy_data == null:
		return 0

	return enemy_data.max_hp


func is_dead() -> bool:
	return hp <= 0


func take_vitality_damage(
	damage: int
) -> int:
	if damage <= 0:
		return 0

	var final_damage: int = damage

	if _is_part_destroyed(
		"Torso"
	):
		final_damage = roundi(
			final_damage
			* TORSO_DESTROYED_MULTIPLIER
		)

	elif status_manager.has_fracture(
		"Torso"
	):
		final_damage = roundi(
			final_damage
			* TORSO_FRACTURED_MULTIPLIER
		)

	hp -= final_damage

	if hp < 0:
		hp = 0

	return final_damage


func modify_incoming_attack_damage(
	damage: int
) -> int:
	var final_damage: int = damage

	if status_manager.consume_marked():
		final_damage = roundi(
			final_damage
			* MARKED_DAMAGE_MULTIPLIER
		)

	return final_damage


func take_part_damage(
	part_name: String,
	damage: int
) -> Dictionary:
	var result: Dictionary = {
		"part_damage": 0,
		"vitality_damage": 0,
		"destroyed": false
	}

	if not body_parts.has(
		part_name
	):
		return result

	var part_data: Dictionary = (
		body_parts[
			part_name
		]
	)

	var old_integrity: int = int(
		part_data[
			"integrity"
		]
	)

	var new_integrity: int = (
		old_integrity
		- damage
	)

	if new_integrity < 0:
		new_integrity = 0

	part_data[
		"integrity"
	] = new_integrity

	body_parts[
		part_name
	] = part_data

	var actual_part_damage: int = (
		old_integrity
		- new_integrity
	)

	result[
		"part_damage"
	] = actual_part_damage

	var vitality_ratio: float = (
		_get_vitality_transfer_ratio(
			part_name
		)
	)

	var vitality_damage: int = roundi(
		actual_part_damage
		* vitality_ratio
	)

	result[
		"vitality_damage"
	] = take_vitality_damage(
		vitality_damage
	)

	result[
		"destroyed"
	] = (
		old_integrity > 0
		and new_integrity <= 0
	)

	return result


func apply_fracture(
	part_name: String
) -> void:
	if not body_parts.has(
		part_name
	):
		return

	status_manager.add_fracture(
		part_name
	)


func begin_activation() -> Dictionary:
	return status_manager.begin_activation()


func end_activation() -> Dictionary:
	return status_manager.end_activation()


func get_body_part_names() -> Array[String]:
	var result: Array[String] = []

	for part_name in body_parts.keys():
		result.append(
			str(
				part_name
			)
		)

	return result


func get_part_integrity(
	part_name: String
) -> int:
	if not body_parts.has(
		part_name
	):
		return 0

	return int(
		body_parts[
			part_name
		][
			"integrity"
		]
	)


func get_part_max_integrity(
	part_name: String
) -> int:
	if not body_parts.has(
		part_name
	):
		return 0

	return int(
		body_parts[
			part_name
		][
			"max_integrity"
		]
	)


func get_move_range() -> int:
	if enemy_data == null:
		return 0

	if _is_part_destroyed(
		"Gambe"
	):
		return 0

	if status_manager.is_immobilized():
		return 0

	var result: int = (
		enemy_data.move_range
	)

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
			HEAD_BROKEN_ATTACK_DAMAGE
		)

	if _is_part_destroyed(
		"Braccia"
	):
		result = mini(
			result,
			ARMS_BROKEN_ATTACK_DAMAGE
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


func _is_part_destroyed(
	part_name: String
) -> bool:
	if not body_parts.has(
		part_name
	):
		return false

	return (
		get_part_integrity(
			part_name
		)
		<= 0
	)


func _get_vitality_transfer_ratio(
	part_name: String
) -> float:
	match part_name:
		"Testa":
			return 1.0

		"Torso":
			return 0.8

		"Braccia":
			return 0.65

		"Gambe":
			return 0.6

		_:
			return 0.5
