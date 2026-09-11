extends Node2D


const GRID_SIZE := 10
const CELL_SIZE := 64

var hovered_cell := Vector2i(-1, -1)


func _ready() -> void:
	queue_redraw()


func _process(_delta: float) -> void:
	var mouse_local := to_local(get_global_mouse_position())
	var cell := local_to_cell(mouse_local)

	if is_cell_inside(cell):
		hovered_cell = cell
	else:
		hovered_cell = Vector2i(-1, -1)

	queue_redraw()


func _draw() -> void:
	for x in range(GRID_SIZE + 1):
		var x_pos := x * CELL_SIZE
		draw_line(
			Vector2(x_pos, 0),
			Vector2(x_pos, GRID_SIZE * CELL_SIZE),
			Color.WHITE,
			1.0
		)

	for y in range(GRID_SIZE + 1):
		var y_pos := y * CELL_SIZE
		draw_line(
			Vector2(0, y_pos),
			Vector2(GRID_SIZE * CELL_SIZE, y_pos),
			Color.WHITE,
			1.0
		)

	if is_cell_inside(hovered_cell):
		var rect := Rect2(
			Vector2(
				hovered_cell.x * CELL_SIZE,
				hovered_cell.y * CELL_SIZE
			),
			Vector2(CELL_SIZE, CELL_SIZE)
		)

		draw_rect(
			rect,
			Color(1.0, 1.0, 1.0, 0.20),
			true
		)


func cell_to_local(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * CELL_SIZE + CELL_SIZE / 2.0,
		cell.y * CELL_SIZE + CELL_SIZE / 2.0
	)


func local_to_cell(local_position: Vector2) -> Vector2i:
	return Vector2i(
		floor(local_position.x / CELL_SIZE),
		floor(local_position.y / CELL_SIZE)
	)


func is_cell_inside(cell: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.x < GRID_SIZE
		and cell.y >= 0
		and cell.y < GRID_SIZE
	)
