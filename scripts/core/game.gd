extends Node2D


@onready var grid: Node2D = $Grid
@onready var player: Node2D = $Player

var player_cell: Vector2i = Vector2i(0, 0)


func _ready() -> void:
	player.position = grid.position + grid.cell_to_local(player_cell)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_local: Vector2 = grid.to_local(event.position)
			var clicked_cell: Vector2i = grid.local_to_cell(mouse_local)

			if grid.is_cell_walkable(clicked_cell):
				player_cell = clicked_cell
				player.position = grid.position + grid.cell_to_local(player_cell)
