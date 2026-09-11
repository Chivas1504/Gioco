extends Node2D


@onready var grid: Node2D = $Grid
@onready var player: Node2D = $Player

const MOVE_TIME := 0.12
const COMBAT_MOVE_RANGE := 2

var player_cell: Vector2i = Vector2i(0, 0)

var current_path: Array[Vector2i] = []
var is_moving: bool = false
var combat_mode: bool = false


func _ready() -> void:
	player.position = grid.position + grid.cell_to_local(player_cell)
	_update_combat_display()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_C:
				_toggle_combat_mode()
				return

	if is_moving:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_grid_click(event.position)


func _handle_grid_click(mouse_position: Vector2) -> void:
	var mouse_local: Vector2 = grid.to_local(mouse_position)
	var clicked_cell: Vector2i = grid.local_to_cell(mouse_local)

	if not grid.is_cell_walkable(clicked_cell):
		return

	var path: Array[Vector2i] = grid.find_path(
		player_cell,
		clicked_cell
	)

	if path.size() <= 1:
		return

	if combat_mode:
		var distance := path.size() - 1

		if distance > COMBAT_MOVE_RANGE:
			return

	current_path = path
	current_path.remove_at(0)

	_move_along_path()


func _move_along_path() -> void:
	if current_path.is_empty():
		is_moving = false
		_update_combat_display()
		return

	is_moving = true

	var next_cell: Vector2i = current_path.pop_front()

	var target_position: Vector2 = (
		grid.position
		+ grid.cell_to_local(next_cell)
	)

	var tween := create_tween()

	tween.tween_property(
		player,
		"position",
		target_position,
		MOVE_TIME
	)

	tween.finished.connect(
		func() -> void:
			player_cell = next_cell
			_move_along_path()
	)


func _toggle_combat_mode() -> void:
	if is_moving:
		return

	combat_mode = not combat_mode

	if combat_mode:
		print("COMBATTIMENTO ATTIVO")
	else:
		print("ESPLORAZIONE LIBERA")

	_update_combat_display()


func _update_combat_display() -> void:
	if combat_mode:
		var reachable: Array[Vector2i] = (
			grid.calculate_reachable_cells(
				player_cell,
				COMBAT_MOVE_RANGE
			)
		)

		grid.set_reachable_cells(reachable)
	else:
		grid.clear_reachable_cells()
