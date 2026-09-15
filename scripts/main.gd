extends Control

var run_state = RunState.new()
var combat_state = CombatState.new()
var log_lines: Array = []

var player_label: Label
var enemy_label: Label
var intent_label: Label
var log_label: RichTextLabel
var card_grid: GridContainer
var safe_panel: VBoxContainer
var end_intent_button: Button
var defeat_snapshot_saved = false

const REWARD_POOL = [
	"warrior_clean_slash",
	"ranger_quick_shot",
	"mage_occult_dart",
	"vampire_crimson_bite",
]

func _ready() -> void:
	run_state.start_new_run()
	_start_new_combat()
	_build_ui()
	_push_log("La run comincia. Hai 30 vita, 30 stamina e nessuna classe.")
	_refresh_ui()


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

	var title = Label.new()
	title.text = "Inferno Roguelike - Combat Prototype V0.1"
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	var status_row = HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 24)
	root.add_child(status_row)

	player_label = Label.new()
	player_label.add_theme_font_size_override("font_size", 18)
	status_row.add_child(player_label)

	enemy_label = Label.new()
	enemy_label.add_theme_font_size_override("font_size", 18)
	status_row.add_child(enemy_label)

	intent_label = Label.new()
	intent_label.add_theme_font_size_override("font_size", 18)
	status_row.add_child(intent_label)

	var content_row = HBoxContainer.new()
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 16)
	root.add_child(content_row)

	var left_column = VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.add_theme_constant_override("separation", 10)
	content_row.add_child(left_column)

	var cards_title = Label.new()
	cards_title.text = "Carte build disponibili"
	cards_title.add_theme_font_size_override("font_size", 18)
	left_column.add_child(cards_title)

	card_grid = GridContainer.new()
	card_grid.columns = 4
	card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_grid.add_theme_constant_override("h_separation", 10)
	card_grid.add_theme_constant_override("v_separation", 10)
	left_column.add_child(card_grid)

	end_intent_button = Button.new()
	end_intent_button.text = "Risolvi intento nemico"
	end_intent_button.pressed.connect(_on_end_intent_pressed)
	left_column.add_child(end_intent_button)

	safe_panel = VBoxContainer.new()
	safe_panel.custom_minimum_size = Vector2(320, 0)
	safe_panel.add_theme_constant_override("separation", 8)
	content_row.add_child(safe_panel)

	log_label = RichTextLabel.new()
	log_label.custom_minimum_size = Vector2(0, 160)
	log_label.fit_content = true
	log_label.scroll_following = true
	root.add_child(log_label)


func _start_new_combat(ignore_forced_shadow: bool = false) -> void:
	defeat_snapshot_saved = false
	if run_state.can_start_forced_shadow_encounter() and not ignore_forced_shadow:
		_start_shadow_combat(true)
		return
	var enemy = GameDatabase.make_affamato_del_borgo(run_state.get_world_level())
	combat_state.start_combat(run_state, enemy)


func _start_shadow_combat(second_encounter: bool) -> void:
	defeat_snapshot_saved = false
	var enemy = GameDatabase.make_shadow_boss(run_state.shadow_memory, run_state.fear, second_encounter)
	combat_state.start_combat(run_state, enemy)
	if second_encounter:
		_push_log("La tua Ombra ritorna. Questa volta non puoi fuggire.")
	else:
		_push_log("La tua Ombra ti aspetta con le anime perdute.")


func _refresh_ui() -> void:
	player_label.text = "PG Lv %d | Classe: %s | Vita %d/%d | Stamina %d/%d | Anime %d | Sangue %d | Paura %d | Mondo Lv %d" % [
		run_state.player_level,
		GameDatabase.get_class_name(run_state.active_class),
		run_state.health,
		run_state.max_health,
		run_state.stamina,
		run_state.max_stamina,
		run_state.get_material("anime"),
		run_state.get_material("sangue"),
		run_state.fear,
		run_state.get_world_level(),
	]
	enemy_label.text = "%s | Vita %d/%d | Veleno %d | Bruciatura %d" % [
		combat_state.enemy.get("name", "Nemico"),
		combat_state.enemy.get("health", 0),
		combat_state.enemy.get("max_health", 0),
		combat_state.enemy.get("poison", 0),
		combat_state.enemy.get("burn", 0),
	]
	var intent = combat_state.current_intent()
	if intent.get("kind") == "attack":
		intent_label.text = "Intento: %s, %d danni" % [intent.get("name", ""), intent.get("damage", 0)]
	elif intent.get("kind") == "buff":
		intent_label.text = "Intento: %s, +%d forza" % [intent.get("name", ""), intent.get("strength", 0)]
	else:
		intent_label.text = "Intento: -"

	_render_cards()
	_render_safe_panel()
	log_label.text = "\n".join(log_lines)


func _render_cards() -> void:
	for child in card_grid.get_children():
		child.queue_free()

	for card_id in run_state.loadout:
		var card = GameDatabase.get_card(card_id)
		var button = Button.new()
		var level = run_state.get_card_level(card_id)
		var cost = combat_state.get_card_cost_for_current_intent(card_id)
		button.custom_minimum_size = Vector2(220, 118)
		button.text = "%s%s\n%s | costo %d\n%s" % [
			card.get("name", card_id),
			(" +" + str(level)) if level > 0 else "",
			_rarity_label(card.get("rarity", "")),
			cost,
			card.get("effect_text", ""),
		]
		button.tooltip_text = "Classe: %s" % GameDatabase.get_class_name(card.get("class_id", CardRules.CLASS_NEUTRAL))
		button.disabled = not combat_state.can_play_card(card_id)
		button.pressed.connect(_on_card_pressed.bind(card_id))
		card_grid.add_child(button)


func _render_safe_panel() -> void:
	for child in safe_panel.get_children():
		child.queue_free()

	var title = Label.new()
	title.text = "Falò / Shop di test"
	title.add_theme_font_size_override("font_size", 18)
	safe_panel.add_child(title)

	if not combat_state.ended:
		var hint = Label.new()
		hint.text = "Disponibile dopo la vittoria."
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		safe_panel.add_child(hint)
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

	if not combat_state.rewards_claimed:
		var claim_button = Button.new()
		claim_button.text = "Raccogli anime"
		claim_button.pressed.connect(_on_claim_rewards_pressed)
		safe_panel.add_child(claim_button)

	var reward_title = Label.new()
	reward_title.text = "Scegli una carta"
	safe_panel.add_child(reward_title)

	for card_id in REWARD_POOL:
		if run_state.collection.has(card_id):
			continue
		var card = GameDatabase.get_card(card_id)
		var reward_button = Button.new()
		reward_button.text = "%s - %s" % [card.get("name", card_id), GameDatabase.get_class_name(card.get("class_id", ""))]
		reward_button.pressed.connect(_on_reward_card_pressed.bind(card_id))
		safe_panel.add_child(reward_button)

	var level_title = Label.new()
	level_title.text = "Compra livello: %d anime" % run_state.next_level_cost()
	safe_panel.add_child(level_title)

	for card_id in run_state.collection:
		var card = GameDatabase.get_card(card_id)
		var level_button = Button.new()
		level_button.text = "Potenzia %s a +%d" % [card.get("name", card_id), run_state.get_card_level(card_id) + 1]
		level_button.disabled = run_state.get_material("anime") < run_state.next_level_cost()
		level_button.pressed.connect(_on_level_up_pressed.bind(card_id))
		safe_panel.add_child(level_button)

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

	var next_button = Button.new()
	next_button.text = "Nuovo combattimento"
	next_button.disabled = run_state.can_start_forced_shadow_encounter()
	next_button.pressed.connect(_on_new_combat_pressed)
	safe_panel.add_child(next_button)


func _on_card_pressed(card_id: String) -> void:
	var result = combat_state.play_card(card_id)
	_push_log(result.get("message", ""))
	if combat_state.ended and combat_state.victory:
		_push_log("Il nemico cade. Le carte torneranno disponibili nel prossimo combattimento.")
	elif combat_state.ended:
		_save_shadow_after_defeat()
		_push_log("La run finisce qui.")
	_refresh_ui()


func _on_end_intent_pressed() -> void:
	var result = combat_state.resolve_enemy_intent()
	_push_log(result.get("message", ""))
	if combat_state.ended and combat_state.victory:
		_push_log("Il nemico cade.")
	elif combat_state.ended:
		_save_shadow_after_defeat()
		_push_log("La run finisce qui.")
	_refresh_ui()


func _on_claim_rewards_pressed() -> void:
	var result = combat_state.claim_enemy_rewards()
	_push_log(result.get("message", ""))
	_refresh_ui()


func _on_reward_card_pressed(card_id: String) -> void:
	var card = GameDatabase.get_card(card_id)
	if run_state.acquire_card(card_id):
		_push_log("Acquisisci %s. Classe attiva: %s." % [card.get("name", card_id), GameDatabase.get_class_name(run_state.active_class)])
	else:
		_push_log("Collezione piena o carta non valida.")
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


func _on_shadow_boss_pressed(second_encounter: bool) -> void:
	_start_shadow_combat(second_encounter)
	_refresh_ui()


func _on_flee_shadow_pressed() -> void:
	var new_fear = run_state.flee_shadow()
	_push_log("Fuggi dall'Ombra. La paura sale a %d." % new_fear)
	_start_new_combat(true)
	_refresh_ui()


func _on_restart_run_pressed() -> void:
	run_state.start_new_run(true)
	defeat_snapshot_saved = false
	_start_new_combat()
	_push_log("Nuova run. Da qualche parte, l'Ombra custodisce cio che hai perso.")
	_refresh_ui()


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
