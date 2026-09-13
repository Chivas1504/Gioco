class_name CombatParticipantSystem
extends RefCounted


static func build_combat_group(
	trigger_enemy: EnemyUnit,
	all_enemies: Array[EnemyUnit],
	enemy_combat_groups: Dictionary
) -> Array[EnemyUnit]:
	var result: Array[EnemyUnit] = []

	if trigger_enemy == null:
		return result

	if trigger_enemy.is_dead():
		return result

	if not enemy_combat_groups.has(
		trigger_enemy
	):
		result.append(
			trigger_enemy
		)

		return result

	var trigger_group_id: String = str(
		enemy_combat_groups[
			trigger_enemy
		]
	)

	if trigger_group_id.is_empty():
		result.append(
			trigger_enemy
		)

		return result

	for enemy_unit in all_enemies:
		if enemy_unit == null:
			continue

		if enemy_unit.is_dead():
			continue

		if not enemy_combat_groups.has(
			enemy_unit
		):
			continue

		var enemy_group_id: String = str(
			enemy_combat_groups[
				enemy_unit
			]
		)

		if enemy_group_id != trigger_group_id:
			continue

		result.append(
			enemy_unit
		)

	return result
