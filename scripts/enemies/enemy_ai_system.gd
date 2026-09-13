class_name EnemyAISystem
extends RefCounted


const ACTION_NONE := "none"
const ACTION_MELEE := "melee"
const ACTION_SPECIAL := "special"


static func choose_action(
	enemy_unit: EnemyUnit,
	can_attack_target: bool = true
) -> Dictionary:
	if enemy_unit == null:
		return _none()

	if enemy_unit.is_dead():
		return _none()

	if not can_attack_target:
		return _none()

	var special_action: Dictionary = (
		EnemyAbilitySystem.get_special_action(
			enemy_unit
		)
	)

	if (
		special_action.get(
			"type",
			EnemyAbilitySystem.ACTION_NONE
		)
		!= EnemyAbilitySystem.ACTION_NONE
	):
		return {
			"type": ACTION_SPECIAL,
			"special_action": special_action
		}

	if enemy_unit.get_attack_damage() > 0:
		return {
			"type": ACTION_MELEE
		}

	return _none()


static func _none() -> Dictionary:
	return {
		"type": ACTION_NONE
	}
