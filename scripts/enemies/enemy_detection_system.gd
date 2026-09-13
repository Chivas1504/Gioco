class_name EnemyDetectionSystem
extends RefCounted


static func find_detecting_enemy(
	player_position: Vector2,
	enemies: Array[EnemyUnit],
	noise_system: NoiseSystem,
	world_2d: World2D
) -> EnemyUnit:
	for enemy_unit in enemies:
		if enemy_unit == null:
			continue

		if enemy_unit.is_dead():
			continue

		if _enemy_detects_player(
			enemy_unit,
			player_position,
			noise_system,
			world_2d
		):
			return enemy_unit

	return null


static func _enemy_detects_player(
	enemy_unit: EnemyUnit,
	player_position: Vector2,
	noise_system: NoiseSystem,
	world_2d: World2D
) -> bool:
	var detection_mode: String = (
		enemy_unit.get_detection_mode()
	)

	match detection_mode:
		EnemyData.PERCEPTION_SIGHT:
			return _detect_by_sight(
				enemy_unit,
				player_position,
				world_2d
			)

		EnemyData.PERCEPTION_NOISE:
			return _detect_by_noise(
				enemy_unit,
				noise_system
			)

		_:
			return false


static func _detect_by_sight(
	enemy_unit: EnemyUnit,
	player_position: Vector2,
	world_2d: World2D
) -> bool:
	var distance_to_player: float = (
		enemy_unit.global_position.distance_to(
			player_position
		)
	)

	if (
		distance_to_player
		> enemy_unit.get_detection_range()
	):
		return false

	if world_2d == null:
		return true

	var space_state: PhysicsDirectSpaceState2D = (
		world_2d.direct_space_state
	)

	var query := PhysicsRayQueryParameters2D.create(
		enemy_unit.global_position,
		player_position
	)

	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result: Dictionary = (
		space_state.intersect_ray(
			query
		)
	)

	if result.is_empty():
		return true

	var collider = result.get(
		"collider"
	)

	if collider == null:
		return true

	if collider is CharacterBody2D:
		return true

	return false


static func _detect_by_noise(
	enemy_unit: EnemyUnit,
	noise_system: NoiseSystem
) -> bool:
	if noise_system == null:
		return false

	if not noise_system.has_active_world_noise():
		return false

	var noise_position: Vector2 = (
		noise_system.get_last_world_noise_position()
	)

	var distance_to_noise: float = (
		enemy_unit.global_position.distance_to(
			noise_position
		)
	)

	return (
		distance_to_noise
		<= enemy_unit.get_detection_range()
	)
