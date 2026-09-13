class_name CombatParticipantSystem
extends RefCounted


static func build_combat_group(
	trigger_enemy: EnemyUnit,
	all_enemies: Array[EnemyUnit],
	join_range: float
) -> Array[EnemyUnit]:
	var result: Array[EnemyUnit] = []

	if trigger_enemy == null:
		return result

	if trigger_enemy.is_dead():
		return result

	result.append(
		trigger_enemy
	)

	var index: int = 0

	while index < result.size():
		var source_enemy: EnemyUnit = result[index]

		for candidate in all_enemies:
			if candidate == null:
				continue

			if candidate.is_dead():
				continue

			if candidate in result:
				continue

			var distance: float = (
				source_enemy.global_position.distance_to(
					candidate.global_position
				)
			)

			if distance <= join_range:
				result.append(
					candidate
				)

		index += 1

	return result
