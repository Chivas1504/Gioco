extends Control

const SCREEN_MENU = "menu"
const SCREEN_COMBAT = "combat"
const SCREEN_REWARD = "reward"
const SCREEN_SAFE = "safe"
const SAFE_POPUP_NONE = ""
const SAFE_POPUP_COLLECTION = "collection"
const SAFE_POPUP_MAP = "map"
const SAFE_POPUP_SETTINGS = "settings"
const SAFE_POPUP_LEVEL = "level"
const BASE_WINDOW_SIZE = Vector2i(1280, 720)
const MIN_WINDOW_SIZE = Vector2i(960, 540)
const CARD_WIDTH = 190
const CARD_HEIGHT = 260
const CARD_GRID_COLUMNS = 3
const HAND_CARD_WIDTH = 118
const HAND_CARD_HEIGHT = 170
const HAND_CARD_COLUMNS = 12
const HAND_CARD_ZOOM = 1.12
const HAND_CARD_MIN_SCALE = 0.62
const STACK_CARD_OFFSET = Vector2(22, 16)
const STACK_CARD_MIN_SCALE = 0.45
const STACK_CARD_PREVIEW_WIDTH = 230
const STACK_CARD_PREVIEW_HEIGHT = 150

var run_state = RunState.new()
var combat_state = CombatState.new()
var log_lines: Array = []
var screen_mode = SCREEN_MENU
var has_current_run = false
var safe_popup_mode = SAFE_POPUP_NONE
var reward_offers: Array = []
var reward_card_claimed = false
var shop_card_offers: Array = []
var shop_card_offers_generated = false

var screen_title: Label
var fullscreen_button: Button
var player_label: Label
var enemy_label: Label
var intent_label: Label
var log_label: RichTextLabel
var cards_title: Label
var card_grid: GridContainer
var hand_spacer: Control
var combat_action_panel: VBoxContainer
var safe_panel: VBoxContainer
var action_scroll: ScrollContainer
var end_intent_button: Button
var pass_turn_button: Button
var hover_card_preview: PanelContainer
var defeat_snapshot_saved = false

func _ready() -> void:
	_configure_game_window()
	_build_ui()
	_show_start_menu()
	_refresh_ui()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and card_grid != null:
		_refresh_ui()


func _configure_game_window() -> void:
	var game_window = get_window()
	game_window.min_size = MIN_WINDOW_SIZE
	game_window.content_scale_size = BASE_WINDOW_SIZE
	game_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	game_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	game_window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	game_window.unresizable = false
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)


func _build_ui() -> void:
	var background = ColorRect.new()
	background.color = Color(0.07, 0.06, 0.055)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	root.offset_left = 24
	root.offset_top = 20
	root.offset_right = -24
	root.offset_bottom = -20
	add_child(root)

	var title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	root.add_child(title_row)

	screen_title = Label.new()
	screen_title.text = "Inferno Roguelike - Combat Prototype V0.1"
	screen_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen_title.add_theme_font_size_override("font_size", 24)
	title_row.add_child(screen_title)

	fullscreen_button = Button.new()
	fullscreen_button.text = "Schermo intero"
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	title_row.add_child(fullscreen_button)

	var status_row = VBoxContainer.new()
	status_row.add_theme_constant_override("separation", 4)
	root.add_child(status_row)

	player_label = Label.new()
	player_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	player_label.add_theme_font_size_override("font_size", 18)
	status_row.add_child(player_label)

	enemy_label = Label.new()
	enemy_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_label.add_theme_font_size_override("font_size", 18)
	status_row.add_child(enemy_label)

	intent_label = Label.new()
	intent_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intent_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intent_label.add_theme_font_size_override("font_size", 18)
	status_row.add_child(intent_label)

	var content_row = HBoxContainer.new()
	content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 16)
	root.add_child(content_row)

	var left_column = VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.size_flags_stretch_ratio = 2.0
	left_column.add_theme_constant_override("separation", 10)
	content_row.add_child(left_column)

	cards_title = Label.new()
	cards_title.text = "Carte build disponibili"
	cards_title.add_theme_font_size_override("font_size", 18)
	left_column.add_child(cards_title)

	hand_spacer = Control.new()
	hand_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_child(hand_spacer)

	card_grid = GridContainer.new()
	card_grid.columns = 4
	card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_grid.add_theme_constant_override("h_separation", 10)
	card_grid.add_theme_constant_override("v_separation", 10)
	left_column.add_child(card_grid)

	combat_action_panel = VBoxContainer.new()
	combat_action_panel.custom_minimum_size = Vector2(280, 0)
	combat_action_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	combat_action_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	combat_action_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	combat_action_panel.add_theme_constant_override("separation", 10)
	combat_action_panel.visible = false
	content_row.add_child(combat_action_panel)

	end_intent_button = Button.new()
	end_intent_button.text = "Risolvi intento nemico"
	end_intent_button.custom_minimum_size = Vector2(260, 52)
	end_intent_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	end_intent_button.visible = false
	end_intent_button.pressed.connect(_on_end_intent_pressed)
	combat_action_panel.add_child(end_intent_button)

	pass_turn_button = Button.new()
	pass_turn_button.text = "Passa turno"
	pass_turn_button.custom_minimum_size = Vector2(260, 46)
	pass_turn_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pass_turn_button.visible = false
	pass_turn_button.pressed.connect(_on_pass_stack_turn_pressed)
	combat_action_panel.add_child(pass_turn_button)

	action_scroll = ScrollContainer.new()
	action_scroll.custom_minimum_size = Vector2(300, 0)
	action_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_scroll.size_flags_stretch_ratio = 1.0
	action_scroll.horizontal_scroll_mode = 0
	content_row.add_child(action_scroll)

	safe_panel = VBoxContainer.new()
	safe_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	safe_panel.add_theme_constant_override("separation", 8)
	action_scroll.add_child(safe_panel)

	log_label = RichTextLabel.new()
	log_label.custom_minimum_size = Vector2(0, 160)
	log_label.fit_content = true
	log_label.scroll_following = true
	root.add_child(log_label)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.alt_pressed and event.keycode == KEY_ENTER):
			_toggle_fullscreen()


func _toggle_fullscreen() -> void:
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_refresh_fullscreen_button()


func _refresh_fullscreen_button() -> void:
	if fullscreen_button == null:
		return
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		fullscreen_button.text = "Finestra"
	else:
		fullscreen_button.text = "Schermo intero"


func _show_start_menu() -> void:
	screen_mode = SCREEN_MENU


func _start_new_run_from_menu() -> void:
	run_state.start_new_run(true)
	has_current_run = true
	safe_popup_mode = SAFE_POPUP_NONE
	reward_offers = []
	reward_card_claimed = false
	shop_card_offers = []
	shop_card_offers_generated = false
	log_lines = []
	_start_new_combat()
	_push_log("La run comincia nel buio: sopravvivi al primo scontro, poi raggiungerai il Falò / Shop.")
	_refresh_ui()


func _resume_current_run() -> void:
	if not has_current_run:
		return
	if combat_state.ended and combat_state.victory:
		if combat_state.rewards_claimed:
			screen_mode = SCREEN_SAFE
		else:
			screen_mode = SCREEN_REWARD
	else:
		screen_mode = SCREEN_COMBAT
	_refresh_ui()


func _start_new_combat(ignore_forced_shadow: bool = false) -> void:
	defeat_snapshot_saved = false
	reward_offers = []
	reward_card_claimed = false
	shop_card_offers = []
	shop_card_offers_generated = false
	if run_state.can_start_forced_shadow_encounter() and not ignore_forced_shadow:
		_start_shadow_combat(true)
		return
	var enemy = GameDatabase.make_grid_enemy(run_state.current_node, run_state.get_world_level(), run_state.active_class)
	combat_state.start_combat(run_state, enemy)
	screen_mode = SCREEN_COMBAT


func _start_shadow_combat(second_encounter: bool) -> void:
	defeat_snapshot_saved = false
	reward_offers = []
	reward_card_claimed = false
	shop_card_offers = []
	shop_card_offers_generated = false
	var enemy = GameDatabase.make_shadow_boss(run_state.shadow_memory, run_state.fear, second_encounter)
	combat_state.start_combat(run_state, enemy)
	if second_encounter:
		_push_log("La tua Ombra ritorna. Questa volta non puoi fuggire.")
	else:
		_push_log("La tua Ombra ti aspetta con le anime perdute.")
	screen_mode = SCREEN_COMBAT


func _refresh_ui() -> void:
	_refresh_fullscreen_button()
	_clear_card_preview()
	if screen_mode == SCREEN_MENU:
		hand_spacer.visible = false
		combat_action_panel.visible = false
		end_intent_button.visible = false
		pass_turn_button.visible = false
		log_label.visible = true
		action_scroll.visible = true
		_render_start_menu()
		log_label.text = "\n".join(log_lines)
		return

	player_label.text = "PG Lv %d | Classe: %s | Vita %d/%d | Stamina %d/%d | Anime %d | Sangue %d | Paura %d" % [
		run_state.player_level,
		_get_class_display_text(run_state.active_class),
		run_state.health,
		run_state.max_health,
		run_state.stamina,
		run_state.max_stamina,
		run_state.get_material("anime"),
		run_state.get_material("sangue"),
		run_state.fear,
	]
	if screen_mode == SCREEN_SAFE:
		enemy_label.text = "Nodo: %s (%s)" % [run_state.get_current_node_name(), run_state.get_current_node_type()]
		intent_label.text = "Posizione: %d,%d" % [
			run_state.map_position.x,
			run_state.map_position.y,
		]
	elif screen_mode == SCREEN_REWARD:
		enemy_label.text = "Nemico sconfitto: %s" % String(combat_state.enemy.get("name", "Nemico"))
		intent_label.text = "Raccogli le ricompense. Puoi scegliere fino a 1 carta."
	else:
		enemy_label.text = "%s | Vita %d/%d | Veleno %d | Bruciatura %d | Sangue perso %d | Marchio %s" % [
			combat_state.enemy.get("name", "Nemico"),
			combat_state.enemy.get("health", 0),
			combat_state.enemy.get("max_health", 0),
			combat_state.enemy.get("poison", 0),
			combat_state.enemy.get("burn", 0),
			combat_state.enemy.get("bleed", 0),
			"si" if bool(combat_state.enemy.get("marked", false)) else "no",
		]
		var intent = combat_state.current_intent()
		if intent.get("kind") == "attack":
			intent_label.text = "Intento: %s, %d danni" % [intent.get("name", ""), intent.get("damage", 0)]
		elif intent.get("kind") == "buff":
			intent_label.text = "Intento: %s, +%d forza" % [intent.get("name", ""), intent.get("strength", 0)]
		else:
			intent_label.text = "Intento: -"
		if combat_state.has_staged_cards():
			intent_label.text += "\nPila: %s" % _format_staged_stack()

	if screen_mode == SCREEN_SAFE:
		screen_title.text = "Falò / Shop"
		hand_spacer.visible = false
		combat_action_panel.visible = false
		end_intent_button.visible = false
		pass_turn_button.visible = false
		cards_title.visible = false
		action_scroll.visible = false
		log_label.visible = false
		_render_safe_summary()
	elif screen_mode == SCREEN_REWARD:
		screen_title.text = "Ricompensa"
		hand_spacer.visible = false
		combat_action_panel.visible = false
		end_intent_button.visible = false
		pass_turn_button.visible = false
		cards_title.visible = false
		action_scroll.visible = false
		log_label.visible = false
		_render_reward_summary()
	else:
		screen_title.text = "Combattimento"
		hand_spacer.visible = true
		combat_action_panel.visible = true
		end_intent_button.visible = true
		end_intent_button.disabled = combat_state.ended
		pass_turn_button.visible = combat_state.can_pass_stack_turn()
		pass_turn_button.disabled = not combat_state.can_pass_stack_turn()
		if combat_state.has_staged_cards():
			end_intent_button.text = "Risolvi pila (%d)" % combat_state.get_staged_card_count()
		else:
			end_intent_button.text = "Gioca una carta"
			end_intent_button.disabled = true
		cards_title.visible = false
		action_scroll.visible = false
		log_label.visible = false
		_render_combat_stack_area()
		_render_cards()
	_render_safe_panel()
	log_label.text = "\n".join(log_lines) if log_label.visible else ""


func _render_start_menu() -> void:
	screen_title.text = "Inferno Roguelike"
	player_label.text = ""
	enemy_label.text = ""
	intent_label.text = ""
	combat_action_panel.visible = false
	cards_title.visible = true
	end_intent_button.visible = false
	pass_turn_button.visible = false
	cards_title.text = "Menu"
	_render_menu_buttons()
	_render_menu_panel()


func _render_menu_buttons() -> void:
	card_grid.columns = 1
	card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for child in card_grid.get_children():
		child.queue_free()

	var new_run_button = Button.new()
	new_run_button.custom_minimum_size = Vector2(260, 70)
	new_run_button.text = "Nuova run"
	new_run_button.pressed.connect(_start_new_run_from_menu)
	card_grid.add_child(new_run_button)

	var continue_button = Button.new()
	continue_button.custom_minimum_size = Vector2(260, 70)
	continue_button.text = "Run corrente"
	continue_button.disabled = not has_current_run
	continue_button.pressed.connect(_resume_current_run)
	card_grid.add_child(continue_button)


func _render_menu_panel() -> void:
	for child in safe_panel.get_children():
		child.queue_free()

	var title = Label.new()
	title.text = "Prototipo V0.1"
	title.add_theme_font_size_override("font_size", 18)
	safe_panel.add_child(title)

	var description = Label.new()
	description.text = "Avvia una nuova run o torna alla run corrente della sessione."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	safe_panel.add_child(description)

	if run_state.has_shadow():
		var shadow = Label.new()
		shadow.text = "Ombra presente: %d anime perdute." % int(run_state.shadow_memory.get("lost_souls", 0))
		shadow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		safe_panel.add_child(shadow)


func _render_cards() -> void:
	card_grid.columns = _get_combat_card_columns()
	card_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card_grid.size_flags_vertical = Control.SIZE_SHRINK_END
	card_grid.add_theme_constant_override("h_separation", 6)
	card_grid.add_theme_constant_override("v_separation", 6)
	for child in card_grid.get_children():
		child.queue_free()

	var hand_card_ids = combat_state.get_hand_card_ids()
	var hand_scale = _get_hand_card_scale(hand_card_ids.size())
	var hand_card_size = Vector2(HAND_CARD_WIDTH, HAND_CARD_HEIGHT) * hand_scale
	for card_id in hand_card_ids:
		var card = GameDatabase.get_card(card_id)
		var button = Button.new()
		var cost = combat_state.get_card_cost_for_current_intent(card_id)
		button.custom_minimum_size = hand_card_size
		button.size = hand_card_size
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.pivot_offset = Vector2(hand_card_size.x / 2.0, hand_card_size.y)
		button.text = _get_hand_card_display_text(card_id, cost)
		button.tooltip_text = "Classe: %s" % _get_class_display_text(String(card.get("class_id", CardRules.CLASS_NEUTRAL)))
		button.disabled = not combat_state.can_play_card(card_id)
		_apply_card_button_style(button, card)
		button.mouse_entered.connect(_on_hand_card_mouse_entered.bind(card_id, button))
		button.mouse_exited.connect(_on_hand_card_mouse_exited.bind(button))
		button.pressed.connect(_on_card_pressed.bind(card_id))
		card_grid.add_child(button)


func _render_combat_stack_area() -> void:
	for child in hand_spacer.get_children():
		child.queue_free()
	if screen_mode != SCREEN_COMBAT or not combat_state.has_staged_cards():
		return

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	hand_spacer.add_child(center)

	var staged_cards = combat_state.get_staged_stack_entries()
	var stack_scale = _get_stack_card_scale(staged_cards.size())
	var stack_card_size = Vector2(CARD_WIDTH, CARD_HEIGHT) * stack_scale
	var stack_offset = STACK_CARD_OFFSET * stack_scale
	var stack_board = Control.new()
	stack_board.custom_minimum_size = Vector2(
		stack_card_size.x + stack_offset.x * max(0, staged_cards.size() - 1),
		stack_card_size.y + stack_offset.y * max(0, staged_cards.size() - 1)
	)
	center.add_child(stack_board)

	for index in range(staged_cards.size()):
		var entry: Dictionary = staged_cards[index]
		var stack_card = Button.new()
		stack_card.custom_minimum_size = stack_card_size
		stack_card.size = stack_card_size
		stack_card.position = stack_offset * index
		stack_card.z_index = index
		stack_card.focus_mode = Control.FOCUS_NONE
		stack_card.mouse_filter = Control.MOUSE_FILTER_STOP
		if String(entry.get("owner", "")) == "enemy":
			stack_card.text = _get_enemy_stack_card_display_text(entry, true)
			stack_card.tooltip_text = _get_enemy_stack_card_display_text(entry, false)
			_apply_enemy_stack_card_style(stack_card)
		else:
			var card_id = String(entry.get("card_id", ""))
			var card = GameDatabase.get_card(card_id)
			stack_card.text = _get_stack_player_card_display_text(card_id)
			stack_card.tooltip_text = _get_card_display_text(card_id, "in pila", "Pronta")
			_apply_card_button_style(stack_card, card)
		stack_card.mouse_entered.connect(_on_stack_card_mouse_entered.bind(entry, stack_card))
		stack_card.mouse_exited.connect(_on_stack_card_mouse_exited.bind(stack_card, index))
		stack_board.add_child(stack_card)


func _render_safe_summary() -> void:
	card_grid.columns = 1
	card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_grid.add_theme_constant_override("h_separation", 10)
	card_grid.add_theme_constant_override("v_separation", 10)
	for child in card_grid.get_children():
		child.queue_free()

	if safe_popup_mode != SAFE_POPUP_NONE:
		_render_safe_popup_page()
		return

	_render_shop_dashboard()


func _render_reward_summary() -> void:
	_ensure_reward_offers()
	card_grid.columns = 1
	card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_grid.add_theme_constant_override("h_separation", 10)
	card_grid.add_theme_constant_override("v_separation", 10)
	for child in card_grid.get_children():
		child.queue_free()
	for child in safe_panel.get_children():
		child.queue_free()

	var popup_center = CenterContainer.new()
	popup_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_grid.add_child(popup_center)

	var popup_panel = PanelContainer.new()
	popup_panel.custom_minimum_size = Vector2(920, 560)
	popup_center.add_child(popup_panel)

	var popup_content = VBoxContainer.new()
	popup_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	popup_content.add_theme_constant_override("separation", 12)
	popup_panel.add_child(popup_content)

	var loot_title = Label.new()
	loot_title.text = "Ricompense"
	loot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loot_title.add_theme_font_size_override("font_size", 24)
	popup_content.add_child(loot_title)

	var soul_reward = _get_visible_soul_reward()
	var rewards_list = VBoxContainer.new()
	rewards_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rewards_list.add_theme_constant_override("separation", 6)
	popup_content.add_child(rewards_list)

	var loot_info = Label.new()
	loot_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loot_info.text = "Anime: %d" % soul_reward
	rewards_list.add_child(loot_info)

	if bool(combat_state.enemy.get("is_shadow", false)):
		var shadow_info = Label.new()
		shadow_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		shadow_info.text = "Ombra: recupero anime perdute e potenziamento speciale."
		rewards_list.add_child(shadow_info)

	var card_title = Label.new()
	card_title.text = "Scegli fino a 1 carta"
	card_title.add_theme_font_size_override("font_size", 18)
	popup_content.add_child(card_title)

	var progress = Label.new()
	progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress.text = "Carta scelta: %s" % ("si" if reward_card_claimed else "nessuna")
	popup_content.add_child(progress)

	var reward_scroll = ScrollContainer.new()
	reward_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reward_scroll.horizontal_scroll_mode = 0
	popup_content.add_child(reward_scroll)

	var reward_center = CenterContainer.new()
	reward_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reward_scroll.add_child(reward_center)

	var reward_grid = GridContainer.new()
	reward_grid.columns = CARD_GRID_COLUMNS
	reward_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	reward_grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	reward_grid.add_theme_constant_override("h_separation", 28)
	reward_grid.add_theme_constant_override("v_separation", 24)
	reward_center.add_child(reward_grid)

	for card_id in reward_offers:
		var card = GameDatabase.get_card(card_id)
		var reward_button = Button.new()
		reward_button.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		reward_button.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		reward_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		reward_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		reward_button.text = _get_card_display_text(card_id, "ricompensa", "Scegli")
		reward_button.disabled = reward_card_claimed
		_apply_card_button_style(reward_button, card)
		reward_button.pressed.connect(_on_reward_card_pressed.bind(card_id))
		reward_grid.add_child(reward_button)

	var claim_button = Button.new()
	claim_button.text = "Raccogli ricompense"
	claim_button.disabled = combat_state.rewards_claimed
	claim_button.custom_minimum_size = Vector2(280, 54)
	claim_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	claim_button.pressed.connect(_on_claim_rewards_pressed)
	popup_content.add_child(claim_button)


func _get_visible_soul_reward() -> int:
	var soul_reward = int(combat_state.enemy.get("soul_reward", 0))
	if bool(combat_state.enemy.get("is_shadow", false)):
		soul_reward += int(combat_state.enemy.get("lost_souls", 0))
	return soul_reward


func _render_shop_dashboard() -> void:
	_ensure_shop_card_offers()

	var dashboard = HBoxContainer.new()
	dashboard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dashboard.add_theme_constant_override("separation", 12)
	card_grid.add_child(dashboard)

	var left_rail = VBoxContainer.new()
	left_rail.custom_minimum_size = Vector2(64, 0)
	left_rail.add_theme_constant_override("separation", 8)
	dashboard.add_child(left_rail)
	_add_safe_nav_button(left_rail, "C", "Collezione / loadout", SAFE_POPUP_COLLECTION)
	_add_safe_nav_button(left_rail, "M", "Mappa", SAFE_POPUP_MAP)
	_add_safe_nav_button(left_rail, "I", "Impostazioni", SAFE_POPUP_SETTINGS)

	var shop = HBoxContainer.new()
	shop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop.add_theme_constant_override("separation", 18)
	dashboard.add_child(shop)

	_add_unified_shop_cards(shop)
	_add_unified_shop_side(shop)


func _ensure_shop_card_offers() -> void:
	if not shop_card_offers_generated:
		shop_card_offers = GameDatabase.get_shop_card_offers(run_state.collection, run_state.active_class, run_state.acquired_classes)
		shop_card_offers_generated = true


func _add_unified_shop_cards(parent: Control) -> void:
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.1
	left.add_theme_constant_override("separation", 10)
	parent.add_child(left)

	var title = Label.new()
	title.text = "Carte in vendita"
	title.add_theme_font_size_override("font_size", 20)
	left.add_child(title)

	var hint = Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = "Compra nuove carte con le anime. Il potenziamento avviene solo quando sali di livello."
	left.add_child(hint)

	var grid_center = CenterContainer.new()
	grid_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(grid_center)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	grid_center.add_child(grid)

	if shop_card_offers.is_empty():
		var empty = Label.new()
		empty.text = "Nessuna carta in vendita."
		grid.add_child(empty)
		return

	for card_id in shop_card_offers:
		var card = GameDatabase.get_card(card_id)
		if card.is_empty():
			continue
		var cost = _get_shop_card_cost(card)
		var card_button = Button.new()
		card_button.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		card_button.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		card_button.text = _get_card_display_text(card_id, "%d anime" % cost, "Compra")
		card_button.disabled = run_state.get_material("anime") < cost or run_state.collection.size() >= CardRules.COLLECTION_MAX
		_apply_card_button_style(card_button, card)
		card_button.pressed.connect(_on_shop_card_buy_pressed.bind(card_id))
		grid.add_child(card_button)


func _get_shop_card_cost(card: Dictionary) -> int:
	match String(card.get("rarity", CardRules.RARITY_COMMON)):
		CardRules.RARITY_COMMON:
			return 35
		CardRules.RARITY_UNCOMMON:
			return 60
		CardRules.RARITY_RARE:
			return 95
		CardRules.RARITY_LEGENDARY:
			return 160
		_:
			return 50


func _add_unified_shop_side(parent: Control) -> void:
	var side = VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.size_flags_stretch_ratio = 1.0
	side.add_theme_constant_override("separation", 18)
	parent.add_child(side)

	_add_unified_level_button(side)
	_add_unified_consumables(side)


func _add_unified_level_button(parent: VBoxContainer) -> void:
	var level_area = VBoxContainer.new()
	level_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_area.add_theme_constant_override("separation", 8)
	parent.add_child(level_area)

	var title = Label.new()
	title.text = "Livello"
	title.add_theme_font_size_override("font_size", 20)
	level_area.add_child(title)

	var info = Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.text = "Costo: %d anime. Dopo l'acquisto scegli nel popup quale carta della collezione potenziare." % run_state.next_level_cost()
	level_area.add_child(info)

	var level_button = Button.new()
	level_button.text = "Sali di livello"
	level_button.custom_minimum_size = Vector2(260, 56)
	level_button.disabled = run_state.collection.is_empty() or run_state.get_material("anime") < run_state.next_level_cost()
	level_button.pressed.connect(_on_open_level_popup_pressed)
	level_area.add_child(level_button)


func _add_unified_consumables(parent: VBoxContainer) -> void:
	var consumable_area = VBoxContainer.new()
	consumable_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	consumable_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	consumable_area.add_theme_constant_override("separation", 8)
	parent.add_child(consumable_area)

	var title = Label.new()
	title.text = "Consumabili"
	title.add_theme_font_size_override("font_size", 20)
	consumable_area.add_child(title)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	consumable_area.add_child(grid)

	for consumable in GameDatabase.get_consumables():
		var consumable_data: Dictionary = consumable
		var cost_data: Dictionary = {}
		if consumable_data.has("cost"):
			cost_data = consumable_data["cost"]
		var consumable_button = Button.new()
		consumable_button.custom_minimum_size = Vector2(250, 118)
		consumable_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		consumable_button.text = "%s\nCosto: %s\n%s" % [
			consumable_data.get("name", "Consumabile"),
			_format_material_cost(cost_data),
			consumable_data.get("effect_text", ""),
		]
		consumable_button.disabled = true
		grid.add_child(consumable_button)


func _format_material_cost(cost: Dictionary) -> String:
	var parts: Array = []
	for material_id in cost.keys():
		parts.append("%s %d" % [String(material_id), int(cost.get(material_id, 0))])
	return ", ".join(parts) if not parts.is_empty() else "gratis"


func _render_safe_popup_page() -> void:
	var popup_panel = PanelContainer.new()
	popup_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_grid.add_child(popup_panel)

	var popup_layout = VBoxContainer.new()
	popup_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	popup_layout.add_theme_constant_override("separation", 12)
	popup_panel.add_child(popup_layout)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = 0

	var header = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_layout.add_child(header)

	var title = Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.text = _get_safe_popup_title()
	title.add_theme_font_size_override("font_size", 22)
	header.add_child(title)

	var up_button = Button.new()
	up_button.text = "Su"
	up_button.tooltip_text = "Scorri verso l'alto"
	up_button.custom_minimum_size = Vector2(64, 44)
	up_button.pressed.connect(_on_popup_scroll_pressed.bind(scroll, -360))
	header.add_child(up_button)

	var down_button = Button.new()
	down_button.text = "Giu"
	down_button.tooltip_text = "Scorri verso il basso"
	down_button.custom_minimum_size = Vector2(64, 44)
	down_button.pressed.connect(_on_popup_scroll_pressed.bind(scroll, 360))
	header.add_child(down_button)

	var close_button = Button.new()
	close_button.text = "X"
	close_button.tooltip_text = "Chiudi pagina"
	close_button.custom_minimum_size = Vector2(54, 44)
	close_button.pressed.connect(_on_close_safe_popup_pressed)
	header.add_child(close_button)

	popup_layout.add_child(scroll)

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	if safe_popup_mode == SAFE_POPUP_COLLECTION:
		_add_collection_content(content)
	elif safe_popup_mode == SAFE_POPUP_MAP:
		_add_map_popup_content(content)
	elif safe_popup_mode == SAFE_POPUP_SETTINGS:
		_add_settings_popup_content(content)
	elif safe_popup_mode == SAFE_POPUP_LEVEL:
		_add_level_popup_content(content)


func _get_safe_popup_title() -> String:
	if safe_popup_mode == SAFE_POPUP_COLLECTION:
		return "Collezione / Loadout"
	if safe_popup_mode == SAFE_POPUP_MAP:
		return "Mappa"
	if safe_popup_mode == SAFE_POPUP_SETTINGS:
		return "Impostazioni"
	if safe_popup_mode == SAFE_POPUP_LEVEL:
		return "Scegli carta da potenziare"
	return "Pagina"


func _on_popup_scroll_pressed(scroll: ScrollContainer, amount: int) -> void:
	scroll.scroll_vertical = max(0, scroll.scroll_vertical + amount)


func _add_collection_content(parent: VBoxContainer) -> void:
	var title = Label.new()
	title.text = "Collezione e loadout"
	title.add_theme_font_size_override("font_size", 18)
	parent.add_child(title)

	var counts = Label.new()
	counts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	counts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	counts.text = "Loadout: %d/%d | Collezione: %d/%d" % [
		run_state.loadout.size(),
		CardRules.LOADOUT_MAX,
		run_state.collection.size(),
		CardRules.COLLECTION_MAX,
	]
	parent.add_child(counts)

	var class_names = []
	for class_id in run_state.acquired_classes:
		class_names.append(_get_class_display_text(class_id))
	var classes = Label.new()
	classes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	classes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	classes.text = "Classi acquisite: %s" % (", ".join(class_names) if not class_names.is_empty() else "nessuna")
	parent.add_child(classes)

	_add_collection_section(parent, "Loadout attuale", run_state.loadout)

	var reserve_cards = []
	for card_id in run_state.collection:
		if not run_state.loadout.has(card_id):
			reserve_cards.append(card_id)
	_add_collection_section(parent, "In collezione, fuori loadout", reserve_cards)


func _add_level_popup_content(parent: VBoxContainer) -> void:
	var title = Label.new()
	title.text = "Sali di livello"
	title.add_theme_font_size_override("font_size", 18)
	parent.add_child(title)

	var info = Label.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.text = "Costo: %d anime. Scegli una carta della collezione: il PG sale di livello, ottiene +5 vita/stamina fino a 100 e quella carta prende +1." % run_state.next_level_cost()
	parent.add_child(info)

	if run_state.collection.is_empty():
		var empty = Label.new()
		empty.text = "Non hai carte in collezione."
		parent.add_child(empty)
		return

	var grid = GridContainer.new()
	grid.columns = _get_collection_card_columns()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	parent.add_child(grid)

	for card_id in run_state.collection:
		var card = GameDatabase.get_card(card_id)
		var level_button = Button.new()
		level_button.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		level_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		level_button.text = _get_card_display_text(card_id, "a +%d" % (run_state.get_card_level(card_id) + 1), "Potenzia")
		level_button.disabled = run_state.get_material("anime") < run_state.next_level_cost()
		_apply_card_button_style(level_button, card)
		level_button.pressed.connect(_on_level_popup_card_pressed.bind(card_id))
		grid.add_child(level_button)


func _add_collection_section(parent: VBoxContainer, title_text: String, card_ids: Array) -> void:
	var title = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 16)
	parent.add_child(title)

	if card_ids.is_empty():
		var empty = Label.new()
		empty.text = "Nessuna carta."
		parent.add_child(empty)
		return

	var grid = GridContainer.new()
	grid.columns = _get_collection_card_columns()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	parent.add_child(grid)

	for card_id in card_ids:
		_add_collection_card(grid, card_id)


func _add_collection_card(parent: Control, card_id: String) -> void:
	var card = GameDatabase.get_card(card_id)
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(panel)

	var rarity = String(card.get("rarity", "")) if not card.is_empty() else ""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.105, 0.095, 0.085)
	style.border_color = _rarity_color(rarity)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	panel.add_child(content)

	if card.is_empty():
		var missing = Label.new()
		missing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		missing.text = "%s\nCarta non trovata" % card_id
		content.add_child(missing)
		return

	var level = run_state.get_card_level(card_id)
	var level_text = " +%d" % level if level > 0 else ""
	var class_id = String(card.get("class_id", CardRules.CLASS_NEUTRAL))
	var cost = GameDatabase.get_base_stamina_cost(card, run_state.active_class, run_state.collection)

	var name_label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.text = "%s%s" % [card.get("name", card_id), level_text]
	content.add_child(name_label)

	var meta_label = Label.new()
	meta_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_label.text = "%s\n%s | costo %d" % [
		_get_class_display_text(class_id),
		_rarity_label(rarity),
		cost,
	]
	content.add_child(meta_label)

	var separator = HSeparator.new()
	content.add_child(separator)

	var effect_label = Label.new()
	effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.text = String(card.get("effect_text", ""))
	content.add_child(effect_label)


func _get_collection_card_columns() -> int:
	var available_width = get_viewport_rect().size.x - 120.0
	var columns = floori(available_width / float(CARD_WIDTH + 20))
	if columns < 1:
		columns = 1
	if columns > 6:
		columns = 6
	return columns


func _rarity_color(rarity: String) -> Color:
	match rarity:
		CardRules.RARITY_COMMON:
			return Color(0.55, 0.55, 0.50)
		CardRules.RARITY_UNCOMMON:
			return Color(0.34, 0.64, 0.42)
		CardRules.RARITY_RARE:
			return Color(0.38, 0.50, 0.82)
		CardRules.RARITY_LEGENDARY:
			return Color(0.86, 0.62, 0.22)
		_:
			return Color(0.42, 0.38, 0.34)


func _get_card_display_text(card_id: String, detail_text: String, action_text: String) -> String:
	var card = GameDatabase.get_card(card_id)
	if card.is_empty():
		return "%s\nCarta non trovata" % card_id
	var level = run_state.get_card_level(card_id)
	var level_text = " +%d" % level if level > 0 else ""
	var class_id = String(card.get("class_id", CardRules.CLASS_NEUTRAL))
	return "%s%s\n%s\n%s | %s\n\n%s\n\n%s" % [
		card.get("name", card_id),
		level_text,
		_get_class_display_text(class_id),
		_rarity_label(card.get("rarity", "")),
		detail_text,
		_format_card_button_effect(String(card.get("effect_text", ""))),
		action_text,
	]


func _get_hand_card_display_text(card_id: String, cost: int) -> String:
	var card = GameDatabase.get_card(card_id)
	if card.is_empty():
		return "%s\n?" % card_id
	var level = run_state.get_card_level(card_id)
	var level_text = " +%d" % level if level > 0 else ""
	return "%s%s\n%s\nCosto %d" % [
		card.get("name", card_id),
		level_text,
		_rarity_label(card.get("rarity", "")),
		cost,
	]


func _get_stack_card_scale(count: int) -> float:
	if count <= 4:
		return 1.0
	var shrink = 1.0 - float(count - 4) * 0.075
	return max(STACK_CARD_MIN_SCALE, shrink)


func _get_hand_card_scale(count: int) -> float:
	if count <= 0:
		return 1.0
	var available_width = card_grid.size.x
	if available_width < 240.0:
		available_width = get_viewport_rect().size.x - 420.0
	var required_width = float(count * HAND_CARD_WIDTH + max(0, count - 1) * 6)
	if required_width <= available_width:
		return 1.0
	var scaled = available_width / max(1.0, float(count * HAND_CARD_WIDTH))
	return clamp(scaled, HAND_CARD_MIN_SCALE, 1.0)


func _get_stack_player_card_display_text(card_id: String) -> String:
	var card = GameDatabase.get_card(card_id)
	if card.is_empty():
		return "%s\nCarta" % card_id
	var cost = combat_state.get_card_cost_for_current_intent(card_id)
	return "%s\n%s\nCosto %d" % [
		card.get("name", card_id),
		_rarity_label(card.get("rarity", "")),
		cost,
	]


func _get_enemy_stack_card_display_text(entry: Dictionary, compact: bool = false) -> String:
	var intent: Dictionary = {}
	if entry.has("intent"):
		intent = entry["intent"]
	var intent_name = String(intent.get("name", "Intento"))
	if intent.get("kind") == "attack":
		if compact:
			return "%s\nAttacco\n%d danni" % [
				intent_name,
				int(intent.get("damage", 0)),
			]
		return "%s\n%s\nAttacco\n%d danni\nPronta" % [
			enemy_label.text.split("|")[0].strip_edges(),
			intent_name,
			int(intent.get("damage", 0)),
		]
	if intent.get("kind") == "buff":
		if compact:
			return "%s\nRito\n+%d forza" % [
				intent_name,
				int(intent.get("strength", 0)),
			]
		return "%s\n%s\nRito\n+%d forza\nPronta" % [
			enemy_label.text.split("|")[0].strip_edges(),
			intent_name,
			int(intent.get("strength", 0)),
		]
	return "%s\n%s\nIntento\nPronta" % [enemy_label.text.split("|")[0].strip_edges(), intent_name]


func _format_staged_stack() -> String:
	var names = combat_state.get_staged_card_names()
	var text = ""
	for index in range(names.size()):
		if index > 0:
			text += " > "
		text += String(names[index])
	return text


func _format_card_button_effect(effect_text: String) -> String:
	var words = effect_text.split(" ")
	var lines = []
	var current_line = ""
	var clipped = false
	for word_index in range(words.size()):
		var word = String(words[word_index])
		var next_line = word if current_line.is_empty() else "%s %s" % [current_line, word]
		if next_line.length() > 28 and not current_line.is_empty():
			lines.append(current_line)
			current_line = word
			if lines.size() >= 2:
				clipped = word_index < words.size() - 1
				break
		else:
			current_line = next_line
	if lines.size() < 2 and not current_line.is_empty():
		lines.append(current_line)
	if clipped and not lines.is_empty():
		lines[lines.size() - 1] = "%s..." % String(lines[lines.size() - 1])
	return "\n".join(lines)


func _get_class_display_text(class_id: String) -> String:
	var display_name = GameDatabase.get_class_name(class_id)
	if class_id == CardRules.CLASS_NEUTRAL:
		return display_name
	return "%s (%s)" % [display_name, _rarity_label(GameDatabase.get_class_rarity(class_id))]


func _apply_card_button_style(button: Button, card: Dictionary) -> void:
	var rarity = String(card.get("rarity", "")) if not card.is_empty() else ""
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_stylebox_override("normal", _make_card_button_style(rarity, 0.105, 2))
	button.add_theme_stylebox_override("hover", _make_card_button_style(rarity, 0.145, 3))
	button.add_theme_stylebox_override("pressed", _make_card_button_style(rarity, 0.075, 3))
	button.add_theme_stylebox_override("disabled", _make_card_button_style(rarity, 0.085, 2))
	button.add_theme_color_override("font_color", Color(0.92, 0.90, 0.86))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.86))
	button.add_theme_color_override("font_pressed_color", Color(0.86, 0.80, 0.70))
	button.add_theme_color_override("font_disabled_color", Color(0.68, 0.65, 0.58))
	button.add_theme_font_size_override("font_size", 14)


func _apply_enemy_stack_card_style(button: Button) -> void:
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_stylebox_override("normal", _make_enemy_stack_card_style(0.10, 2))
	button.add_theme_stylebox_override("hover", _make_enemy_stack_card_style(0.13, 3))
	button.add_theme_stylebox_override("pressed", _make_enemy_stack_card_style(0.075, 3))
	button.add_theme_stylebox_override("disabled", _make_enemy_stack_card_style(0.085, 2))
	button.add_theme_color_override("font_color", Color(0.94, 0.78, 0.72))
	button.add_theme_font_size_override("font_size", 14)


func _make_enemy_stack_card_style(shade: float, border_width: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(shade * 1.05, shade * 0.55, shade * 0.48)
	style.border_color = Color(0.70, 0.18, 0.14)
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	return style


func _make_card_button_style(rarity: String, shade: float, border_width: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(shade, shade * 0.92, shade * 0.82)
	style.border_color = _rarity_color(rarity)
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	return style


func _on_hand_card_mouse_entered(card_id: String, button: Button) -> void:
	button.scale = Vector2(HAND_CARD_ZOOM, HAND_CARD_ZOOM)
	button.z_index = 10
	_show_card_preview(card_id, button)


func _on_hand_card_mouse_exited(button: Button) -> void:
	button.scale = Vector2.ONE
	button.z_index = 0
	_clear_card_preview()


func _on_stack_card_mouse_entered(entry: Dictionary, button: Button) -> void:
	button.z_index = 90
	_show_stack_card_preview(entry, button)


func _on_stack_card_mouse_exited(button: Button, base_z_index: int) -> void:
	button.z_index = base_z_index
	_clear_card_preview()


func _show_card_preview(card_id: String, source_button: Control) -> void:
	_clear_card_preview()
	hover_card_preview = PanelContainer.new()
	hover_card_preview.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	hover_card_preview.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	hover_card_preview.z_index = 100
	add_child(hover_card_preview)

	var card = GameDatabase.get_card(card_id)
	var rarity = String(card.get("rarity", "")) if not card.is_empty() else ""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.105, 0.095, 0.085)
	style.border_color = _rarity_color(rarity)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	hover_card_preview.add_theme_stylebox_override("panel", style)

	var preview_position = source_button.global_position + Vector2(
		-float(CARD_WIDTH - HAND_CARD_WIDTH) / 2.0,
		-float(CARD_HEIGHT) - 18.0
	)
	var viewport_size = get_viewport_rect().size
	preview_position.x = clamp(preview_position.x, 12.0, viewport_size.x - CARD_WIDTH - 12.0)
	preview_position.y = clamp(preview_position.y, 12.0, viewport_size.y - CARD_HEIGHT - 12.0)
	hover_card_preview.global_position = preview_position

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	hover_card_preview.add_child(content)
	_add_card_detail_content(content, card_id)


func _show_stack_card_preview(entry: Dictionary, source_button: Control) -> void:
	_clear_card_preview()
	hover_card_preview = PanelContainer.new()
	hover_card_preview.custom_minimum_size = Vector2(STACK_CARD_PREVIEW_WIDTH, STACK_CARD_PREVIEW_HEIGHT)
	hover_card_preview.size = Vector2(STACK_CARD_PREVIEW_WIDTH, STACK_CARD_PREVIEW_HEIGHT)
	hover_card_preview.z_index = 120
	add_child(hover_card_preview)

	var is_enemy = String(entry.get("owner", "")) == "enemy"
	var border_color = Color(0.70, 0.18, 0.14)
	if not is_enemy:
		var card_id = String(entry.get("card_id", ""))
		var card = GameDatabase.get_card(card_id)
		border_color = _rarity_color(String(card.get("rarity", "")) if not card.is_empty() else "")

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.08, 0.07)
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	hover_card_preview.add_theme_stylebox_override("panel", style)

	var preview_position = source_button.global_position + Vector2(source_button.size.x + 12.0, -20.0)
	var viewport_size = get_viewport_rect().size
	preview_position.x = clamp(preview_position.x, 12.0, viewport_size.x - STACK_CARD_PREVIEW_WIDTH - 12.0)
	preview_position.y = clamp(preview_position.y, 12.0, viewport_size.y - STACK_CARD_PREVIEW_HEIGHT - 12.0)
	hover_card_preview.global_position = preview_position

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 4)
	hover_card_preview.add_child(content)

	if is_enemy:
		_add_enemy_stack_detail_content(content, entry)
	else:
		_add_stack_player_detail_content(content, String(entry.get("card_id", "")))


func _clear_card_preview() -> void:
	if hover_card_preview != null:
		hover_card_preview.queue_free()
		hover_card_preview = null


func _add_stack_player_detail_content(parent: VBoxContainer, card_id: String) -> void:
	var card = GameDatabase.get_card(card_id)
	if card.is_empty():
		var missing = Label.new()
		missing.text = "Carta non trovata"
		parent.add_child(missing)
		return
	var cost = combat_state.get_card_cost_for_current_intent(card_id)
	var title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 15)
	title.text = "%s | %s | costo %d" % [card.get("name", card_id), _rarity_label(card.get("rarity", "")), cost]
	parent.add_child(title)
	var effect = Label.new()
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.text = String(card.get("effect_text", ""))
	parent.add_child(effect)


func _add_enemy_stack_detail_content(parent: VBoxContainer, entry: Dictionary) -> void:
	var intent: Dictionary = {}
	if entry.has("intent"):
		intent = entry["intent"]
	var title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 15)
	title.text = "%s | %s" % [enemy_label.text.split("|")[0].strip_edges(), intent.get("name", "Intento")]
	parent.add_child(title)
	var detail = Label.new()
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if intent.get("kind") == "attack":
		detail.text = "Attacco: %d danni quando la pila si risolve." % int(intent.get("damage", 0))
	elif intent.get("kind") == "buff":
		detail.text = "Rito: il nemico ottiene +%d forza." % int(intent.get("strength", 0))
	else:
		detail.text = "Intento nemico in pila."
	parent.add_child(detail)


func _add_card_detail_content(parent: VBoxContainer, card_id: String) -> void:
	var card = GameDatabase.get_card(card_id)
	if card.is_empty():
		var missing = Label.new()
		missing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		missing.text = "%s\nCarta non trovata" % card_id
		parent.add_child(missing)
		return

	var level = run_state.get_card_level(card_id)
	var level_text = " +%d" % level if level > 0 else ""
	var class_id = String(card.get("class_id", CardRules.CLASS_NEUTRAL))
	var cost = GameDatabase.get_base_stamina_cost(card, run_state.active_class, run_state.collection)
	if screen_mode == SCREEN_COMBAT:
		cost = combat_state.get_card_cost_for_current_intent(card_id)

	var name_label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.text = "%s%s" % [card.get("name", card_id), level_text]
	parent.add_child(name_label)

	var meta_label = Label.new()
	meta_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_label.text = "%s\n%s | costo %d" % [
		_get_class_display_text(class_id),
		_rarity_label(card.get("rarity", "")),
		cost,
	]
	parent.add_child(meta_label)

	var separator = HSeparator.new()
	parent.add_child(separator)

	var effect_label = Label.new()
	effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.text = String(card.get("effect_text", ""))
	parent.add_child(effect_label)


func _add_map_popup_content(parent: VBoxContainer) -> void:
	var title = Label.new()
	title.text = "Mappa"
	title.add_theme_font_size_override("font_size", 18)
	parent.add_child(title)

	var current = Label.new()
	current.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	current.text = "Posizione: %d,%d | Nodo: %s" % [
		run_state.map_position.x,
		run_state.map_position.y,
		run_state.get_current_node_name(),
	]
	parent.add_child(current)

	var unknown = Label.new()
	unknown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unknown.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	unknown.text = "Boss finale: posizione sconosciuta. Serve un pezzo di mappa o un indizio."
	parent.add_child(unknown)

	_add_map_controls_to(parent)


func _add_settings_popup_content(parent: VBoxContainer) -> void:
	var title = Label.new()
	title.text = "Impostazioni"
	title.add_theme_font_size_override("font_size", 18)
	parent.add_child(title)

	var fullscreen = Button.new()
	fullscreen.text = "Alterna schermo intero"
	fullscreen.pressed.connect(_toggle_fullscreen)
	parent.add_child(fullscreen)

	var menu_button = Button.new()
	menu_button.text = "Torna al menu"
	menu_button.pressed.connect(_on_menu_pressed)
	parent.add_child(menu_button)

	var hint = Label.new()
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = "Audio, controlli e opzioni grafiche arriveranno quando la UI base sara stabile."
	parent.add_child(hint)


func _add_safe_nav_button(parent: VBoxContainer, text: String, tooltip: String, mode: String) -> void:
	var button = Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(54, 54)
	button.disabled = safe_popup_mode == mode
	button.pressed.connect(_on_safe_popup_pressed.bind(mode))
	parent.add_child(button)


func _add_level_shop_box(parent: Control) -> void:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.0
	parent.add_child(panel)

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var title = Label.new()
	title.text = "Potenziamenti"
	title.add_theme_font_size_override("font_size", 20)
	content.add_child(title)

	var level_title = Label.new()
	level_title.text = "Acquista livello: %d anime" % run_state.next_level_cost()
	level_title.add_theme_font_size_override("font_size", 16)
	content.add_child(level_title)

	var level_hint = Label.new()
	level_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	level_hint.text = "Scegli una carta: sali di livello, ottieni +5 vita/stamina fino a 100 e quella carta prende +1."
	content.add_child(level_hint)

	var level_scroll = ScrollContainer.new()
	level_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	level_scroll.horizontal_scroll_mode = 0
	content.add_child(level_scroll)

	var level_grid = GridContainer.new()
	level_grid.columns = 2
	level_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_grid.add_theme_constant_override("h_separation", 12)
	level_grid.add_theme_constant_override("v_separation", 12)
	level_scroll.add_child(level_grid)

	for card_id in run_state.collection:
		var card = GameDatabase.get_card(card_id)
		var level_button = Button.new()
		level_button.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		level_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		level_button.text = _get_card_display_text(card_id, "a +%d" % (run_state.get_card_level(card_id) + 1), "Potenzia")
		level_button.disabled = run_state.get_material("anime") < run_state.next_level_cost()
		_apply_card_button_style(level_button, card)
		level_button.pressed.connect(_on_level_up_pressed.bind(card_id))
		level_grid.add_child(level_button)


func _add_reward_shop_box(parent: Control) -> void:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.35
	parent.add_child(panel)

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var title = Label.new()
	title.text = "Mercante"
	title.add_theme_font_size_override("font_size", 20)
	content.add_child(title)

	var placeholder = Label.new()
	placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	placeholder.text = "Le ricompense del combattimento si scelgono prima di arrivare qui. Questo riquadro ospitera carte in vendita, consumabili ed equipaggiamenti."
	content.add_child(placeholder)

	if run_state.has_shadow():
		var shadow_title = Label.new()
		shadow_title.text = "Ombra: %d anime perdute" % int(run_state.shadow_memory.get("lost_souls", 0))
		content.add_child(shadow_title)
		var shadow_button = Button.new()
		if run_state.can_start_forced_shadow_encounter():
			shadow_button.text = "Affronta l'Ombra ritornata"
			shadow_button.pressed.connect(_on_shadow_boss_pressed.bind(true))
		elif run_state.can_start_first_shadow_encounter():
			shadow_button.text = "Affronta la tua Ombra"
			shadow_button.pressed.connect(_on_shadow_boss_pressed.bind(false))
		else:
			shadow_button.text = "L'Ombra tornera a Paura 90"
			shadow_button.disabled = true
		content.add_child(shadow_button)


func _add_map_controls_to(parent: VBoxContainer) -> void:
	var map_title = Label.new()
	map_title.text = "Movimento griglia"
	map_title.add_theme_font_size_override("font_size", 16)
	parent.add_child(map_title)

	var directions = [
		["Nord", "north"],
		["Sud", "south"],
		["Est", "east"],
		["Ovest", "west"],
	]
	for direction in directions:
		var move_button = Button.new()
		move_button.text = "Vai a %s" % direction[0]
		move_button.disabled = run_state.game_won or run_state.can_start_forced_shadow_encounter() or not combat_state.rewards_claimed
		move_button.pressed.connect(_on_move_pressed.bind(direction[1]))
		parent.add_child(move_button)


func _render_safe_panel() -> void:
	for child in safe_panel.get_children():
		child.queue_free()

	if screen_mode == SCREEN_SAFE or screen_mode == SCREEN_REWARD:
		return

	var title = Label.new()
	title.text = "Azioni"
	title.add_theme_font_size_override("font_size", 18)
	safe_panel.add_child(title)

	if not combat_state.ended:
		if bool(combat_state.enemy.get("is_shadow", false)):
			var shadow_hint = Label.new()
			if bool(combat_state.enemy.get("second_encounter", false)):
				shadow_hint.text = "L'Ombra ritornata non permette fuga."
			else:
				shadow_hint.text = "Puoi fuggire dall'Ombra, ma la paura aumenta di 50."
			shadow_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			safe_panel.add_child(shadow_hint)
			if not bool(combat_state.enemy.get("second_encounter", false)):
				var flee_button = Button.new()
				flee_button.text = "Fuggi dall'Ombra (+50 Paura)"
				flee_button.pressed.connect(_on_flee_shadow_pressed)
				safe_panel.add_child(flee_button)
		return

	if not combat_state.victory:
		_save_shadow_after_defeat()
		var defeat = Label.new()
		defeat.text = "Sei morto o hai finito stamina. La tua Ombra custodisce le anime perdute."
		defeat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		safe_panel.add_child(defeat)
		var restart_button = Button.new()
		restart_button.text = "Nuova run"
		restart_button.pressed.connect(_on_restart_run_pressed)
		safe_panel.add_child(restart_button)
		return

	if combat_state.victory:
		var enter_shop_button = Button.new()
		enter_shop_button.text = "Vai al Falò / Shop"
		enter_shop_button.pressed.connect(_enter_safe_area)
		safe_panel.add_child(enter_shop_button)


func _render_shop_controls() -> void:
	var collection_button = Button.new()
	collection_button.text = "Nascondi collezione / loadout" if safe_popup_mode == SAFE_POPUP_COLLECTION else "Vedi collezione / loadout"
	collection_button.pressed.connect(_on_toggle_collection_view_pressed)
	safe_panel.add_child(collection_button)

	_render_level_shop_controls()

	if run_state.has_shadow():
		var shadow_title = Label.new()
		shadow_title.text = "Ombra: %d anime perdute" % int(run_state.shadow_memory.get("lost_souls", 0))
		safe_panel.add_child(shadow_title)
		var shadow_button = Button.new()
		if run_state.can_start_forced_shadow_encounter():
			shadow_button.text = "Affronta l'Ombra ritornata"
			shadow_button.pressed.connect(_on_shadow_boss_pressed.bind(true))
		elif run_state.can_start_first_shadow_encounter():
			shadow_button.text = "Affronta la tua Ombra"
			shadow_button.pressed.connect(_on_shadow_boss_pressed.bind(false))
		else:
			shadow_button.text = "L'Ombra tornera a Paura 90"
			shadow_button.disabled = true
		safe_panel.add_child(shadow_button)

	_render_map_controls()

	var menu_button = Button.new()
	menu_button.text = "Torna al menu"
	menu_button.pressed.connect(_on_menu_pressed)
	safe_panel.add_child(menu_button)


func _render_level_shop_controls() -> void:
	var level_title = Label.new()
	level_title.text = "Acquista livello: %d anime" % run_state.next_level_cost()
	safe_panel.add_child(level_title)

	var level_hint = Label.new()
	level_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	level_hint.text = "Scegli una carta: sali di livello, ottieni +5 vita/stamina fino a 100 e quella carta prende +1."
	safe_panel.add_child(level_hint)

	for card_id in run_state.collection:
		var card = GameDatabase.get_card(card_id)
		var level_button = Button.new()
		level_button.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		level_button.text = _get_card_display_text(card_id, "a +%d" % (run_state.get_card_level(card_id) + 1), "Potenzia")
		level_button.disabled = run_state.get_material("anime") < run_state.next_level_cost()
		_apply_card_button_style(level_button, card)
		level_button.pressed.connect(_on_level_up_pressed.bind(card_id))
		safe_panel.add_child(level_button)


func _render_map_controls() -> void:
	_add_map_controls_to(safe_panel)


func _on_card_pressed(card_id: String) -> void:
	var result = combat_state.stage_card(card_id)
	_push_log(result.get("message", ""))
	_refresh_ui()


func _on_end_intent_pressed() -> void:
	var result = {}
	if combat_state.has_staged_cards():
		result = combat_state.resolve_staged_cards()
	else:
		result = {"message": "Prima gioca una carta o aspetta che il nemico entri nella pila."}
	_push_log(result.get("message", ""))
	if combat_state.ended and combat_state.victory:
		_push_log("Il nemico cade.")
		_enter_reward_area()
	elif combat_state.ended:
		_save_shadow_after_defeat()
		_push_log("La run finisce qui.")
	_refresh_ui()


func _on_pass_stack_turn_pressed() -> void:
	var result = combat_state.pass_stack_turn()
	_push_log(result.get("message", ""))
	_refresh_ui()


func _on_claim_rewards_pressed() -> void:
	var result = combat_state.claim_enemy_rewards()
	_push_log(result.get("message", ""))
	if not reward_card_claimed:
		reward_card_claimed = true
	if run_state.game_won:
		_push_log("Hai sconfitto il boss finale della tua classe. La run e completa.")
	_enter_safe_area()
	_refresh_ui()


func _on_reward_card_pressed(card_id: String) -> void:
	if reward_card_claimed:
		_push_log("Hai gia scelto la ricompensa carta di questo combattimento.")
		_refresh_ui()
		return
	var card = GameDatabase.get_card(card_id)
	if run_state.acquire_card(card_id):
		reward_card_claimed = true
		_push_log("Acquisisci %s. Classe attiva: %s." % [card.get("name", card_id), _get_class_display_text(run_state.active_class)])
	else:
		_push_log("Collezione piena o carta non valida.")
	_refresh_ui()


func _on_shop_card_buy_pressed(card_id: String) -> void:
	var card = GameDatabase.get_card(card_id)
	if card.is_empty():
		_push_log("Carta non valida.")
		_refresh_ui()
		return
	var cost = _get_shop_card_cost(card)
	if run_state.get_material("anime") < cost:
		_push_log("Non hai abbastanza anime per comprare %s." % card.get("name", card_id))
		_refresh_ui()
		return
	if run_state.collection.size() >= CardRules.COLLECTION_MAX:
		_push_log("La collezione e piena.")
		_refresh_ui()
		return
	if not run_state.spend_material("anime", cost):
		_push_log("Non hai abbastanza anime.")
		_refresh_ui()
		return
	if run_state.acquire_card(card_id):
		shop_card_offers.erase(card_id)
		_push_log("Compri %s per %d anime." % [card.get("name", card_id), cost])
	else:
		run_state.add_material("anime", cost)
		_push_log("Non puoi acquistare questa carta.")
	_refresh_ui()


func _on_open_level_popup_pressed() -> void:
	safe_popup_mode = SAFE_POPUP_LEVEL
	_refresh_ui()


func _on_level_popup_card_pressed(card_id: String) -> void:
	var card = GameDatabase.get_card(card_id)
	if run_state.buy_level_up(card_id):
		_push_log("Sali al livello %d. %s ora e +%d." % [
			run_state.player_level,
			card.get("name", card_id),
			run_state.get_card_level(card_id),
		])
		safe_popup_mode = SAFE_POPUP_NONE
	else:
		_push_log("Non hai abbastanza anime.")
	_refresh_ui()


func _on_level_up_pressed(card_id: String) -> void:
	var card = GameDatabase.get_card(card_id)
	if run_state.buy_level_up(card_id):
		_push_log("Sali al livello %d. %s ora e +%d." % [
			run_state.player_level,
			card.get("name", card_id),
			run_state.get_card_level(card_id),
		])
	else:
		_push_log("Non hai abbastanza anime.")
	_refresh_ui()


func _on_new_combat_pressed() -> void:
	_start_new_combat()
	if not bool(combat_state.enemy.get("is_shadow", false)):
		_push_log("Un nuovo Affamato del Borgo emerge dal buio.")
	_refresh_ui()


func _on_move_pressed(direction: String) -> void:
	reward_offers = []
	shop_card_offers = []
	shop_card_offers_generated = false
	var node = run_state.move_to_direction(direction)
	_push_log("Ti muovi verso %s: %s." % [direction, node.get("name", "nodo sconosciuto")])
	_enter_current_map_node()
	_refresh_ui()


func _on_shadow_boss_pressed(second_encounter: bool) -> void:
	_start_shadow_combat(second_encounter)
	_refresh_ui()


func _on_flee_shadow_pressed() -> void:
	var new_fear = run_state.flee_shadow()
	_push_log("Fuggi dall'Ombra. La paura sale a %d." % new_fear)
	_start_new_combat(true)
	_refresh_ui()


func _on_restart_run_pressed() -> void:
	var thief_rewards = run_state.get_pending_thief_restart_rewards()
	run_state.start_new_run(true)
	has_current_run = true
	defeat_snapshot_saved = false
	safe_popup_mode = SAFE_POPUP_NONE
	reward_offers = []
	shop_card_offers = []
	shop_card_offers_generated = false
	_start_new_combat()
	_push_log("Nuova run. Prima il combattimento, poi il Falò / Shop.")
	if not thief_rewards.is_empty():
		_push_log("Il Ladro riparte con %d anime dell'ultimo bottino." % int(thief_rewards.get("anime", 0)))
	_refresh_ui()


func _on_menu_pressed() -> void:
	_show_start_menu()
	_refresh_ui()


func _on_safe_popup_pressed(mode: String) -> void:
	if safe_popup_mode == mode:
		safe_popup_mode = SAFE_POPUP_NONE
	else:
		safe_popup_mode = mode
	_refresh_ui()


func _on_close_safe_popup_pressed() -> void:
	safe_popup_mode = SAFE_POPUP_NONE
	_refresh_ui()


func _on_toggle_collection_view_pressed() -> void:
	if safe_popup_mode == SAFE_POPUP_COLLECTION:
		safe_popup_mode = SAFE_POPUP_NONE
	else:
		safe_popup_mode = SAFE_POPUP_COLLECTION
	_refresh_ui()


func _enter_reward_area() -> void:
	_refresh_reward_offers()
	if reward_offers.is_empty():
		reward_card_claimed = true
	screen_mode = SCREEN_REWARD


func _enter_safe_area() -> void:
	screen_mode = SCREEN_SAFE


func _enter_current_map_node() -> void:
	var node_type = run_state.get_current_node_type()
	if node_type == "event":
		_resolve_event_node()
		return
	if node_type == "campfire":
		run_state.mark_current_node_resolved()
		_prepare_safe_node_state()
		screen_mode = SCREEN_SAFE
		_push_log("Raggiungi un falò. Puoi riprendere fiato.")
		return
	_start_new_combat()


func _resolve_event_node() -> void:
	var reward = 20 + run_state.get_distance_from_start() * 3
	run_state.add_material("anime", reward)
	run_state.add_fear(5)
	run_state.mark_current_node_resolved()
	combat_state.ended = true
	combat_state.victory = true
	combat_state.rewards_claimed = true
	combat_state.enemy = {
		"name": run_state.get_current_node_name(),
		"health": 0,
		"max_health": 0,
		"poison": 0,
		"burn": 0,
		"bleed": 0,
		"marked": false,
		"intents": [],
	}
	screen_mode = SCREEN_SAFE
	_push_log("Evento oscuro: ottieni %d anime, ma la paura sale a %d." % [reward, run_state.fear])


func _prepare_safe_node_state() -> void:
	_ensure_reward_offers()
	combat_state.ended = true
	combat_state.victory = true
	combat_state.rewards_claimed = true
	combat_state.enemy = {
		"name": run_state.get_current_node_name(),
		"health": 0,
		"max_health": 0,
		"poison": 0,
		"burn": 0,
		"bleed": 0,
		"marked": false,
		"intents": [],
	}


func _refresh_reward_offers() -> void:
	reward_offers = GameDatabase.get_reward_offers(run_state.collection, run_state.active_class, run_state.acquired_classes)


func _ensure_reward_offers() -> void:
	if reward_offers.is_empty():
		_refresh_reward_offers()


func _save_shadow_after_defeat() -> void:
	if defeat_snapshot_saved:
		return
	defeat_snapshot_saved = true
	if bool(combat_state.enemy.get("is_shadow", false)):
		run_state.materials["anime"] = 0
		_push_log("L'Ombra resta intatta e le anime ti sfuggono ancora.")
		return
	var shadow = run_state.create_shadow_from_current_run()
	_push_log("Nasce un'Ombra dalla build precedente: %d anime perdute." % int(shadow.get("lost_souls", 0)))


func _push_log(message: String) -> void:
	if message.is_empty():
		return
	log_lines.append(message)
	if log_lines.size() > 8:
		log_lines.pop_front()


func _rarity_label(rarity: String) -> String:
	match rarity:
		CardRules.RARITY_COMMON:
			return "Comune"
		CardRules.RARITY_UNCOMMON:
			return "Non comune"
		CardRules.RARITY_RARE:
			return "Rara"
		CardRules.RARITY_LEGENDARY:
			return "Leggendaria"
		_:
			return rarity


func _get_combat_card_columns() -> int:
	return max(1, combat_state.get_hand_card_count())
