class_name EnemyUnit
extends Node2D


const RADIUS := 20.0
const MAX_HP := 25

const BASE_ATTACK_DAMAGE := 6
const HEAD_BROKEN_ATTACK_DAMAGE := 4
const ARMS_BROKEN_ATTACK_DAMAGE := 3

const TORSO_DAMAGE_MULTIPLIER := 1.25

const BODY_PART_ORDER: Array[String] = [
	"Testa",
	"Torso",
	"Braccia",
	"Gambe"
]


var hp: int = MAX_HP


var body_parts: Dictionary = {
	"Testa": {
		"max_integrity": 10,
		"integrity": 10,
		"vitality_transfer": 1.0
	},
	"Torso": {
		"max_integrity": 18,
		"integrity": 18,
		"vitality_transfer": 0.80
	},
	"Braccia": {
		"max_integrity": 12,
		"integrity": 12,
		"vitality_transfer": 0.65
	},
	"Gambe": {
		"max_integrity": 14,
		"integrity": 14,
		"vitality_transfer": 0.60
	}
}


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(
		Vector2.ZERO,
		RADIUS,
		Color(0.85, 0.15, 0.15)
	)


func take_vitality_damage(
	amount: int,
	apply_torso_bonus: bool = true
) -> int:
	if amount <= 0:
		return 0

	var final_damage: int = amount

	if (
		apply_torso_bonus
		and is_part_destroyed("Torso")
	):
		final_damage = roundi(
			final_damage
			* TORSO_DAMAGE_MULTIPLIER
		)

	var old_hp: int = hp

	hp -= final_damage

	if hp < 0:
		hp = 0

	return old_hp - hp


func take_part_damage(
	part_name: String,
	amount: int
) -> Dictionary:
	var result: Dictionary = {
		"part_damage": 0,
		"vitality_damage": 0,
		"destroyed": false
	}

	if amount <= 0:
		return result

	if not body_parts.has(part_name):
		return result

	# Serve per evitare che il colpo che distrugge
	# il Torso riceva già il bonus del +25%.
	var torso_was_destroyed: bool = (
		is_part_destroyed("Torso")
	)

	var part: Dictionary = body_parts[part_name]

	var old_integrity: int = int(
		part["integrity"]
	)

	var new_integrity: int = (
		old_integrity - amount
	)

	if new_integrity < 0:
		new_integrity = 0

	part["integrity"] = new_integrity
	body_parts[part_name] = part

	var actual_part_damage: int = (
		old_integrity - new_integrity
	)

	var transfer: float = float(
		part["vitality_transfer"]
	)

	var requested_vitality_damage: int = roundi(
		actual_part_damage * transfer
	)

	var actual_vitality_damage: int = (
		take_vitality_damage(
			requested_vitality_damage,
			torso_was_destroyed
		)
	)

	result["part_damage"] = actual_part_damage
	result["vitality_damage"] = actual_vitality_damage
	result["destroyed"] = new_integrity <= 0

	return result


func get_hp() -> int:
	return hp


func get_max_hp() -> int:
	return MAX_HP


func is_dead() -> bool:
	return hp <= 0


func get_body_part_names() -> Array[String]:
	var result: Array[String] = []

	for part_name in BODY_PART_ORDER:
		result.append(part_name)

	return result


func get_part_integrity(
	part_name: String
) -> int:
	if not body_parts.has(part_name):
		return 0

	var part: Dictionary = body_parts[part_name]

	return int(
		part["integrity"]
	)


func get_part_max_integrity(
	part_name: String
) -> int:
	if not body_parts.has(part_name):
		return 0

	var part: Dictionary = body_parts[part_name]

	return int(
		part["max_integrity"]
	)


func is_part_destroyed(
	part_name: String
) -> bool:
	return (
		get_part_integrity(part_name)
		<= 0
	)


func can_move() -> bool:
	return not is_part_destroyed("Gambe")


func get_attack_damage() -> int:
	var damage: int = BASE_ATTACK_DAMAGE

	if is_part_destroyed("Testa"):
		damage = HEAD_BROKEN_ATTACK_DAMAGE

	if is_part_destroyed("Braccia"):
		damage = ARMS_BROKEN_ATTACK_DAMAGE

	return damage
