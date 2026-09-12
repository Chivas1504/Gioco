class_name Enemy
extends Node2D


const DEFAULT_MAX_VITALITY := 25
const DEFAULT_ATTACK_DAMAGE := 6
const VITALITY_TRANSFER_PERCENT := 100

const BODY_PART_HEAD := "Testa"
const BODY_PART_TORSO := "Torso"
const BODY_PART_ARMS := "Braccia"
const BODY_PART_LEGS := "Gambe"

const BODY_PARTS: Array[String] = [
	BODY_PART_HEAD,
	BODY_PART_TORSO,
	BODY_PART_ARMS,
	BODY_PART_LEGS
]


var max_vitality: int = DEFAULT_MAX_VITALITY
var vitality: int = DEFAULT_MAX_VITALITY
var attack_damage: int = DEFAULT_ATTACK_DAMAGE

var body_part_max_integrity: Dictionary[String, int] = {
	BODY_PART_HEAD: 8,
	BODY_PART_TORSO: 14,
	BODY_PART_ARMS: 10,
	BODY_PART_LEGS: 10
}

var body_part_integrity: Dictionary[String, int] = {}


func _ready() -> void:
	reset_enemy()


func reset_enemy() -> void:
	vitality = max_vitality
	body_part_integrity.clear()

	for body_part: String in BODY_PARTS:
		body_part_integrity[body_part] = body_part_max_integrity[body_part]

	visible = true


func get_body_parts() -> Array[String]:
	return BODY_PARTS.duplicate()


func get_default_target_part() -> String:
	return BODY_PART_TORSO


func get_attack_damage() -> int:
	return attack_damage


func is_dead() -> bool:
	return vitality <= 0


func get_body_part_integrity(body_part: String) -> int:
	var valid_body_part: String = _get_valid_body_part(body_part)
	return body_part_integrity[valid_body_part]


func get_body_part_max_integrity(body_part: String) -> int:
	var valid_body_part: String = _get_valid_body_part(body_part)
	return body_part_max_integrity[valid_body_part]


func apply_damage(amount: int, body_part: String) -> Dictionary:
	if amount <= 0 or is_dead():
		return {
			"body_part": _get_valid_body_part(body_part),
			"integrity_damage": 0,
			"vitality_damage": 0
		}

	var valid_body_part: String = _get_valid_body_part(body_part)
	var current_integrity: int = body_part_integrity[valid_body_part]
	var integrity_damage: int = mini(amount, current_integrity)

	body_part_integrity[valid_body_part] = current_integrity - integrity_damage

	var vitality_damage: int = _calculate_vitality_damage(amount)
	vitality -= vitality_damage

	if vitality < 0:
		vitality = 0

	return {
		"body_part": valid_body_part,
		"integrity_damage": integrity_damage,
		"vitality_damage": vitality_damage
	}


func apply_direct_vitality_damage(amount: int) -> int:
	if amount <= 0 or is_dead():
		return 0

	var vitality_damage: int = mini(amount, vitality)
	vitality -= vitality_damage

	if vitality < 0:
		vitality = 0

	return vitality_damage


func get_vitality_text() -> String:
	return (
		str(vitality)
		+ "/"
		+ str(max_vitality)
	)


func get_anatomy_text(selected_body_part: String = "") -> String:
	var text: String = ""

	for body_part: String in BODY_PARTS:
		if not text.is_empty():
			text += " | "

		var marker: String = ""

		if body_part == selected_body_part:
			marker = ">"

		text += (
			marker
			+ body_part
			+ " "
			+ str(body_part_integrity[body_part])
			+ "/"
			+ str(body_part_max_integrity[body_part])
		)

	return text


func _calculate_vitality_damage(amount: int) -> int:
	var transferred_damage: float = (
		float(amount)
		* float(VITALITY_TRANSFER_PERCENT)
		/ 100.0
	)

	return ceili(transferred_damage)


func _get_valid_body_part(body_part: String) -> String:
	if body_part_integrity.has(body_part):
		return body_part

	return BODY_PART_TORSO
