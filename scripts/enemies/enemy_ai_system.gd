class_name EnemyAISystem
extends RefCounted


const ACTION_NONE := "none"
const ACTION_MELEE := "melee"
const ACTION_SPECIAL := "special"
const ACTION_MOVE := "move"


static func choose_action(
	enemy_unit: EnemyUnit,
	enemy_cell: Vector2i,
	target_cell: Vector2i,
	grid: Node,
	can_attack_target: bool = true
) -> Dictionary:
	if enemy_unit == null:
		return _none()

	if enemy_unit.is_dead():
		return _none()

	if target_cell == Vector2i(-1, -1):
		return _none()

	var distance_to_target: int = (
		_grid_distance(
			enemy_cell,
			target_cell
		)
	)

	if (
		can_attack_target
		and distance_to_target == 1
	):
		return {
			"type": ACTION_MELEE,
			"target_cell": target_cell
		}

	if can_attack_target:
		var special_action: Dictionary = (
			EnemyAbilitySystem.get_special_action(
				enemy_unit,
				enemy_cell,
				target_cell,
				grid
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
				"target_cell": target_cell,
				"special_action": special_action
			}

	if enemy_unit.get_move_range() > 0:
		return {
			"type": ACTION_MOVE,
			"target_cell": target_cell
		}

	return _none()


static func _grid_distance(
	first_cell: Vector2i,
	second_cell: Vector2i
) -> int:
	var difference: Vector2i = (
		first_cell - second_cell
	)

	return (
		absi(difference.x)
		+ absi(difference.y)
	)


static func _none() -> Dictionary:
	return {
		"type": ACTION_NONE
	}
