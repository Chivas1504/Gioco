extends Node2D


@onready var grid: Node2D = $Grid
@onready var player: Node2D = $Player
@onready var enemy: Node2D = $Enemy

@onready var hp_label: Label = $UI/HUD/CombatPanel/HPLabel
@onready var actions_label: Label = $UI/HUD/CombatPanel/ActionsLabel
@onready var state_label: Label = $UI/HUD/CombatPanel/StateLabel
@onready var enemy_hp_label: Label = $UI/HUD/CombatPanel/EnemyHPLabel


const MOVE_TIME := 0.12
const ENEMY_MOVE_TIME := 0.18

const COMBAT_MOVE_RANGE := 2
const PLAYER_MAX_ACTIONS := 2

const PLAYER_MAX_HP := 30

const ENEMY_MAX_HP := 25
const ENEMY_DAMAGE := 6


var player_cell: Vector2i = Vector2i(0, 0)
var enemy_cell: Vector2i = Vector2i(6, 4)

var player_hp: int = PLAYER_MAX_HP
var enemy_hp: int = ENEMY_MAX_HP

var current_path: Array[Vector2i] = []

var is_moving: bool = false
var enemy_is_moving: bool = false

var combat_mode: bool = false

var player_actions_remaining: int = PLAYER_MAX_ACTIONS

var player_is_dead: bool = false
var enemy_is_dead: bool = false

var mannaia_del_carnefice: CardData
var chiodo_del_giudizio: CardData
var maglio_della_pena: CardData
var bende_del_viandante: CardData
var catena_del_contrappasso: CardData
var spinta_dei_condannati: CardData


func _ready() -> void:
	_create_test_cards()

	player.position = grid.position + grid.cell_to_local(player_cell)
	enemy.position = grid.position + grid.cell_to_local(enemy_cell)

	var occupied: Array[Vector2i] = [
		enemy_cell
	]

	grid.set_occupied_cells(occupied)

	_update_ui()
	_update_combat_display()


func _create_test_cards() -> void:
	var mannaia_tags: Array[String] = [
		"Taglio",
		"Mischia"
	]

	mannaia_del_carnefice = CardData.new(
		"Mannaia del Carnefice",
		1,
		7,
		0,
		1,
		0,
		0,
		mannaia_tags
	)

	var chiodo_tags: Array[String] = [
		"Perforazione",
		"Distanza",
		"Mira"
	]

	chiodo_del_giudizio = CardData.new(
		"Chiodo del Giudizio",
		1,
		6,
		0,
		5,
		0,
		0,
		chiodo_tags
	)

	var maglio_tags: Array[String] = [
		"Impatto",
		"Mischia",
		"Pesante"
	]

	maglio_della_pena = CardData.new(
		"Maglio della Pena",
		2,
		10,
		0,
		1,
		0,
		0,
		maglio_tags
	)

	var bende_tags: Array[String] = [
		"Cura",
		"Supporto"
	]

	bende_del_viandante = CardData.new(
		"Bende del Viandante",
		1,
		0,
		6,
		0,
		0,
		0,
		bende_tags
	)

	var catena_tags: Array[String] = [
		"Impatto",
		"Distanza",
		"Controllo",
		"Tiro"
	]

	catena_del_contrappasso = CardData.new(
		"Catena del Contrappasso",
		1,
		4,
		0,
		3,
		1,
		0,
		catena_tags
	)

	var spinta_tags: Array[String] = [
		"Impatto",
		"Mischia",
		"Controllo",
		"Spinta"
	]

	spinta_dei_condannati = CardData.new(
		"Spinta dei Condannati",
		1,
		3,
		0,
		1,
		0,
		1,
		spinta_tags
	)


func _unhandled_input(event: InputEvent) -> void:
	if player_is_dead:
		return

	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_C:
				_toggle_combat_mode()
				return

			if event.keycode == KEY_1:
				_try_use_card(mannaia_del_carnefice)
				return

			if event.keycode == KEY_2:
				_try_use_card(chiodo_del_giudizio)
				return

			if event.keycode == KEY_3:
				_try_use_card(maglio_della_pena)
				return

			if event.keycode == KEY_4:
				_try_use_card(bende_del_viandante)
				return

			if event.keycode == KEY_5:
				_try_use_card(catena_del_contrappasso)
				return

			if event.keycode == KEY_6:
				_try_use_card(spinta_dei_condannati)
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


func _handle_grid_click(mouse_position: Vector2) -> void:
	if enemy_is_moving:
		return

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
			_finish_player_action(1)
		else:
			_update_combat_display()

		return

	is_moving = true

	var next_cell: Vector2i = current_path.pop_front()

	var target_position: Vector2 = (
		grid.position
		+ grid.cell_to_local(next_cell)
	)

	var tween: Tween = create_tween()

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


func _try_use_card(card: CardData) -> void:
	if not combat_mode:
		return

	if player_is_dead:
		return

	if enemy_is_dead:
		return

	if is_moving or enemy_is_moving:
		return

	if player_actions_remaining < card.action_cost:
		print(
			card.card_name,
			": Azioni insufficienti."
		)
		return

	if card.healing > 0:
		_try_use_healing_card(card)
		return

	if card.damage > 0:
		_try_use_attack_card(card)
		return


func _try_use_attack_card(card: CardData) -> void:
	var distance: int = _grid_distance(
		player_cell,
		enemy_cell
	)

	if distance > card.attack_range:
		print(
			card.card_name,
			": bersaglio fuori portata."
		)
		return

	_use_attack_card(card)


func _try_use_healing_card(card: CardData) -> void:
	if player_hp >= PLAYER_MAX_HP:
		print(
			card.card_name,
			": HP già al massimo."
		)
		return

	_use_healing_card(card)


func _use_attack_card(card: CardData) -> void:
	enemy_hp -= card.damage

	if enemy_hp < 0:
		enemy_hp = 0

	print(
		"Usata carta: ",
		card.card_name
	)

	print(
		"Danno inflitto: ",
		card.damage
	)

	if enemy_hp <= 0:
		_update_ui()
		_enemy_died()
		return

	if card.pull_distance > 0:
		_pull_enemy(card.pull_distance)

	if card.push_distance > 0:
		_push_enemy(card.push_distance)

	_update_ui()

	_finish_player_action(card.action_cost)


func _pull_enemy(pull_distance: int) -> void:
	for step in range(pull_distance):
		grid.remove_occupied_cell(enemy_cell)

		var path: Array[Vector2i] = grid.find_path(
			enemy_cell,
			player_cell
		)

		grid.add_occupied_cell(enemy_cell)

		if path.size() <= 1:
			return

		var next_cell: Vector2i = path[1]

		if next_cell == player_cell:
			print("Il nemico non può essere trascinato oltre.")
			return

		if not grid.is_cell_walkable(next_cell):
			print("Il tiro della catena è bloccato.")
			return

		grid.remove_occupied_cell(enemy_cell)

		enemy_cell = next_cell

		grid.add_occupied_cell(enemy_cell)

		enemy.position = (
			grid.position
			+ grid.cell_to_local(enemy_cell)
		)

		print(
			"Nemico trascinato nella cella ",
			enemy_cell
		)


func _push_enemy(push_distance: int) -> void:
	for step in range(push_distance):
		var direction: Vector2i = enemy_cell - player_cell

		if direction.x != 0:
			direction.x = signi(direction.x)

		if direction.y != 0:
			direction.y = signi(direction.y)

		var next_cell: Vector2i = enemy_cell + direction

		if not grid.is_cell_inside(next_cell):
			print("Il nemico non può essere spinto fuori dalla griglia.")
			return

		if next_cell == player_cell:
			return

		grid.remove_occupied_cell(enemy_cell)

		var can_move: bool = grid.is_cell_walkable(next_cell)

		grid.add_occupied_cell(enemy_cell)

		if not can_move:
			print("La spinta è bloccata.")
			return

		grid.remove_occupied_cell(enemy_cell)

		enemy_cell = next_cell

		grid.add_occupied_cell(enemy_cell)

		enemy.position = (
			grid.position
			+ grid.cell_to_local(enemy_cell)
		)

		print(
			"Nemico spinto nella cella ",
			enemy_cell
		)


func _use_healing_card(card: CardData) -> void:
	var old_hp: int = player_hp

	player_hp += card.healing

	if player_hp > PLAYER_MAX_HP:
		player_hp = PLAYER_MAX_HP

	var healed_amount: int = player_hp - old_hp

	print(
		"Usata carta: ",
		card.card_name
	)

	print(
		"HP recuperati: ",
		healed_amount
	)

	_update_ui()

	_finish_player_action(card.action_cost)


func _enemy_died() -> void:
	enemy_is_dead = true

	grid.remove_occupied_cell(enemy_cell)

	enemy.visible = false
	combat_mode = false

	grid.clear_reachable_cells()

	print("NEMICO UCCISO")
	print("COMBATTIMENTO TERMINATO")

	_update_ui()


func _finish_player_action(action_cost: int) -> void:
	player_actions_remaining -= action_cost

	if player_actions_remaining < 0:
		player_actions_remaining = 0

	_update_ui()

	if player_actions_remaining <= 0:
		grid.clear_reachable_cells()
		_start_enemy_turn()
	else:
		_update_combat_display()


func _start_enemy_turn() -> void:
	if enemy_is_dead:
		return

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

	var tween: Tween = create_tween()

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
	if player_is_dead:
		return

	if enemy_is_dead:
		return

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


func _grid_distance(
	first_cell: Vector2i,
	second_cell: Vector2i
) -> int:
	var difference: Vector2i = first_cell - second_cell

	var distance_x: int = absi(difference.x)
	var distance_y: int = absi(difference.y)

	return distance_x + distance_y


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

	if enemy_is_dead:
		enemy_hp_label.text = "Nemico: MORTO"
	else:
		enemy_hp_label.text = (
			"Nemico: "
			+ str(enemy_hp)
			+ "/"
			+ str(ENEMY_MAX_HP)
			+ " HP"
		)

	if player_is_dead:
		state_label.text = "MORTO"

	elif enemy_is_dead:
		state_label.text = "COMBATTIMENTO TERMINATO"

	elif enemy_is_moving:
		state_label.text = "TURNO NEMICO"

	elif combat_mode:
		state_label.text = "TURNO GIOCATORE"

	else:
		state_label.text = "ESPLORAZIONE"
