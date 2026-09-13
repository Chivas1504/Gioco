class_name EnemyAbilitySystem
extends RefCounted


const ACTION_NONE := "none"
const ACTION_CHAIN_PULL := "chain_pull"
const ACTION_RANGED_ATTACK := "ranged_attack"


static func get_special_action(
	enemy_unit: EnemyUnit,
	enemy_cell: Vector2i,
	player_cell: Vector2i,
	grid: Node
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
			return _get_chain_pull_action(
				enemy_unit,
				enemy_cell,
				player_cell,
				grid
			)

		ACTION_RANGED_ATTACK:
			return _get_ranged_attack_action(
				enemy_unit,
				enemy_cell,
				player_cell,
				grid
			)

		_:
			return _no_action()


static func _get_chain_pull_action(
	enemy_unit: EnemyUnit,
	enemy_cell: Vector2i,
	player_cell: Vector2i,
	grid: Node
) -> Dictionary:
	var distance: int = (
		_grid_distance(
			enemy_cell,
			player_cell
		)
	)

	if distance < 2:
		return _no_action()

	if distance > enemy_unit.get_special_range():
		return _no_action()

	if not _has_clear_straight_line(
		enemy_cell,
		player_cell,
		grid
	):
		return _no_action()

	var direction := Vector2i(
		signi(
			enemy_cell.x - player_cell.x
		),
		signi(
			enemy_cell.y - player_cell.y
		)
	)

	var final_cell: Vector2i = (
		player_cell
	)

	var pull_distance: int = (
		enemy_unit.get_special_pull_distance()
	)

	for _step in range(
		pull_distance
	):
		var next_cell: Vector2i = (
			final_cell + direction
		)

		if next_cell == enemy_cell:
			break

		if not grid.is_cell_inside(
			next_cell
		):
			break

		if not grid.is_cell_walkable(
			next_cell
		):
			break

		final_cell = next_cell

	return {
		"type": ACTION_CHAIN_PULL,
		"target_cell": final_cell
	}


static func _get_ranged_attack_action(
	enemy_unit: EnemyUnit,
	enemy_cell: Vector2i,
	player_cell: Vector2i,
	grid: Node
) -> Dictionary:
	var distance: int = (
		_grid_distance(
			enemy_cell,
			player_cell
		)
	)

	if distance < 2:
		return _no_action()

	if distance > enemy_unit.get_special_range():
		return _no_action()

	if not _has_clear_straight_line(
		enemy_cell,
		player_cell,
		grid
	):
		return _no_action()

	return {
		"type": ACTION_RANGED_ATTACK,
		"damage": enemy_unit.get_attack_damage()
	}


static func _has_clear_straight_line(
	from_cell: Vector2i,
	to_cell: Vector2i,
	grid: Node
) -> bool:
	if (
		from_cell.x != to_cell.x
		and from_cell.y != to_cell.y
	):
		return false

	var direction := Vector2i(
		signi(
			to_cell.x - from_cell.x
		),
		signi(
			to_cell.y - from_cell.y
		)
	)

	var current_cell: Vector2i = (
		from_cell + direction
	)

	while current_cell != to_cell:
		if grid.is_cell_blocked(
			current_cell
		):
			return false

		if grid.is_cell_occupied(
			current_cell
		):
			return false

		current_cell += direction

	return true


static func _grid_distance(
	first_cell: Vector2i,
	second_cell: Vector2i
) -> int:
	var difference: Vector2i = (
		first_cell - second_cell
	)

	return (
		absi(
			difference.x
		)
		+ absi(
			difference.y
		)
	)


static func _no_action() -> Dictionary:
	return {
		"type": ACTION_NONE
	}
