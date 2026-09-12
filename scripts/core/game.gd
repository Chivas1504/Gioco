extends Node2D


@onready var grid: Node2D = $Grid
@onready var player: Node2D = $Player
@onready var enemy: EnemyUnit = $Enemy

@onready var hp_label: Label = $UI/HUD/CombatPanel/HPLabel
@onready var actions_label: Label = $UI/HUD/CombatPanel/ActionsLabel
@onready var state_label: Label = $UI/HUD/CombatPanel/StateLabel
@onready var enemy_hp_label: Label = $UI/HUD/CombatPanel/EnemyHPLabel
@onready var target_part_label: Label = $UI/HUD/CombatPanel/TargetPartLabel

@onready var player_status_label: Label = (
	$UI/HUD/CombatPanel/PlayerStatusLabel
)

@onready var enemy_status_label: Label = (
	$UI/HUD/CombatPanel/EnemyStatusLabel
)

@onready var card_bar = (
	$UI/HUD/CardBar
)


const MOVE_TIME := 0.12
const ENEMY_MOVE_TIME := 0.18

const COMBAT_MOVE_RANGE := 2
const PLAYER_MAX_ACTIONS := 2

const PLAYER_MAX_HP := 30
const COLLISION_DAMAGE := 2


var player_cell: Vector2i = Vector2i(0, 0)
var enemy_cell: Vector2i = Vector2i(6, 4)

var player_hp: int = PLAYER_MAX_HP

var player_statuses: StatusManager = (
	StatusManager.new()
)

var current_path: Array[Vector2i] = []

var is_moving: bool = false
var enemy_is_moving: bool = false
var combat_mode: bool = false

var player_actions_remaining: int = (
	PLAYER_MAX_ACTIONS
)

var player_is_dead: bool = false

var selected_body_part_index: int = 0


var mannaia_del_carnefice: CardData
var chiodo_del_giudizio: CardData
var maglio_della_pena: CardData
var bende_del_viandante: CardData
var catena_del_contrappasso: CardData
var spinta_dei_condannati: CardData

var active_cards: Array[CardData] = []


func _ready() -> void:
	_load_test_cards()
	_load_test_enemy()
	_setup_card_bar()

	player.position = (
		grid.position
		+ grid.cell_to_local(
			player_cell
		)
	)

	enemy.position = (
		grid.position
		+ grid.cell_to_local(
			enemy_cell
		)
	)

	var occupied: Array[Vector2i] = [
		enemy_cell
	]

	grid.set_occupied_cells(
		occupied
	)

	_update_ui()
	_update_combat_display()


func _load_test_cards() -> void:
	mannaia_del_carnefice = (
		CardDatabase.get_card(
			CardDatabase.MANNAIA_DEL_CARNEFICE
		)
	)

	chiodo_del_giudizio = (
		CardDatabase.get_card(
			CardDatabase.CHIODO_DEL_GIUDIZIO
		)
	)

	maglio_della_pena = (
		CardDatabase.get_card(
			CardDatabase.MAGLIO_DELLA_PENA
		)
	)

	bende_del_viandante = (
		CardDatabase.get_card(
			CardDatabase.BENDE_DEL_VIANDANTE
		)
	)

	catena_del_contrappasso = (
		CardDatabase.get_card(
			CardDatabase.CATENA_DEL_CONTRAPPASSO
		)
	)

	spinta_dei_condannati = (
		CardDatabase.get_card(
			CardDatabase.SPINTA_DEI_CONDANNATI
		)
	)

	active_cards = [
		mannaia_del_carnefice,
		chiodo_del_giudizio,
		maglio_della_pena,
		bende_del_viandante,
		catena_del_contrappasso,
		spinta_dei_condannati
	]


func _load_test_enemy() -> void:
	var data: EnemyData = (
		EnemyDatabase.get_enemy(
			EnemyDatabase.SENZA_VOLTO
		)
	)

	enemy.setup(data)


func _setup_card_bar() -> void:
	if not card_bar.has_method(
		"set_cards"
	):
		push_error(
			"CardBar non espone set_cards()."
		)
		return

	card_bar.set_cards(
		active_cards
	)

	if not card_bar.card_selected.is_connected(
		_on_card_selected
	):
		card_bar.card_selected.connect(
			_on_card_selected
		)


func _on_card_selected(
	card: CardData
) -> void:
	_try_use_card(card)


func _unhandled_input(
	event: InputEvent
) -> void:
	if player_is_dead:
		return

	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_C:
				_toggle_combat_mode()
				return

			if event.keycode == KEY_Q:
				_select_previous_body_part()
				return

			if event.keycode == KEY_E:
				_select_next_body_part()
				return

	if is_moving or enemy_is_moving:
		return

	if (
		combat_mode
		and player_actions_remaining <= 0
	):
		return

	if event is InputEventMouseButton:
		if (
			event.button_index
			== MOUSE_BUTTON_LEFT
			and event.pressed
		):
			_handle_grid_click(
				event.position
			)


func _select_previous_body_part() -> void:
	if not combat_mode:
		return

	if enemy.is_dead():
		return

	if is_moving or enemy_is_moving:
		return

	var parts: Array[String] = (
		enemy.get_body_part_names()
	)

	selected_body_part_index -= 1

	if selected_body_part_index < 0:
		selected_body_part_index = (
			parts.size() - 1
		)

	_update_ui()


func _select_next_body_part() -> void:
	if not combat_mode:
		return

	if enemy.is_dead():
		return

	if is_moving or enemy_is_moving:
		return

	var parts: Array[String] = (
		enemy.get_body_part_names()
	)

	selected_body_part_index += 1

	if (
		selected_body_part_index
		>= parts.size()
	):
		selected_body_part_index = 0

	_update_ui()


func _get_selected_body_part() -> String:
	var parts: Array[String] = (
		enemy.get_body_part_names()
	)

	if parts.is_empty():
		return ""

	if (
		selected_body_part_index
		>= parts.size()
	):
		selected_body_part_index = 0

	return parts[
		selected_body_part_index
	]


func _get_player_move_range() -> int:
	if player_statuses.is_immobilized():
		return 0

	var result: int = (
		COMBAT_MOVE_RANGE
	)

	if player_statuses.is_slowed():
		result -= 1

	return maxi(
		result,
		0
	)


func _handle_grid_click(
	mouse_position: Vector2
) -> void:
	if enemy_is_moving:
		return

	var mouse_local: Vector2 = (
		grid.to_local(
			mouse_position
		)
	)

	var clicked_cell: Vector2i = (
		grid.local_to_cell(
			mouse_local
		)
	)

	if not grid.is_cell_walkable(
		clicked_cell
	):
		return

	var path: Array[Vector2i] = (
		grid.find_path(
			player_cell,
			clicked_cell
		)
	)

	if path.size() <= 1:
		return

	if combat_mode:
		var distance: int = (
			path.size() - 1
		)

		var move_range: int = (
			_get_player_move_range()
		)

		if distance > move_range:
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

	var next_cell: Vector2i = (
		current_path.pop_front()
	)

	var target_position: Vector2 = (
		grid.position
		+ grid.cell_to_local(
			next_cell
		)
	)

	var tween: Tween = (
		create_tween()
	)

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


func _is_card_available(
	card: CardData
) -> bool:
	if card == null:
		return false

	if not combat_mode:
		return false

	if player_is_dead:
		return false

	if enemy.is_dead():
		return false

	if is_moving:
		return false

	if enemy_is_moving:
		return false

	if (
		player_actions_remaining
		< card.action_cost
	):
		return false

	if card.healing > 0:
		return (
			player_hp
			< PLAYER_MAX_HP
		)

	if card.damage <= 0:
		return false

	if (
		"Mira" in card.tags
		and player_statuses.is_blinded()
	):
		return false

	var effective_range: int = (
		_get_effective_card_range(
			card
		)
	)

	var distance: int = (
		_grid_distance(
			player_cell,
			enemy_cell
		)
	)

	return (
		distance
		<= effective_range
	)


func _get_effective_card_range(
	card: CardData
) -> int:
	var effective_range: int = (
		card.attack_range
	)

	if (
		"Distanza" in card.tags
		and player_statuses.is_blinded()
	):
		effective_range = maxi(
			effective_range - 2,
			0
		)

	return effective_range


func _refresh_card_bar() -> void:
	card_bar.visible = (
		combat_mode
		and not player_is_dead
		and not enemy.is_dead()
	)

	if not card_bar.has_method(
		"set_card_available"
	):
		return

	for card in active_cards:
		card_bar.set_card_available(
			card,
			_is_card_available(card)
		)


func _try_use_card(
	card: CardData
) -> void:
	if card == null:
		return

	if not _is_card_available(card):
		return

	if card.healing > 0:
		_use_healing_card(card)
		return

	if card.damage > 0:
		_use_attack_card(card)


func _use_attack_card(
	card: CardData
) -> void:
	var modified_damage: int = (
		enemy.modify_incoming_attack_damage(
			card.damage
		)
	)

	if "Mira" in card.tags:
		_use_aimed_attack(
			card,
			modified_damage
		)

		return

	var damage_done: int = (
		enemy.take_vitality_damage(
			modified_damage
		)
	)

	print(
		"Usata carta: ",
		card.card_name
	)

	print(
		"Danno Vitalità: ",
		damage_done
	)

	if enemy.is_dead():
		_enemy_died()
		return

	_apply_card_effects(card)

	if card.pull_distance > 0:
		_pull_enemy(
			card.pull_distance
		)

	if card.push_distance > 0:
		_push_enemy(
			card.push_distance,
			card
		)

	if enemy.is_dead():
		return

	_update_ui()

	_finish_player_action(
		card.action_cost
	)


func _use_aimed_attack(
	card: CardData,
	damage: int
) -> void:
	var target_part: String = (
		_get_selected_body_part()
	)

	var result: Dictionary = (
		enemy.take_part_damage(
			target_part,
			damage
		)
	)

	print(
		"Usata carta: ",
		card.card_name
	)

	print(
		"Parte colpita: ",
		target_part
	)

	print(
		"Danno Integrità: ",
		result["part_damage"]
	)

	print(
		"Danno Vitalità trasferito: ",
		result["vitality_damage"]
	)

	if bool(
		result["destroyed"]
	):
		print(
			target_part,
			" DISTRUTTA"
		)

	if enemy.is_dead():
		_update_ui()
		_enemy_died()
		return

	_apply_card_effects(card)

	_update_ui()

	_finish_player_action(
		card.action_cost
	)


func _apply_card_effects(
	card: CardData
) -> void:
	if not card.status_to_apply.is_empty():
		enemy.status_manager.add_status(
			card.status_to_apply,
			card.status_duration,
			card.status_stacks
		)

		print(
			"Stato applicato: ",
			card.status_to_apply
		)

	if card.fracture_selected_part:
		var target_part: String = (
			_get_selected_body_part()
		)

		enemy.apply_fracture(
			target_part
		)

		print(
			"Frattura applicata a: ",
			target_part
		)

	_update_ui()


func _pull_enemy(
	pull_distance: int
) -> void:
	for _step in range(
		pull_distance
	):
		grid.remove_occupied_cell(
			enemy_cell
		)

		var path: Array[Vector2i] = (
			grid.find_path(
				enemy_cell,
				player_cell
			)
		)

		grid.add_occupied_cell(
			enemy_cell
		)

		if path.size() <= 1:
			return

		var next_cell: Vector2i = (
			path[1]
		)

		if next_cell == player_cell:
			return

		if not grid.is_cell_walkable(
			next_cell
		):
			return

		grid.remove_occupied_cell(
			enemy_cell
		)

		enemy_cell = next_cell

		grid.add_occupied_cell(
			enemy_cell
		)

		enemy.position = (
			grid.position
			+ grid.cell_to_local(
				enemy_cell
			)
		)


func _push_enemy(
	push_distance: int,
	source_card: CardData
) -> void:
	for _step in range(
		push_distance
	):
		var direction: Vector2i = (
			enemy_cell
			- player_cell
		)

		if direction.x != 0:
			direction.x = signi(
				direction.x
			)

		if direction.y != 0:
			direction.y = signi(
				direction.y
			)

		var next_cell: Vector2i = (
			enemy_cell
			+ direction
		)

		if not grid.is_cell_inside(
			next_cell
		):
			return

		if grid.is_cell_blocked(
			next_cell
		):
			_apply_collision_damage()

			_apply_collision_card_effect(
				source_card
			)

			return

		grid.remove_occupied_cell(
			enemy_cell
		)

		var can_move: bool = (
			grid.is_cell_walkable(
				next_cell
			)
		)

		grid.add_occupied_cell(
			enemy_cell
		)

		if not can_move:
			return

		grid.remove_occupied_cell(
			enemy_cell
		)

		enemy_cell = next_cell

		grid.add_occupied_cell(
			enemy_cell
		)

		enemy.position = (
			grid.position
			+ grid.cell_to_local(
				enemy_cell
			)
		)


func _apply_collision_damage() -> void:
	var damage_done: int = (
		enemy.take_vitality_damage(
			COLLISION_DAMAGE
		)
	)

	print(
		"Collisione: ",
		damage_done,
		" danni alla Vitalità."
	)

	_update_ui()

	if enemy.is_dead():
		_enemy_died()


func _apply_collision_card_effect(
	card: CardData
) -> void:
	if enemy.is_dead():
		return

	if (
		card
		.collision_status_to_apply
		.is_empty()
	):
		return

	enemy.status_manager.add_status(
		card.collision_status_to_apply,
		card.collision_status_duration,
		card.collision_status_stacks
	)

	print(
		"Collisione: applicato ",
		card.collision_status_to_apply
	)

	_update_ui()


func _use_healing_card(
	card: CardData
) -> void:
	var old_hp: int = (
		player_hp
	)

	player_hp += (
		card.healing
	)

	if player_hp > PLAYER_MAX_HP:
		player_hp = PLAYER_MAX_HP

	var healed_amount: int = (
		player_hp - old_hp
	)

	print(
		"Usata carta: ",
		card.card_name
	)

	print(
		"HP recuperati: ",
		healed_amount
	)

	_update_ui()

	_finish_player_action(
		card.action_cost
	)


func _finish_player_action(
	action_cost: int
) -> void:
	player_actions_remaining -= (
		action_cost
	)

	if player_actions_remaining < 0:
		player_actions_remaining = 0

	_update_ui()

	if player_actions_remaining <= 0:
		grid.clear_reachable_cells()

		if not _end_player_activation():
			return

		_start_enemy_turn()
	else:
		_update_combat_display()


func _begin_player_activation() -> bool:
	var result: Dictionary = (
		player_statuses.begin_activation()
	)

	var burn_damage: int = int(
		result.get(
			"burn_damage",
			0
		)
	)

	if burn_damage > 0:
		player_hp -= burn_damage

		if player_hp < 0:
			player_hp = 0

		print(
			"Ustione giocatore: -",
			burn_damage,
			" HP"
		)

	if player_hp <= 0:
		_player_died()
		return false

	if bool(
		result.get(
			"stunned",
			false
		)
	):
		player_actions_remaining = 1

		print(
			"Stordimento: solo 1 Azione."
		)
	else:
		player_actions_remaining = (
			PLAYER_MAX_ACTIONS
		)

	_update_ui()
	_update_combat_display()

	return true


func _end_player_activation() -> bool:
	var result: Dictionary = (
		player_statuses.end_activation()
	)

	var bleeding_damage: int = int(
		result.get(
			"bleeding_damage",
			0
		)
	)

	if bleeding_damage > 0:
		player_hp -= bleeding_damage

		if player_hp < 0:
			player_hp = 0

		print(
			"Sanguinamento giocatore: -",
			bleeding_damage,
			" HP"
		)

	if player_hp <= 0:
		_player_died()
		return false

	return true


func _start_enemy_turn() -> void:
	if enemy.is_dead():
		return

	enemy_is_moving = true

	var activation: Dictionary = (
		enemy.begin_activation()
	)

	var burn_damage: int = int(
		activation.get(
			"burn_damage_applied",
			0
		)
	)

	if burn_damage > 0:
		print(
			"Ustione nemico: -",
			burn_damage,
			" HP"
		)

	_update_ui()

	if enemy.is_dead():
		_enemy_died()
		return

	var enemy_is_stunned: bool = bool(
		activation.get(
			"stunned",
			false
		)
	)

	if enemy_is_stunned:
		print(
			"Il nemico è Stordito: "
			+ "non può avanzare."
		)

		if (
			_grid_distance(
				enemy_cell,
				player_cell
			)
			== 1
		):
			_enemy_attack()
		else:
			_finish_enemy_turn()

		return

	var enemy_move_range: int = (
		enemy.get_move_range()
	)

	if enemy_move_range <= 0:
		if (
			_grid_distance(
				enemy_cell,
				player_cell
			)
			== 1
		):
			_enemy_attack()
		else:
			_finish_enemy_turn()

		return

	grid.remove_occupied_cell(
		enemy_cell
	)

	var path: Array[Vector2i] = (
		grid.find_path(
			enemy_cell,
			player_cell
		)
	)

	grid.add_occupied_cell(
		enemy_cell
	)

	if path.size() <= 1:
		_finish_enemy_turn()
		return

	if path.size() == 2:
		_enemy_attack()
		return

	var steps_to_move: int = mini(
		enemy_move_range,
		path.size() - 2
	)

	if steps_to_move <= 0:
		_finish_enemy_turn()
		return

	var next_cell: Vector2i = (
		path[
			steps_to_move
		]
	)

	grid.remove_occupied_cell(
		enemy_cell
	)

	enemy_cell = next_cell

	grid.add_occupied_cell(
		enemy_cell
	)

	var target_position: Vector2 = (
		grid.position
		+ grid.cell_to_local(
			enemy_cell
		)
	)

	var tween: Tween = (
		create_tween()
	)

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
	var damage: int = (
		enemy.get_attack_damage()
	)

	if player_statuses.consume_marked():
		damage = roundi(
			damage * 1.25
		)

	player_hp -= damage

	if player_hp < 0:
		player_hp = 0

	print(
		"Il nemico infligge ",
		damage,
		" danni."
	)

	_update_ui()

	if player_hp <= 0:
		_player_died()
		return

	_finish_enemy_turn()


func _finish_enemy_turn() -> void:
	var result: Dictionary = (
		enemy.end_activation()
	)

	var bleeding_damage: int = int(
		result.get(
			"bleeding_damage_applied",
			0
		)
	)

	if bleeding_damage > 0:
		print(
			"Sanguinamento nemico: -",
			bleeding_damage,
			" HP"
		)

	if enemy.is_dead():
		_enemy_died()
		return

	enemy_is_moving = false

	if player_is_dead:
		return

	_begin_player_activation()


func _enemy_died() -> void:
	enemy_is_moving = false

	grid.remove_occupied_cell(
		enemy_cell
	)

	enemy.visible = false
	combat_mode = false

	grid.clear_reachable_cells()

	_update_ui()


func _player_died() -> void:
	player_is_dead = true
	combat_mode = false
	enemy_is_moving = false

	grid.clear_reachable_cells()

	_update_ui()


func _toggle_combat_mode() -> void:
	if player_is_dead:
		return

	if enemy.is_dead():
		return

	if is_moving or enemy_is_moving:
		return

	combat_mode = not combat_mode

	if combat_mode:
		_begin_player_activation()
	else:
		grid.clear_reachable_cells()
		_update_ui()


func _update_combat_display() -> void:
	if combat_mode:
		var move_range: int = (
			_get_player_move_range()
		)

		var reachable: Array[Vector2i] = (
			grid.calculate_reachable_cells(
				player_cell,
				move_range
			)
		)

		grid.set_reachable_cells(
			reachable
		)
	else:
		grid.clear_reachable_cells()


func _grid_distance(
	first_cell: Vector2i,
	second_cell: Vector2i
) -> int:
	var difference: Vector2i = (
		first_cell
		- second_cell
	)

	return (
		absi(difference.x)
		+ absi(difference.y)
	)


func _status_summary_to_text(
	statuses: Array[String]
) -> String:
	if statuses.is_empty():
		return "Nessuno"

	var result: String = ""

	for index in range(
		statuses.size()
	):
		if index > 0:
			result += ", "

		result += statuses[index]

	return result


func _update_status_labels() -> void:
	var player_summary: Array[String] = (
		player_statuses
		.get_status_summary()
	)

	player_status_label.text = (
		"Stati G: "
		+ _status_summary_to_text(
			player_summary
		)
	)

	if enemy.is_dead():
		enemy_status_label.text = (
			"Stati N: -"
		)

		return

	var enemy_summary: Array[String] = (
		enemy.status_manager
		.get_status_summary()
	)

	enemy_status_label.text = (
		"Stati N: "
		+ _status_summary_to_text(
			enemy_summary
		)
	)


func _update_ui() -> void:
	hp_label.text = (
		"HP: "
		+ str(player_hp)
		+ "/"
		+ str(PLAYER_MAX_HP)
	)

	actions_label.text = (
		"Azioni: "
		+ str(
			player_actions_remaining
		)
		+ "/"
		+ str(
			PLAYER_MAX_ACTIONS
		)
	)

	if enemy.is_dead():
		enemy_hp_label.text = (
			enemy.get_enemy_name()
			+ ": MORTO"
		)
	else:
		enemy_hp_label.text = (
			enemy.get_enemy_name()
			+ ": "
			+ str(
				enemy.get_hp()
			)
			+ "/"
			+ str(
				enemy.get_max_hp()
			)
			+ " HP"
		)

	var selected_part: String = (
		_get_selected_body_part()
	)

	if enemy.is_dead():
		target_part_label.text = (
			"Mira: -"
		)
	else:
		target_part_label.text = (
			"Mira: "
			+ selected_part
			+ " "
			+ str(
				enemy.get_part_integrity(
					selected_part
				)
			)
			+ "/"
			+ str(
				enemy.get_part_max_integrity(
					selected_part
				)
			)
		)

	_update_status_labels()
	_refresh_card_bar()

	if player_is_dead:
		state_label.text = (
			"MORTO"
		)

	elif enemy.is_dead():
		state_label.text = (
			"COMBATTIMENTO TERMINATO"
		)

	elif enemy_is_moving:
		state_label.text = (
			"TURNO NEMICO"
		)

	elif combat_mode:
		state_label.text = (
			"TURNO GIOCATORE"
		)

	else:
		state_label.text = (
			"ESPLORAZIONE"
		)
