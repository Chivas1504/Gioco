extends Node2D


@onready var grid: Node2D = $Grid
@onready var player: Node2D = $Player

var player_cell: Vector2i = Vector2i(0, 0)

var current_path: Array[Vector2i] = []
var is_moving: bool = false

const MOVE_TIME := 0.12


func _ready() -> void:
	player.position = grid.position + grid.cell_to_local(player_cell)


func _unhandled_input(event: InputEvent) -> void:
	if is_moving:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_local: Vector2 = grid.to_local(event.position)
			var clicked_cell: Vector2i = grid.local_to_cell(mouse_local)

			if grid.is_cell_walkable(clicked_cell):
				current_path = grid.find_path(player_cell, clicked_cell)

				if current_path.size() > 1:
					current_path.remove_at(0)
					_move_along_path()


func _move_along_path() -> void:
	if current_path.is_empty():
		is_moving = false
		return

	is_moving = true

	var next_cell: Vector2i = current_path.pop_front()
	var target_position: Vector2 = grid.position + grid.cell_to_local(next_cell)

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
