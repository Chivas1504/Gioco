extends Node2D


@onready var grid: Node2D = $Grid
@onready var player: Node2D = $Player
@onready var enemy: Node2D = $Enemy

@onready var hp_label: Label = $UI/HUD/CombatPanel/HPLabel
@onready var actions_label: Label = $UI/HUD/CombatPanel/ActionsLabel
@onready var state_label: Label = $UI/HUD/CombatPanel/StateLabel


const MOVE_TIME := 0.12
const ENEMY_MOVE_TIME := 0.18

const COMBAT_MOVE_RANGE := 2
const PLAYER_MAX_ACTIONS := 2

const PLAYER_MAX_HP := 30
const ENEMY_DAMAGE := 6


var player_cell: Vector2i = Vector2i(0, 0)
var enemy_cell: Vector2i = Vector2i(6, 4)

var player_hp: int = PLAYER_MAX_HP

var current_path: Array[Vector2i] = []

var is_moving: bool = false
var enemy_is_moving: bool = false

var combat_mode: bool = false
var player_actions_remaining: int = PLAYER_MAX_ACTIONS

var player_is_dead: bool = false


func _ready() -> void:
	player.position = (
		grid.position
		+ grid.cell_to_local(player_cell)
	)

	enemy.position = (
		grid.position
		+ grid.cell_to_local(enemy_cell)
	)

	var occupied: Array[Vector2i] = [
		enemy_cell
	]

	grid.set_occupied_cells(occupied)

	_update_ui()
	_update_combat_display()


func _unhandled_input(event: InputEvent) -> void:
	if player_is_dead:
		return

	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_C:
				_toggle_combat_mode()
				return

	if is_moving or enemy_is_moving:
		return

	if combat_mode and player_actions_remaining <= 0:
		return

	if event is InputEventMouseButton:
		if (
			event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed
		):
			_handle_grid_click(event.position)


func _handle_grid_click(
	mouse_position: Vector2
) -> void:
	var mouse_local: Vector2 = grid.to_local(
		mouse_position
	)

	var clicked_cell: Vector2i = (
		grid.local_to_cell(mouse_local)
	)

	if not grid.is_cell_walkable(clicked_cell):
		return

	var path: Array[Vector2i] = grid.find_path(
		player_cell,
		clicked_cell
	)

	if path.size() <= 1:
		return

	if combat_mode:
		var distance: int = path.size() - 1

		if distance > COMBAT_MOVE_RANGE:
			return

	current_path = path
	current_path.remove_at(0)

	_move_player_along_path()


func _move_player_along_path() -> void:
	if current_path.is_empty():
		is_moving = false

		if combat_mode:
			_finish_player_action()
		else:
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
			_move_player_along_path()
	)


func _finish_player_action() -> void:
	player_actions_remaining -= 1

	_update_ui()

	if player_actions_remaining <= 0:
		grid.clear_reachable_cells()

		_start_enemy_turn()
	else:
		_update_combat_display()


func _start_enemy_turn() -> void:
	enemy_is_moving = true

	_update_ui()

	grid.remove_occupied_cell(enemy_cell)

	var path: Array[Vector2i] = grid.find_path(
		enemy_cell,
		player_cell
	)

	grid.add_occupied_cell(enemy_cell)

	if path.size() <= 1:
		_finish_enemy_turn()
		return

	if path.size() == 2:
		_enemy_attack()
		return

	var next_cell: Vector2i = path[1]

	grid.remove_occupied_cell(enemy_cell)

	enemy_cell = next_cell

	grid.add_occupied_cell(enemy_cell)

	var target_position: Vector2 = (
		grid.position
		+ grid.cell_to_local(enemy_cell)
	)

	var tween := create_tween()

	tween.tween_property(
		enemy,
		"position",
		target_position,
		ENEMY_MOVE_TIME
	)

	tween.finished.connect(
		func() -> void:
			_finish_enemy_turn()
	)


func _enemy_attack() -> void:
	player_hp -= ENEMY_DAMAGE

	if player_hp < 0:
		player_hp = 0

	_update_ui()

	if player_hp <= 0:
		_player_died()
		return

	_finish_enemy_turn()


func _player_died() -> void:
	player_is_dead = true
	combat_mode = false
	enemy_is_moving = false

	grid.clear_reachable_cells()

	_update_ui()


func _finish_enemy_turn() -> void:
	enemy_is_moving = false

	if player_is_dead:
		return

	player_actions_remaining = PLAYER_MAX_ACTIONS

	_update_ui()
	_update_combat_display()


func _toggle_combat_mode() -> void:
	if is_moving or enemy_is_moving:
		return

	combat_mode = not combat_mode

	if combat_mode:
		player_actions_remaining = PLAYER_MAX_ACTIONS

	_update_ui()
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


func _update_ui() -> void:
	hp_label.text = (
		"HP: "
		+ str(player_hp)
		+ "/"
		+ str(PLAYER_MAX_HP)
	)

	actions_label.text = (
		"Azioni: "
		+ str(player_actions_remaining)
		+ "/"
		+ str(PLAYER_MAX_ACTIONS)
	)

	if player_is_dead:
		state_label.text = "MORTO"
	elif enemy_is_moving:
		state_label.text = "TURNO NEMICO"
	elif combat_mode:
		state_label.text = "TURNO GIOCATORE"
	else:
		state_label.text = "ESPLORAZIONE"
