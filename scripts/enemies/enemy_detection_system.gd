class_name EnemyDetectionSystem
extends RefCounted


static func find_detecting_enemy(
	player_position: Vector2,
	enemies: Array[EnemyUnit],
	detection_range: float
) -> EnemyUnit:
	for enemy_unit in enemies:
		if enemy_unit == null:
			continue

		if enemy_unit.is_dead():
			continue

		var distance_to_player: float = (
			enemy_unit.position.distance_to(
				player_position
			)
		)

		if distance_to_player <= detection_range:
			return enemy_unit

	return null
