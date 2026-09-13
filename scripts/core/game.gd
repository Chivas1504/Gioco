extends Node2D


@onready var grid: Node2D = $Grid
@onready var player: CharacterBody2D = $Player

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

@onready var card_bar = $UI/HUD/CardBar


const MOVE_TIME := 0.12
const ENEMY_MOVE_TIME := 0.18

const EXPLORATION_MOVE_SPEED := 220.0

const COMBAT_MOVE_RANGE := 2
const PLAYER_MAX_ACTIONS := 2

const PLAYER_MAX_HP := 30
const COLLISION_DAMAGE := 2


var current_mode: String = GameMode.EXPLORATION


var player_cell: Vector2i = Vector2i(0, 0)
var player_hp: int = PLAYER_MAX_HP

var player_statuses: StatusManager = StatusManager.new()
var noise_system: NoiseSystem = NoiseSystem.new()


var enemy_units: Array[EnemyUnit] = []
var active_combat_enemies: Array[EnemyUnit] = []

var enemy_cells: Dictionary = {}
var enemy_combat_groups: Dictionary = {}


var selected_enemy: EnemyUnit
var selected_body_part_index: int = 0

var enemy_turn_index: int = 0


var current_path: Array[Vector2i] = []

var is_moving: bool = false
var enemy_is_moving: bool = false

var player_is_dead: bool = false

var player_actions_remaining: int = PLAYER_MAX_ACTIONS


var mannaia_del_carnefice: CardData
var chiodo_del_giudizio: CardData
var maglio_della_pena: CardData
var bende_del_viandante: CardData
var catena_del_contrappasso: CardData
var spinta_dei_condannati: CardData

var active_cards: Array[CardData] = []


func _ready() -> void:
	_load_test_cards()
	_setup_enemies()
	_setup_card_bar()

	player.position = (
		grid.position
		+ grid.cell_to_local(
			player_cell
		)
	)

	_update_grid_occupancy()

	_enter_exploration_mode()

	_update_ui()


func _process(
	delta: float
) -> void:
	if player_is_dead:
		player.velocity = Vector2.ZERO
		return

	noise_system.tick(
		delta
	)

	if not _is_exploration_mode():
		player.velocity = Vector2.ZERO
		return

	_process_exploration_movement()

	_check_enemy_detection()


func _process_exploration_movement() -> void:
	var input_direction: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	if input_direction != Vector2.ZERO:
		input_direction = input_direction.normalized()

	player.velocity = (
		input_direction
		* EXPLORATION_MOVE_SPEED
	)

	player.move_and_slide()

	if input_direction != Vector2.ZERO:
		noise_system.emit_world_noise(
			player.global_position
		)


func _check_enemy_detection() -> void:
	if not _is_exploration_mode():
		return

	var detecting_enemy: EnemyUnit = (
		EnemyDetectionSystem.find_detecting_enemy(
			player.global_position,
			enemy_units,
			noise_system,
			get_world_2d()
		)
	)

	if detecting_enemy == null:
		return

	print(
		detecting_enemy.get_enemy_name(),
		" ha rilevato il giocatore tramite ",
		detecting_enemy.get_detection_mode(),
		"."
	)

	_start_combat_from_enemy(
		detecting_enemy
	)


func _start_combat_from_enemy(
	trigger_enemy: EnemyUnit
) -> void:
	active_combat_enemies = (
		CombatParticipantSystem.build_combat_group(
			trigger_enemy,
			enemy_units,
			enemy_combat_groups
		)
	)

	if active_combat_enemies.is_empty():
		return

	selected_enemy = trigger_enemy
	selected_body_part_index = 0

	var group_id: String = ""

	if enemy_combat_groups.has(
		trigger_enemy
	):
		group_id = str(
			enemy_combat_groups[
				trigger_enemy
			]
		)

	print(
		"Gruppo di combattimento: ",
		group_id
	)

	print(
		"Nemici entrati nel combattimento: ",
		active_combat_enemies.size()
	)

	for enemy_unit in active_combat_enemies:
		print(
			" - ",
			enemy_unit.get_enemy_name()
		)

	_enter_combat_mode()


func _is_combat_mode() -> bool:
	return current_mode == GameMode.COMBAT


func _is_exploration_mode() -> bool:
	return current_mode == GameMode.EXPLORATION


func _enter_exploration_mode() -> void:
	current_mode = GameMode.EXPLORATION

	is_moving = false
	enemy_is_moving = false

	player.velocity = Vector2.ZERO

	current_path.clear()

	grid.clear_reachable_cells()
	grid.visible = false

	card_bar.visible = false

	noise_system.clear_noise()

	active_combat_enemies.clear()

	selected_enemy = null
	selected_body_part_index = 0

	_update_enemy_visibility()
	_update_enemy_selection_visuals()
	_update_grid_occupancy()
	_update_ui()

func _enter_combat_mode() -> void:
	if player_is_dead:
		return

	if active_combat_enemies.is_empty():
		return

	player.velocity = Vector2.ZERO

	var exploration_noise_was_active: bool = (
		noise_system.has_active_world_noise()
	)

	_snap_player_to_combat_grid()

	current_mode = GameMode.COMBAT

	grid.visible = true

	if (
		selected_enemy == null
		or selected_enemy.is_dead()
	):
		selected_enemy = (
			_get_first_alive_combat_enemy()
		)

	_update_enemy_visibility()
	_update_grid_occupancy()
	_update_enemy_selection_visuals()

	if exploration_noise_was_active:
		noise_system.emit_noise(
			player_cell
		)

	noise_system.clear_world_noise()

	_begin_player_activation()

func _snap_player_to_combat_grid() -> void:
	var player_position_relative_to_grid: Vector2 = (
		player.position - grid.position
	)

	var desired_cell: Vector2i = (
		grid.local_to_cell(
			player_position_relative_to_grid
		)
	)

	var valid_cell: Vector2i = (
		_find_nearest_valid_combat_cell(
			desired_cell
		)
	)

	player_cell = valid_cell

	player.position = (
		grid.position
		+ grid.cell_to_local(
			player_cell
		)
	)

	print(
		"Entrata in combattimento. Player agganciato alla cella ",
		player_cell
	)


func _find_nearest_valid_combat_cell(
	start_cell: Vector2i
) -> Vector2i:
	if (
		grid.is_cell_inside(
			start_cell
		)
		and not grid.is_cell_blocked(
			start_cell
		)
		and not grid.is_cell_occupied(
			start_cell
		)
	):
		return start_cell

	var best_cell: Vector2i = player_cell
	var best_distance: int = 999999

	for x in range(
		grid.GRID_SIZE
	):
		for y in range(
			grid.GRID_SIZE
		):
			var candidate := Vector2i(
				x,
				y
			)

			if grid.is_cell_blocked(
				candidate
			):
				continue

			if grid.is_cell_occupied(
				candidate
			):
				continue

			var distance: int = (
				absi(
					candidate.x - start_cell.x
				)
				+ absi(
					candidate.y - start_cell.y
				)
			)

			if distance < best_distance:
				best_distance = distance
				best_cell = candidate

	return best_cell


func _load_test_cards() -> void:
	mannaia_del_carnefice = CardDatabase.get_card(
		CardDatabase.MANNAIA_DEL_CARNEFICE
	)

	chiodo_del_giudizio = CardDatabase.get_card(
		CardDatabase.CHIODO_DEL_GIUDIZIO
	)

	maglio_della_pena = CardDatabase.get_card(
		CardDatabase.MAGLIO_DELLA_PENA
	)

	bende_del_viandante = CardDatabase.get_card(
		CardDatabase.BENDE_DEL_VIANDANTE
	)

	catena_del_contrappasso = CardDatabase.get_card(
		CardDatabase.CATENA_DEL_CONTRAPPASSO
	)

	spinta_dei_condannati = CardDatabase.get_card(
		CardDatabase.SPINTA_DEI_CONDANNATI
	)

	active_cards = [
		mannaia_del_carnefice,
		chiodo_del_giudizio,
		maglio_della_pena,
		bende_del_viandante,
		catena_del_contrappasso,
		spinta_dei_condannati
	]


func _setup_enemies() -> void:
	enemy_units.clear()
	active_combat_enemies.clear()

	enemy_cells.clear()
	enemy_combat_groups.clear()

	var encounter: EncounterData = (
		EncounterDatabase.get_encounter(
			EncounterDatabase.LIMBO_TEST
		)
	)

	if encounter == null:
		push_error(
			"Impossibile caricare l'incontro."
		)

		return

	for index in range(
		encounter.get_enemy_count()
	):
		var encounter_enemy: EncounterData.EncounterEnemy = (
			encounter.get_enemy(
				index
			)
		)

		if encounter_enemy == null:
			continue

		var enemy_data: EnemyData = (
			EnemyDatabase.get_enemy(
				encounter_enemy.enemy_id
			)
		)

		if enemy_data == null:
			continue

		var enemy_unit: EnemyUnit = EnemyUnit.new()

		add_child(
			enemy_unit
		)

		enemy_unit.setup(
			enemy_data
		)

		enemy_units.append(
			enemy_unit
		)

		enemy_cells[
			enemy_unit
		] = encounter_enemy.spawn_cell

		enemy_combat_groups[
			enemy_unit
		] = encounter_enemy.combat_group_id

		enemy_unit.position = (
			grid.position
			+ grid.cell_to_local(
				encounter_enemy.spawn_cell
			)
		)


func _setup_card_bar() -> void:
	if not card_bar.has_method(
		"set_cards"
	):
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
	_try_use_card(
		card
	)


func _unhandled_input(
	event: InputEvent
) -> void:
	if player_is_dead:
		return

	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_Q:
				_select_previous_body_part()
				return

			if event.keycode == KEY_E:
				_select_next_body_part()
				return

	if not _is_combat_mode():
		return

	if is_moving or enemy_is_moving:
		return

	if player_actions_remaining <= 0:
		return

	if event is InputEventMouseButton:
		if (
			event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed
		):
			_handle_grid_click(
				event.position
			)


func _handle_grid_click(
	mouse_position: Vector2
) -> void:
	if not _is_combat_mode():
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

	var clicked_enemy: EnemyUnit = (
		_get_enemy_at_cell(
			clicked_cell
		)
	)

	if clicked_enemy != null:
		_select_enemy(
			clicked_enemy
		)

		return

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

	var distance: int = path.size() - 1

	if distance > _get_player_move_range():
		return

	current_path = path
	current_path.remove_at(0)

	_move_player_along_path()


func _select_enemy(
	enemy_unit: EnemyUnit
) -> void:
	if enemy_unit == null:
		return

	if enemy_unit.is_dead():
		return

	if enemy_unit not in active_combat_enemies:
		return

	selected_enemy = enemy_unit
	selected_body_part_index = 0

	_update_enemy_selection_visuals()
	_update_ui()


func _get_enemy_at_cell(
	cell: Vector2i
) -> EnemyUnit:
	var source: Array[EnemyUnit] = enemy_units

	if _is_combat_mode():
		source = active_combat_enemies

	for enemy_unit in source:
		if enemy_unit.is_dead():
			continue

		if _get_enemy_cell(
			enemy_unit
		) == cell:
			return enemy_unit

	return null


func _get_enemy_cell(
	enemy_unit: EnemyUnit
) -> Vector2i:
	if not enemy_cells.has(
		enemy_unit
	):
		return Vector2i(-1, -1)

	return enemy_cells[
		enemy_unit
	]


func _set_enemy_cell(
	enemy_unit: EnemyUnit,
	cell: Vector2i
) -> void:
	enemy_cells[
		enemy_unit
	] = cell


func _update_grid_occupancy() -> void:
	var occupied: Array[Vector2i] = []

	var source: Array[EnemyUnit] = enemy_units

	if _is_combat_mode():
		source = active_combat_enemies

	for enemy_unit in source:
		if enemy_unit.is_dead():
			continue

		occupied.append(
			_get_enemy_cell(
				enemy_unit
			)
		)

	grid.set_occupied_cells(
		occupied
	)


func _update_enemy_selection_visuals() -> void:
	for enemy_unit in enemy_units:
		if enemy_unit.is_dead():
			continue

		if (
			_is_combat_mode()
			and enemy_unit == selected_enemy
			and enemy_unit in active_combat_enemies
		):
			enemy_unit.scale = Vector2(
				1.20,
				1.20
			)
		else:
			enemy_unit.scale = Vector2.ONE


func _select_previous_body_part() -> void:
	if not _is_combat_mode():
		return

	if selected_enemy == null:
		return

	var parts: Array[String] = (
		selected_enemy.get_body_part_names()
	)

	if parts.is_empty():
		return

	selected_body_part_index -= 1

	if selected_body_part_index < 0:
		selected_body_part_index = (
			parts.size() - 1
		)

	_update_ui()


func _select_next_body_part() -> void:
	if not _is_combat_mode():
		return

	if selected_enemy == null:
		return

	var parts: Array[String] = (
		selected_enemy.get_body_part_names()
	)

	if parts.is_empty():
		return

	selected_body_part_index += 1

	if selected_body_part_index >= parts.size():
		selected_body_part_index = 0

	_update_ui()


func _get_selected_body_part() -> String:
	if selected_enemy == null:
		return ""

	var parts: Array[String] = (
		selected_enemy.get_body_part_names()
	)

	if parts.is_empty():
		return ""

	if selected_body_part_index >= parts.size():
		selected_body_part_index = 0

	return parts[
		selected_body_part_index
	]


func _get_player_move_range() -> int:
	if player_statuses.is_immobilized():
		return 0

	var result: int = COMBAT_MOVE_RANGE

	if player_statuses.is_slowed():
		result -= 1

	return maxi(
		result,
		0
	)


func _move_player_along_path() -> void:
	if current_path.is_empty():
		is_moving = false

		_finish_player_action(
			1
		)

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

			noise_system.emit_noise(
				player_cell
			)

			_move_player_along_path()
	)


func _is_card_available(
	card: CardData
) -> bool:
	if card == null:
		return false

	if not _is_combat_mode():
		return false

	if player_is_dead:
		return false

	if is_moving or enemy_is_moving:
		return false

	if player_actions_remaining < card.action_cost:
		return false

	if card.healing > 0:
		return (
			player_hp < PLAYER_MAX_HP
		)

	if selected_enemy == null:
		return false

	if selected_enemy.is_dead():
		return false

	if selected_enemy not in active_combat_enemies:
		return false

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

	var target_cell: Vector2i = (
		_get_enemy_cell(
			selected_enemy
		)
	)

	return (
		_grid_distance(
			player_cell,
			target_cell
		)
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
		_is_combat_mode()
		and not player_is_dead
		and not _all_combat_enemies_dead()
	)

	if not card_bar.has_method(
		"set_card_available"
	):
		return

	for card in active_cards:
		card_bar.set_card_available(
			card,
			_is_card_available(
				card
			)
		)


func _try_use_card(
	card: CardData
) -> void:
	if not _is_card_available(
		card
	):
		return

	if card.healing > 0:
		_use_healing_card(
			card
		)

		return

	_use_attack_card(
		card
	)


func _use_attack_card(
	card: CardData
) -> void:
	if selected_enemy == null:
		return

	var target_enemy: EnemyUnit = selected_enemy

	var modified_damage: int = (
		target_enemy.modify_incoming_attack_damage(
			card.damage
		)
	)

	if "Mira" in card.tags:
		_use_aimed_attack(
			card,
			modified_damage
		)

		return

	target_enemy.take_vitality_damage(
		modified_damage
	)

	if target_enemy.is_dead():
		_handle_enemy_death(
			target_enemy
		)

		if _all_combat_enemies_dead():
			return

		_finish_player_action(
			card.action_cost
		)

		return

	_apply_card_effects(
		card,
		target_enemy
	)

	if card.pull_distance > 0:
		_pull_enemy(
			target_enemy,
			card.pull_distance
		)

	if card.push_distance > 0:
		_push_enemy(
			target_enemy,
			card.push_distance,
			card
		)

	_update_ui()

	_finish_player_action(
		card.action_cost
	)


func _use_aimed_attack(
	card: CardData,
	damage: int
) -> void:
	if selected_enemy == null:
		return

	var target_enemy: EnemyUnit = selected_enemy
	var target_part: String = _get_selected_body_part()

	target_enemy.take_part_damage(
		target_part,
		damage
	)

	if target_enemy.is_dead():
		_handle_enemy_death(
			target_enemy
		)

		if _all_combat_enemies_dead():
			return

		_finish_player_action(
			card.action_cost
		)

		return

	_apply_card_effects(
		card,
		target_enemy
	)

	_update_ui()

	_finish_player_action(
		card.action_cost
	)


func _apply_card_effects(
	card: CardData,
	target_enemy: EnemyUnit
) -> void:
	if target_enemy == null:
		return

	if target_enemy.is_dead():
		return

	if not card.status_to_apply.is_empty():
		target_enemy.status_manager.add_status(
			card.status_to_apply,
			card.status_duration,
			card.status_stacks
		)

	if card.fracture_selected_part:
		target_enemy.apply_fracture(
			_get_selected_body_part()
		)


func _pull_enemy(
	enemy_unit: EnemyUnit,
	pull_distance: int
) -> void:
	for _step in range(
		pull_distance
	):
		var enemy_cell: Vector2i = (
			_get_enemy_cell(
				enemy_unit
			)
		)

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

		var next_cell: Vector2i = path[1]

		if next_cell == player_cell:
			return

		if not grid.is_cell_walkable(
			next_cell
		):
			return

		grid.remove_occupied_cell(
			enemy_cell
		)

		_set_enemy_cell(
			enemy_unit,
			next_cell
		)

		grid.add_occupied_cell(
			next_cell
		)

		enemy_unit.position = (
			grid.position
			+ grid.cell_to_local(
				next_cell
			)
		)


func _push_enemy(
	enemy_unit: EnemyUnit,
	push_distance: int,
	source_card: CardData
) -> void:
	for _step in range(
		push_distance
	):
		var enemy_cell: Vector2i = (
			_get_enemy_cell(
				enemy_unit
			)
		)

		var direction: Vector2i = (
			enemy_cell - player_cell
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
			enemy_cell + direction
		)

		if not grid.is_cell_inside(
			next_cell
		):
			return

		if grid.is_cell_blocked(
			next_cell
		):
			_apply_collision_damage(
				enemy_unit
			)

			_apply_collision_card_effect(
				enemy_unit,
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

		_set_enemy_cell(
			enemy_unit,
			next_cell
		)

		grid.add_occupied_cell(
			next_cell
		)

		enemy_unit.position = (
			grid.position
			+ grid.cell_to_local(
				next_cell
			)
		)


func _apply_collision_damage(
	enemy_unit: EnemyUnit
) -> void:
	enemy_unit.take_vitality_damage(
		COLLISION_DAMAGE
	)

	if enemy_unit.is_dead():
		_handle_enemy_death(
			enemy_unit
		)


func _apply_collision_card_effect(
	enemy_unit: EnemyUnit,
	card: CardData
) -> void:
	if enemy_unit.is_dead():
		return

	if card.collision_status_to_apply.is_empty():
		return

	enemy_unit.status_manager.add_status(
		card.collision_status_to_apply,
		card.collision_status_duration,
		card.collision_status_stacks
	)


func _use_healing_card(
	card: CardData
) -> void:
	player_hp = mini(
		player_hp + card.healing,
		PLAYER_MAX_HP
	)

	_update_ui()

	_finish_player_action(
		card.action_cost
	)


func _finish_player_action(
	action_cost: int
) -> void:
	player_actions_remaining -= action_cost

	if player_actions_remaining < 0:
		player_actions_remaining = 0

	_update_ui()

	if player_actions_remaining <= 0:
		grid.clear_reachable_cells()

		if not _end_player_activation():
			return

		_start_enemy_phase()
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

	player_hp = maxi(
		player_hp - burn_damage,
		0
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
	else:
		player_actions_remaining = PLAYER_MAX_ACTIONS

	enemy_is_moving = false

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

	player_hp = maxi(
		player_hp - bleeding_damage,
		0
	)

	if player_hp <= 0:
		_player_died()

		return false

	return true


func _start_enemy_phase() -> void:
	if not _is_combat_mode():
		return

	enemy_is_moving = true
	enemy_turn_index = 0

	_update_ui()

	_run_next_enemy_turn()


func _run_next_enemy_turn() -> void:
	if not _is_combat_mode():
		return

	while enemy_turn_index < active_combat_enemies.size():
		var enemy_unit: EnemyUnit = (
			active_combat_enemies[
				enemy_turn_index
			]
		)

		enemy_turn_index += 1

		if enemy_unit.is_dead():
			continue

		_run_enemy_turn(
			enemy_unit
		)

		return

	enemy_is_moving = false

	_begin_player_activation()


func _run_enemy_turn(
	enemy_unit: EnemyUnit
) -> void:
	var activation: Dictionary = (
		enemy_unit.begin_activation()
	)

	if enemy_unit.is_dead():
		_handle_enemy_death(
			enemy_unit
		)

		_run_next_enemy_turn()

		return

	var enemy_cell: Vector2i = (
		_get_enemy_cell(
			enemy_unit
		)
	)

	var enemy_is_stunned: bool = bool(
		activation.get(
			"stunned",
			false
		)
	)

	if enemy_is_stunned:
		if (
			_grid_distance(
				enemy_cell,
				player_cell
			) == 1
		):
			_enemy_attack(
				enemy_unit
			)
		else:
			_finish_single_enemy_turn(
				enemy_unit
			)

		return

	var target_cell: Vector2i = player_cell
	var can_attack_target: bool = true

	if (
		enemy_unit.get_detection_mode()
		== EnemyData.PERCEPTION_NOISE
	):
		if not noise_system.has_active_noise():
			_finish_single_enemy_turn(
				enemy_unit
			)

			return

		target_cell = (
			noise_system.get_last_noise_cell()
		)

		can_attack_target = (
			target_cell == player_cell
		)

	var ai_action: Dictionary = (
		EnemyAISystem.choose_action(
			enemy_unit,
			enemy_cell,
			target_cell,
			grid,
			can_attack_target
		)
	)

	var action_type: String = str(
		ai_action.get(
			"type",
			EnemyAISystem.ACTION_NONE
		)
	)

	match action_type:
		EnemyAISystem.ACTION_MELEE:
			_enemy_attack(
				enemy_unit
			)

		EnemyAISystem.ACTION_SPECIAL:
			_execute_enemy_special_action(
				enemy_unit,
				ai_action.get(
					"special_action",
					{}
				)
			)

		EnemyAISystem.ACTION_MOVE:
			_execute_enemy_move(
				enemy_unit,
				ai_action.get(
					"target_cell",
					target_cell
				)
			)

		_:
			_finish_single_enemy_turn(
				enemy_unit
			)


func _execute_enemy_special_action(
	enemy_unit: EnemyUnit,
	special_action: Dictionary
) -> void:
	var special_type: String = str(
		special_action.get(
			"type",
			EnemyAbilitySystem.ACTION_NONE
		)
	)

	match special_type:
		EnemyAbilitySystem.ACTION_CHAIN_PULL:
			_execute_chain_pull_action(
				enemy_unit,
				special_action
			)

		EnemyAbilitySystem.ACTION_RANGED_ATTACK:
			_execute_ranged_action(
				enemy_unit,
				special_action
			)

		_:
			_finish_single_enemy_turn(
				enemy_unit
			)


func _execute_enemy_move(
	enemy_unit: EnemyUnit,
	target_cell: Vector2i
) -> void:
	var enemy_cell: Vector2i = (
		_get_enemy_cell(
			enemy_unit
		)
	)

	var move_range: int = (
		enemy_unit.get_move_range()
	)

	if move_range <= 0:
		_finish_single_enemy_turn(
			enemy_unit
		)

		return

	if enemy_cell == target_cell:
		if (
			enemy_unit.get_detection_mode()
			== EnemyData.PERCEPTION_NOISE
			and target_cell != player_cell
		):
			noise_system.clear_noise()

		_finish_single_enemy_turn(
			enemy_unit
		)

		return

	grid.remove_occupied_cell(
		enemy_cell
	)

	var path: Array[Vector2i] = (
		grid.find_path(
			enemy_cell,
			target_cell
		)
	)

	grid.add_occupied_cell(
		enemy_cell
	)

	if path.size() <= 1:
		_finish_single_enemy_turn(
			enemy_unit
		)

		return

	var max_steps: int = (
		path.size() - 1
	)

	if target_cell == player_cell:
		max_steps = (
			path.size() - 2
		)

	var steps_to_move: int = mini(
		move_range,
		max_steps
	)

	if steps_to_move <= 0:
		if (
			target_cell == player_cell
			and path.size() == 2
		):
			_enemy_attack(
				enemy_unit
			)
		else:
			_finish_single_enemy_turn(
				enemy_unit
			)

		return

	var next_cell: Vector2i = (
		path[
			steps_to_move
		]
	)

	grid.remove_occupied_cell(
		enemy_cell
	)

	_set_enemy_cell(
		enemy_unit,
		next_cell
	)

	grid.add_occupied_cell(
		next_cell
	)

	var target_position: Vector2 = (
		grid.position
		+ grid.cell_to_local(
			next_cell
		)
	)

	var tween: Tween = create_tween()

	tween.tween_property(
		enemy_unit,
		"position",
		target_position,
		ENEMY_MOVE_TIME
	)

	tween.finished.connect(
		func() -> void:
			if (
				enemy_unit.get_detection_mode()
				== EnemyData.PERCEPTION_NOISE
				and next_cell == target_cell
				and target_cell != player_cell
			):
				noise_system.clear_noise()

			_finish_single_enemy_turn(
				enemy_unit
			)
	)


func _execute_chain_pull_action(
	enemy_unit: EnemyUnit,
	action: Dictionary
) -> void:
	var final_cell: Vector2i = (
		action.get(
			"target_cell",
			player_cell
		)
	)

	if final_cell == player_cell:
		_finish_single_enemy_turn(
			enemy_unit
		)

		return

	var target_position: Vector2 = (
		grid.position
		+ grid.cell_to_local(
			final_cell
		)
	)

	var tween: Tween = create_tween()

	tween.tween_property(
		player,
		"position",
		target_position,
		ENEMY_MOVE_TIME
	)

	tween.finished.connect(
		func() -> void:
			player_cell = final_cell

			_finish_single_enemy_turn(
				enemy_unit
			)
	)


func _execute_ranged_action(
	enemy_unit: EnemyUnit,
	action: Dictionary
) -> void:
	var damage: int = int(
		action.get(
			"damage",
			0
		)
	)

	if player_statuses.consume_marked():
		damage = roundi(
			damage * 1.25
		)

	player_hp = maxi(
		player_hp - damage,
		0
	)

	_update_ui()

	if player_hp <= 0:
		_player_died()

		return

	_finish_single_enemy_turn(
		enemy_unit
	)


func _enemy_attack(
	enemy_unit: EnemyUnit
) -> void:
	var damage: int = (
		enemy_unit.get_attack_damage()
	)

	if player_statuses.consume_marked():
		damage = roundi(
			damage * 1.25
		)

	player_hp = maxi(
		player_hp - damage,
		0
	)

	_update_ui()

	if player_hp <= 0:
		_player_died()

		return

	_finish_single_enemy_turn(
		enemy_unit
	)


func _finish_single_enemy_turn(
	enemy_unit: EnemyUnit
) -> void:
	if not enemy_unit.is_dead():
		enemy_unit.end_activation()

	if enemy_unit.is_dead():
		_handle_enemy_death(
			enemy_unit
		)

	_update_ui()

	if _is_combat_mode():
		_run_next_enemy_turn()


func _handle_enemy_death(
	enemy_unit: EnemyUnit
) -> void:
	var dead_cell: Vector2i = (
		_get_enemy_cell(
			enemy_unit
		)
	)

	grid.remove_occupied_cell(
		dead_cell
	)

	enemy_unit.visible = false
	enemy_unit.scale = Vector2.ONE

	if selected_enemy == enemy_unit:
		selected_enemy = (
			_get_first_alive_combat_enemy()
		)

		selected_body_part_index = 0

	_update_grid_occupancy()
	_update_enemy_selection_visuals()

	if _all_combat_enemies_dead():
		_end_combat()

	_update_ui()


func _get_first_alive_combat_enemy() -> EnemyUnit:
	for enemy_unit in active_combat_enemies:
		if not enemy_unit.is_dead():
			return enemy_unit

	return null


func _all_combat_enemies_dead() -> bool:
	if active_combat_enemies.is_empty():
		return true

	for enemy_unit in active_combat_enemies:
		if not enemy_unit.is_dead():
			return false

	return true


func _all_encounter_enemies_dead() -> bool:
	if enemy_units.is_empty():
		return true

	for enemy_unit in enemy_units:
		if not enemy_unit.is_dead():
			return false

	return true


func _end_combat() -> void:
	noise_system.clear_noise()
	noise_system.clear_world_noise()

	_enter_exploration_mode()


func _player_died() -> void:
	player_is_dead = true
	enemy_is_moving = false

	player.velocity = Vector2.ZERO

	grid.clear_reachable_cells()
	grid.visible = false

	card_bar.visible = false

	_update_ui()


func _update_combat_display() -> void:
	if not _is_combat_mode():
		grid.clear_reachable_cells()

		return

	var reachable: Array[Vector2i] = (
		grid.calculate_reachable_cells(
			player_cell,
			_get_player_move_range()
		)
	)

	grid.set_reachable_cells(
		reachable
	)


func _grid_distance(
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

		result += statuses[
			index
		]

	return result


func _update_status_labels() -> void:
	player_status_label.text = (
		"Stati G: "
		+ _status_summary_to_text(
			player_statuses.get_status_summary()
		)
	)

	if (
		selected_enemy == null
		or selected_enemy.is_dead()
	):
		enemy_status_label.text = (
			"Stati N: -"
		)

		return

	enemy_status_label.text = (
		"Stati N: "
		+ _status_summary_to_text(
			selected_enemy.status_manager
			.get_status_summary()
		)
	)


func _update_ui() -> void:
	hp_label.text = (
		"HP: "
		+ str(
			player_hp
		)
		+ "/"
		+ str(
			PLAYER_MAX_HP
		)
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

	if (
		_is_combat_mode()
		and selected_enemy != null
		and not selected_enemy.is_dead()
	):
		enemy_hp_label.text = (
			selected_enemy.get_enemy_name()
			+ ": "
			+ str(
				selected_enemy.get_hp()
			)
			+ "/"
			+ str(
				selected_enemy.get_max_hp()
			)
			+ " HP"
		)

		var selected_part: String = (
			_get_selected_body_part()
		)

		if selected_part.is_empty():
			target_part_label.text = (
				"Mira: -"
			)
		else:
			target_part_label.text = (
				"Mira: "
				+ selected_part
				+ " "
				+ str(
					selected_enemy.get_part_integrity(
						selected_part
					)
				)
				+ "/"
				+ str(
					selected_enemy.get_part_max_integrity(
						selected_part
					)
				)
			)

	else:
		enemy_hp_label.text = (
			"Nemico: -"
		)

		target_part_label.text = (
			"Mira: -"
		)

	_update_status_labels()
	_refresh_card_bar()
	_update_enemy_selection_visuals()

	if player_is_dead:
		state_label.text = (
			"MORTO"
		)

	elif _all_encounter_enemies_dead():
		state_label.text = (
			"AREA RIPULITA"
		)

	elif enemy_is_moving:
		state_label.text = (
			"TURNO NEMICI"
		)

	elif _is_combat_mode():
		state_label.text = (
			"TURNO GIOCATORE - "
			+ str(
				_count_alive_combat_enemies()
			)
			+ " NEMICI"
		)

	else:
		state_label.text = (
			"ESPLORAZIONE"
		)


func _count_alive_combat_enemies() -> int:
	var count: int = 0

	for enemy_unit in active_combat_enemies:
		if not enemy_unit.is_dead():
			count += 1

	return count
	
func _update_enemy_visibility() -> void:
	for enemy_unit in enemy_units:
		if enemy_unit.is_dead():
			enemy_unit.visible = false
			continue

		if _is_combat_mode():
			enemy_unit.visible = (
				enemy_unit in active_combat_enemies
			)
		else:
			enemy_unit.visible = true
