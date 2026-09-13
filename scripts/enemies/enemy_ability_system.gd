class_name EnemyAbilitySystem
extends RefCounted


const ACTION_NONE := "none"
const ACTION_CHAIN_PULL := "chain_pull"
const ACTION_RANGED_ATTACK := "ranged_attack"


static func get_special_action(
	enemy_unit: EnemyUnit
) -> Dictionary:
	if enemy_unit == null:
		return _no_action()

	if not enemy_unit.can_use_special_ability():
		return _no_action()

	var ability: String = (
		enemy_unit.get_special_ability()
	)

	match ability:
		ACTION_CHAIN_PULL:
			return {
				"type": ACTION_CHAIN_PULL,
				"damage": maxi(
					enemy_unit.get_attack_damage() - 1,
					0
				),
				"status": StatusManager.IMMOBILIZED,
				"duration": 1
			}

		ACTION_RANGED_ATTACK:
			return {
				"type": ACTION_RANGED_ATTACK,
				"damage": enemy_unit.get_attack_damage()
			}

		_:
			return _no_action()


static func _no_action() -> Dictionary:
	return {
		"type": ACTION_NONE
	}
