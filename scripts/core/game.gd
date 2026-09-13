extends Node2D


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


const EXPLORATION_MOVE_SPEED := 220.0

const PLAYER_MAX_ACTIONS := 3
const PLAYER_MAX_EFFORT := 6
const PLAYER_EFFORT_RECOVERY := 1
const PLAYER_TIRED_EFFORT := 4

const PLAYER_MAX_HP := 30

const ENEMY_TURN_DELAY := 0.35
const SELECTION_RADIUS := 42.0

const PLAYER_COMBAT_POSITION := Vector2(250.0, 330.0)
const ENEMY_COMBAT_CENTER := Vector2(760.0, 300.0)
const ENEMY_COMBAT_SPACING := 90.0


var current_mode: String = GameMode.EXPLORATION
var current_room_id: String = ""

var player_hp: int = PLAYER_MAX_HP
var player_effort: int = 0
var player_reaction_block: int = 0

var player_statuses: StatusManager = StatusManager.new()
var noise_system: NoiseSystem = NoiseSystem.new()

var enemy_units: Array[EnemyUnit] = []
var active_combat_enemies: Array[EnemyUnit] = []

var enemy_combat_groups: Dictionary = {}
var enemy_rooms: Dictionary = {}
var enemy_exploration_positions: Dictionary = {}
var player_exploration_position: Vector2 = Vector2.ZERO

var selected_enemy: EnemyUnit = null
var selected_body_part_index: int = 0
var enemy_turn_index: int = 0

var enemy_is_acting: bool = false
var player_is_dead: bool = false
var player_actions_remaining: int = PLAYER_MAX_ACTIONS

var mannaia_del_carnefice: CardData
var chiodo_del_giudizio: CardData
var maglio_della_pena: CardData
var bende_del_viandante: CardData
var catena_del_contrappasso: CardData
var parata_dei_condannati: CardData
var esecuzione: CardData

var active_cards: Array[CardData] = []


func _ready() -> void:
	randomize()

	_load_test_cards()
	_setup_enemies()
	_setup_card_bar()
	_setup_room_areas()

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


func _setup_room_areas() -> void:
	var room_areas: Array[Node] = (
		get_tree().get_nodes_in_group(
			"room_areas"
		)
	)

	for node in room_areas:
		if node is RoomArea:
			var room_area: RoomArea = node

			if not room_area.player_entered_room.is_connected(
				_on_player_entered_room
			):
				room_area.player_entered_room.connect(
					_on_player_entered_room
				)

			if not room_area.player_exited_room.is_connected(
				_on_player_exited_room
			):
				room_area.player_exited_room.connect(
					_on_player_exited_room
				)


func _on_player_entered_room(
	room_id: String
) -> void:
	current_room_id = room_id
	_update_ui()


func _on_player_exited_room(
	room_id: String
) -> void:
	if current_room_id == room_id:
		current_room_id = ""

	_update_ui()


func _check_enemy_detection() -> void:
	if not _is_exploration_mode():
		return

	if current_room_id.is_empty():
		return

	var room_enemies: Array[EnemyUnit] = []

	for enemy_unit in enemy_units:
		if enemy_unit == null:
			continue

		if enemy_unit.is_dead():
			continue

		if not enemy_rooms.has(
			enemy_unit
		):
			continue

		var enemy_room_id: String = str(
			enemy_rooms[
				enemy_unit
			]
		)

		if enemy_room_id != current_room_id:
			continue

		room_enemies.append(
			enemy_unit
		)

	if room_enemies.is_empty():
		return

	var detecting_enemy: EnemyUnit = (
		EnemyDetectionSystem.find_detecting_enemy(
			player.global_position,
			room_enemies,
			noise_system,
			get_world_2d()
		)
	)

	if detecting_enemy == null:
		return

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

	_enter_combat_mode()


func _is_combat_mode() -> bool:
	return current_mode == GameMode.COMBAT


func _is_exploration_mode() -> bool:
	return current_mode == GameMode.EXPLORATION


func _enter_exploration_mode() -> void:
	current_mode = GameMode.EXPLORATION

	enemy_is_acting = false
	player.velocity = Vector2.ZERO

	card_bar.visible = false

	noise_system.clear_noise()
	noise_system.clear_world_noise()

	_restore_exploration_positions()

	active_combat_enemies.clear()
	selected_enemy = null
	selected_body_part_index = 0
	player_reaction_block = 0

	_update_enemy_visibility()
	_update_enemy_selection_visuals()
	_update_ui()


func _enter_combat_mode() -> void:
	if player_is_dead:
		return

	if active_combat_enemies.is_empty():
		return

	current_mode = GameMode.COMBAT
	player.velocity = Vector2.ZERO

	_save_exploration_positions()
	_arrange_combat_stage()

	if (
		selected_enemy == null
		or selected_enemy.is_dead()
	):
		selected_enemy = (
			_get_first_alive_combat_enemy()
		)

	noise_system.clear_world_noise()

	_update_enemy_visibility()
	_update_enemy_selection_visuals()
	_begin_player_activation()


func _save_exploration_positions() -> void:
	player_exploration_position = player.position

	enemy_exploration_positions.clear()

	for enemy_unit in enemy_units:
		enemy_exploration_positions[
			enemy_unit
		] = enemy_unit.position


func _restore_exploration_positions() -> void:
	if player_exploration_position != Vector2.ZERO:
		player.position = player_exploration_position

	for enemy_unit in enemy_units:
		if not enemy_exploration_positions.has(
			enemy_unit
		):
			continue

		enemy_unit.position = enemy_exploration_positions[
			enemy_unit
		]

	enemy_exploration_positions.clear()


func _arrange_combat_stage() -> void:
	player.position = PLAYER_COMBAT_POSITION

	var alive_enemies: Array[EnemyUnit] = (
		_get_alive_combat_enemies()
	)

	var top_y: float = (
		ENEMY_COMBAT_CENTER.y
		- (
			float(
				alive_enemies.size() - 1
			)
			* ENEMY_COMBAT_SPACING
			* 0.5
		)
	)

	for index in range(
		alive_enemies.size()
	):
		var enemy_unit: EnemyUnit = alive_enemies[
			index
		]

		enemy_unit.position = Vector2(
			ENEMY_COMBAT_CENTER.x,
			top_y + float(index) * ENEMY_COMBAT_SPACING
		)


func _get_alive_combat_enemies() -> Array[EnemyUnit]:
	var result: Array[EnemyUnit] = []

	for enemy_unit in active_combat_enemies:
		if enemy_unit == null:
			continue

		if enemy_unit.is_dead():
			continue

		result.append(
			enemy_unit
		)

	return result


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

	parata_dei_condannati = CardDatabase.get_card(
		CardDatabase.PARATA_DEI_CONDANNATI
	)

	esecuzione = CardDatabase.get_card(
		CardDatabase.ESECUZIONE
	)

	active_cards = [
		mannaia_del_carnefice,
		chiodo_del_giudizio,
		maglio_della_pena,
		bende_del_viandante,
		catena_del_contrappasso,
		parata_dei_condannati,
		esecuzione
	]


func _setup_enemies() -> void:
	enemy_units.clear()
	active_combat_enemies.clear()

	enemy_combat_groups.clear()
	enemy_rooms.clear()

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

		enemy_combat_groups[
			enemy_unit
		] = encounter_enemy.combat_group_id

		enemy_rooms[
			enemy_unit
		] = encounter_enemy.room_id

		enemy_unit.position = (
			_get_spawn_position(
				encounter_enemy.room_id,
				encounter_enemy.spawn_cell
			)
		)


func _get_spawn_position(
	room_id: String,
	spawn_cell: Vector2i
) -> Vector2:
	var room_center: Vector2 = _get_room_center(
		room_id
	)

	var offset := Vector2(
		float(spawn_cell.x - 5) * 36.0,
		float(spawn_cell.y - 4) * 28.0
	)

	return room_center + offset


func _get_room_center(
	room_id: String
) -> Vector2:
	match room_id:
		RoomDatabase.LIMBO_ROOM_A:
			return Vector2(300.0, 300.0)

		RoomDatabase.LIMBO_ROOM_B:
			return Vector2(900.0, 300.0)

		_:
			return Vector2(500.0, 300.0)


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

			if event.keycode == KEY_TAB:
				_select_next_enemy()
				return

	if not _is_combat_mode():
		return

	if enemy_is_acting:
		return

	if event is InputEventMouseButton:
		if (
			event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed
		):
			_select_enemy_at_screen_position(
				event.position
			)


func _select_enemy_at_screen_position(
	screen_position: Vector2
) -> void:
	var closest_enemy: EnemyUnit = null
	var closest_distance: float = SELECTION_RADIUS

	for enemy_unit in active_combat_enemies:
		if enemy_unit == null:
			continue

		if enemy_unit.is_dead():
			continue

		var enemy_screen_position: Vector2 = (
			enemy_unit
			.get_global_transform_with_canvas()
			.origin
		)

		var distance: float = (
			enemy_screen_position.distance_to(
				screen_position
			)
		)

		if distance <= closest_distance:
			closest_distance = distance
			closest_enemy = enemy_unit

	if closest_enemy != null:
		_select_enemy(
			closest_enemy
		)


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


func _select_next_enemy() -> void:
	if not _is_combat_mode():
		return

	var alive_enemies: Array[EnemyUnit] = (
		_get_alive_combat_enemies()
	)

	if alive_enemies.is_empty():
		return

	var current_index: int = alive_enemies.find(
		selected_enemy
	)

	current_index += 1

	if current_index >= alive_enemies.size():
		current_index = 0

	_select_enemy(
		alive_enemies[
			current_index
		]
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


func _is_card_available(
	card: CardData
) -> bool:
	if card == null:
		return false

	if not _is_combat_mode():
		return false

	if player_is_dead:
		return false

	if enemy_is_acting:
		return false

	if player_actions_remaining < card.action_cost:
		return false

	if (
		card.effort_generated > 0
		and player_effort + card.effort_generated > PLAYER_MAX_EFFORT
	):
		return false

	if card.is_reaction():
		return player_reaction_block <= 0

	if card.healing > 0:
		return (
			player_hp < PLAYER_MAX_HP
			or (
				card.effort_generated < 0
				and player_effort > 0
			)
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
		card.uses_body_target()
		and player_statuses.is_blinded()
	):
		return false

	if card.low_vitality_required_ratio > 0.0:
		var target_ratio: float = (
			float(
				selected_enemy.get_hp()
			)
			/ float(
				maxi(
					selected_enemy.get_max_hp(),
					1
				)
			)
		)

		if target_ratio > card.low_vitality_required_ratio:
			return false

	return true


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

	if card.is_reaction():
		_use_reaction_card(
			card
		)

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

	if card.uses_body_target():
		var target_part: String = (
			_get_selected_body_part()
		)

		target_enemy.take_part_damage(
			target_part,
			modified_damage
		)
	else:
		target_enemy.take_vitality_damage(
			modified_damage
		)

	if target_enemy.is_dead():
		_handle_enemy_death(
			target_enemy
		)

		if _all_combat_enemies_dead():
			return
	else:
		_apply_card_effects(
			card,
			target_enemy
		)

	_play_card_impact_motion(
		target_enemy
	)

	_apply_card_effort(
		card
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
		var status_chance: float = (
			_get_status_chance(
				card,
				target_enemy
			)
		)

		if randf() < status_chance:
			target_enemy.status_manager.add_status(
				card.status_to_apply,
				card.status_duration,
				card.status_stacks
			)

	if card.fracture_selected_part:
		var target_part: String = (
			_get_selected_body_part()
		)

		var fracture_chance: float = (
			_get_fracture_chance(
				target_enemy,
				target_part
			)
		)

		if target_enemy.status_manager.has_status(
			StatusManager.MARKED
		):
			fracture_chance += 0.10

		if randf() < clamp(
			fracture_chance,
			0.0,
			1.0
		):
			target_enemy.apply_fracture(
				target_part
			)


func _get_status_chance(
	card: CardData,
	target_enemy: EnemyUnit
) -> float:
	var chance: float = card.status_chance

	if target_enemy.status_manager.has_status(
		StatusManager.MARKED
	):
		chance += card.marked_status_bonus

	if (
		not card.conditional_status_name.is_empty()
		and target_enemy.status_manager.has_status(
			card.conditional_status_name
		)
	):
		chance += card.conditional_status_bonus

	return clamp(
		chance,
		0.0,
		1.0
	)


func _get_fracture_chance(
	target_enemy: EnemyUnit,
	target_part: String
) -> float:
	if target_part.is_empty():
		return 0.0

	var max_integrity: int = (
		target_enemy.get_part_max_integrity(
			target_part
		)
	)

	if max_integrity <= 0:
		return 0.0

	var current_integrity: int = (
		target_enemy.get_part_integrity(
			target_part
		)
	)

	var integrity_ratio: float = (
		float(current_integrity)
		/ float(max_integrity)
	)

	if integrity_ratio <= 0.25:
		return 0.40

	if integrity_ratio <= 0.50:
		return 0.25

	return 0.10


func _use_healing_card(
	card: CardData
) -> void:
	player_hp = mini(
		player_hp + card.healing,
		PLAYER_MAX_HP
	)

	_apply_card_effort(
		card
	)

	_update_ui()
	_finish_player_action(
		card.action_cost
	)


func _use_reaction_card(
	card: CardData
) -> void:
	player_reaction_block = maxi(
		player_reaction_block,
		card.reaction_block
	)

	if card.reaction_effort_relief > 0:
		player_effort = maxi(
			player_effort - card.reaction_effort_relief,
			0
		)

	_apply_card_effort(
		card
	)

	_update_ui()
	_finish_player_action(
		card.action_cost
	)


func _apply_card_effort(
	card: CardData
) -> void:
	player_effort = clampi(
		player_effort + card.effort_generated,
		0,
		PLAYER_MAX_EFFORT
	)


func _finish_player_action(
	action_cost: int
) -> void:
	player_actions_remaining -= action_cost

	if player_actions_remaining < 0:
		player_actions_remaining = 0

	_update_ui()

	if player_actions_remaining <= 0:
		if not _end_player_activation():
			return

		_start_enemy_phase()


func _begin_player_activation() -> bool:
	player_reaction_block = 0

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

	player_effort = maxi(
		player_effort - PLAYER_EFFORT_RECOVERY,
		0
	)

	var actions_for_turn: int = PLAYER_MAX_ACTIONS

	if player_effort >= PLAYER_TIRED_EFFORT:
		actions_for_turn -= 1

	if player_statuses.is_slowed():
		actions_for_turn -= 1

	if player_statuses.is_immobilized():
		actions_for_turn = mini(
			actions_for_turn,
			1
		)

	if bool(
		result.get(
			"stunned",
			false
		)
	):
		actions_for_turn = mini(
			actions_for_turn,
			1
		)

	player_actions_remaining = maxi(
		actions_for_turn,
		1
	)

	enemy_is_acting = false

	_update_ui()
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

	enemy_is_acting = true
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

		if enemy_unit == null:
			continue

		if enemy_unit.is_dead():
			continue

		_run_enemy_turn(
			enemy_unit
		)

		return

	enemy_is_acting = false
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

	var enemy_is_stunned: bool = bool(
		activation.get(
			"stunned",
			false
		)
	)

	if enemy_is_stunned:
		_finish_single_enemy_turn(
			enemy_unit
		)
		return

	var ai_action: Dictionary = (
		EnemyAISystem.choose_action(
			enemy_unit,
			true
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


func _execute_chain_pull_action(
	enemy_unit: EnemyUnit,
	action: Dictionary
) -> void:
	var status_name: String = str(
		action.get(
			"status",
			""
		)
	)

	if not status_name.is_empty():
		player_statuses.add_status(
			status_name,
			int(
				action.get(
					"duration",
					1
				)
			),
			1
		)

	_apply_enemy_damage(
		int(
			action.get(
				"damage",
				0
			)
		)
	)

	_play_enemy_action_motion(
		enemy_unit
	)

	if player_is_dead:
		return

	_finish_single_enemy_turn(
		enemy_unit
	)


func _execute_ranged_action(
	enemy_unit: EnemyUnit,
	action: Dictionary
) -> void:
	_apply_enemy_damage(
		int(
			action.get(
				"damage",
				0
			)
		)
	)

	_play_enemy_action_motion(
		enemy_unit
	)

	if player_is_dead:
		return

	_finish_single_enemy_turn(
		enemy_unit
	)


func _enemy_attack(
	enemy_unit: EnemyUnit
) -> void:
	_apply_enemy_damage(
		enemy_unit.get_attack_damage()
	)

	_play_enemy_action_motion(
		enemy_unit
	)

	if player_is_dead:
		return

	_finish_single_enemy_turn(
		enemy_unit
	)


func _apply_enemy_damage(
	damage: int
) -> void:
	if player_statuses.consume_marked():
		damage = roundi(
			damage * 1.25
		)

	if player_reaction_block > 0:
		damage = maxi(
			damage - player_reaction_block,
			0
		)

		player_reaction_block = 0

	player_hp = maxi(
		player_hp - damage,
		0
	)

	_update_ui()

	if player_hp <= 0:
		_player_died()


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
		var timer := get_tree().create_timer(
			ENEMY_TURN_DELAY
		)

		timer.timeout.connect(
			_run_next_enemy_turn
		)


func _handle_enemy_death(
	enemy_unit: EnemyUnit
) -> void:
	enemy_unit.visible = false
	enemy_unit.scale = Vector2.ONE

	if selected_enemy == enemy_unit:
		selected_enemy = (
			_get_first_alive_combat_enemy()
		)

		selected_body_part_index = 0

	_update_enemy_selection_visuals()

	if _all_combat_enemies_dead():
		_end_combat()

	_update_ui()


func _get_first_alive_combat_enemy() -> EnemyUnit:
	for enemy_unit in active_combat_enemies:
		if enemy_unit == null:
			continue

		if not enemy_unit.is_dead():
			return enemy_unit

	return null


func _all_combat_enemies_dead() -> bool:
	if active_combat_enemies.is_empty():
		return true

	for enemy_unit in active_combat_enemies:
		if enemy_unit == null:
			continue

		if not enemy_unit.is_dead():
			return false

	return true


func _all_encounter_enemies_dead() -> bool:
	if enemy_units.is_empty():
		return true

	for enemy_unit in enemy_units:
		if enemy_unit == null:
			continue

		if not enemy_unit.is_dead():
			return false

	return true


func _end_combat() -> void:
	noise_system.clear_noise()
	noise_system.clear_world_noise()
	_enter_exploration_mode()


func _player_died() -> void:
	player_is_dead = true
	enemy_is_acting = false

	player.velocity = Vector2.ZERO
	card_bar.visible = false

	_update_ui()


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
		+ str(player_hp)
		+ "/"
		+ str(PLAYER_MAX_HP)
	)

	var reaction_text: String = "-"

	if player_reaction_block > 0:
		reaction_text = (
			"-"
			+ str(player_reaction_block)
			+ " danno"
		)

	actions_label.text = (
		"PA: "
		+ str(player_actions_remaining)
		+ "/"
		+ str(PLAYER_MAX_ACTIONS)
		+ "  Sforzo: "
		+ str(player_effort)
		+ "/"
		+ str(PLAYER_MAX_EFFORT)
		+ "  Reazione: "
		+ reaction_text
	)

	if (
		_is_combat_mode()
		and selected_enemy != null
		and not selected_enemy.is_dead()
	):
		enemy_hp_label.text = (
			selected_enemy.get_enemy_name()
			+ ": "
			+ str(selected_enemy.get_hp())
			+ "/"
			+ str(selected_enemy.get_max_hp())
			+ " Vitalita"
		)

		var selected_part: String = (
			_get_selected_body_part()
		)

		if selected_part.is_empty():
			target_part_label.text = (
				"Mira carte: -"
			)
		else:
			target_part_label.text = (
				"Mira carte Q/E: "
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
			"Mira carte: -"
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

	elif enemy_is_acting:
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
		if current_room_id.is_empty():
			state_label.text = (
				"ESPLORAZIONE"
			)
		else:
			state_label.text = (
				"ESPLORAZIONE - "
				+ current_room_id
			)


func _count_alive_combat_enemies() -> int:
	var count: int = 0

	for enemy_unit in active_combat_enemies:
		if enemy_unit == null:
			continue

		if not enemy_unit.is_dead():
			count += 1

	return count


func _play_card_impact_motion(
	target_enemy: EnemyUnit
) -> void:
	if target_enemy == null:
		return

	if target_enemy.is_dead():
		return

	var original_position: Vector2 = target_enemy.position
	var tween: Tween = create_tween()

	tween.tween_property(
		target_enemy,
		"position",
		original_position + Vector2(16.0, 0.0),
		0.06
	)

	tween.tween_property(
		target_enemy,
		"position",
		original_position,
		0.08
	)


func _play_enemy_action_motion(
	enemy_unit: EnemyUnit
) -> void:
	if enemy_unit == null:
		return

	if enemy_unit.is_dead():
		return

	var original_position: Vector2 = enemy_unit.position
	var tween: Tween = create_tween()

	tween.tween_property(
		enemy_unit,
		"position",
		original_position + Vector2(-18.0, 0.0),
		0.08
	)

	tween.tween_property(
		enemy_unit,
		"position",
		original_position,
		0.10
	)
