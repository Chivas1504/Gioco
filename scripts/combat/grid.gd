extends Node2D


const GRID_SIZE := 9
const CELL_SIZE := 64

var hovered_cell: Vector2i = Vector2i(-1, -1)

var blocked_cells: Array[Vector2i] = [
	Vector2i(3, 2),
	Vector2i(3, 3),
	Vector2i(3, 4),
	Vector2i(6, 5),
	Vector2i(7, 5)
]

var occupied_cells: Array[Vector2i] = []
var reachable_cells: Array[Vector2i] = []

var astar := AStarGrid2D.new()


func _ready() -> void:
	_setup_astar()
	queue_redraw()


func _process(_delta: float) -> void:
	var mouse_local: Vector2 = to_local(get_global_mouse_position())
	var cell: Vector2i = local_to_cell(mouse_local)

	if is_cell_inside(cell):
		hovered_cell = cell
	else:
		hovered_cell = Vector2i(-1, -1)

	queue_redraw()


func _setup_astar() -> void:
	astar.region = Rect2i(0, 0, GRID_SIZE, GRID_SIZE)
	astar.cell_size = Vector2(CELL_SIZE, CELL_SIZE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()

	_refresh_astar_solids()


func _refresh_astar_solids() -> void:
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			astar.set_point_solid(Vector2i(x, y), false)

	for cell in blocked_cells:
		astar.set_point_solid(cell, true)

	for cell in occupied_cells:
		astar.set_point_solid(cell, true)


func set_occupied_cells(cells: Array[Vector2i]) -> void:
	occupied_cells = cells
	_refresh_astar_solids()
	queue_redraw()


func add_occupied_cell(cell: Vector2i) -> void:
	if cell not in occupied_cells:
		occupied_cells.append(cell)
		_refresh_astar_solids()
		queue_redraw()


func remove_occupied_cell(cell: Vector2i) -> void:
	if cell in occupied_cells:
		occupied_cells.erase(cell)
		_refresh_astar_solids()
		queue_redraw()


func find_path(
	from_cell: Vector2i,
	to_cell: Vector2i
) -> Array[Vector2i]:
	if not is_cell_walkable(to_cell):
		return []

	var from_was_occupied := from_cell in occupied_cells

	if from_was_occupied:
		astar.set_point_solid(from_cell, false)

	var raw_path: Array[Vector2i] = astar.get_id_path(
		from_cell,
		to_cell
	)

	if from_was_occupied:
		astar.set_point_solid(from_cell, true)

	if raw_path.is_empty():
		return []

	return raw_path


func calculate_reachable_cells(
	from_cell: Vector2i,
	max_distance: int
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			var target := Vector2i(x, y)

			if target == from_cell:
				result.append(target)
				continue

			if not is_cell_walkable(target):
				continue

			var path: Array[Vector2i] = find_path(
				from_cell,
				target
			)

			if path.is_empty():
				continue

			var distance := path.size() - 1

			if distance <= max_distance:
				result.append(target)

	return result


func set_reachable_cells(cells: Array[Vector2i]) -> void:
	reachable_cells = cells
	queue_redraw()


func clear_reachable_cells() -> void:
	reachable_cells.clear()
	queue_redraw()


func _draw() -> void:
	_draw_blocked_cells()
	_draw_occupied_cells()
	_draw_reachable_cells()
	_draw_grid()
	_draw_hovered_cell()


func _draw_blocked_cells() -> void:
	for cell in blocked_cells:
		var rect := _get_cell_rect(cell)

		draw_rect(
			rect,
			Color(0.30, 0.30, 0.30, 1.0),
			true
		)


func _draw_occupied_cells() -> void:
	for cell in occupied_cells:
		var rect := _get_cell_rect(cell)

		draw_rect(
			rect,
			Color(0.45, 0.10, 0.10, 0.35),
			true
		)


func _draw_reachable_cells() -> void:
	for cell in reachable_cells:
		var rect := _get_cell_rect(cell)

		draw_rect(
			rect,
			Color(0.25, 0.55, 1.0, 0.22),
			true
		)


func _draw_grid() -> void:
	for x in range(GRID_SIZE + 1):
		var x_pos: float = x * CELL_SIZE

		draw_line(
			Vector2(x_pos, 0),
			Vector2(x_pos, GRID_SIZE * CELL_SIZE),
			Color.WHITE,
			1.0
		)

	for y in range(GRID_SIZE + 1):
		var y_pos: float = y * CELL_SIZE

		draw_line(
			Vector2(0, y_pos),
			Vector2(GRID_SIZE * CELL_SIZE, y_pos),
			Color.WHITE,
			1.0
		)


func _draw_hovered_cell() -> void:
	if not is_cell_inside(hovered_cell):
		return

	var rect := _get_cell_rect(hovered_cell)

	if is_cell_walkable(hovered_cell):
		draw_rect(
			rect,
			Color(1.0, 1.0, 1.0, 0.20),
			true
		)
	else:
		draw_rect(
			rect,
			Color(1.0, 0.0, 0.0, 0.25),
			true
		)


func _get_cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(
		Vector2(
			cell.x * CELL_SIZE,
			cell.y * CELL_SIZE
		),
		Vector2(CELL_SIZE, CELL_SIZE)
	)


func cell_to_local(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * CELL_SIZE + CELL_SIZE / 2.0,
		cell.y * CELL_SIZE + CELL_SIZE / 2.0
	)


func local_to_cell(local_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(local_position.x / CELL_SIZE),
		floori(local_position.y / CELL_SIZE)
	)


func is_cell_inside(cell: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.x < GRID_SIZE
		and cell.y >= 0
		and cell.y < GRID_SIZE
	)


func is_cell_blocked(cell: Vector2i) -> bool:
	return cell in blocked_cells


func is_cell_occupied(cell: Vector2i) -> bool:
	return cell in occupied_cells


func is_cell_walkable(cell: Vector2i) -> bool:
	return (
		is_cell_inside(cell)
		and not is_cell_blocked(cell)
		and not is_cell_occupied(cell)
	)
