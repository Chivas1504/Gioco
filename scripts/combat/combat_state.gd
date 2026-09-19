class_name CombatState
extends RefCounted

var run_state: RunState
var enemy = {}
var used_card_ids: Array = []
var staged_card_ids: Array = []
var staged_stack: Array = []
var used_class_bonuses: Array = []
var guard = 0
var enemy_strength_bonus = 0
var weakened_next_intent = 0
var incoming_damage_bonus = 0
var next_damage_multiplier = 1.0
var temporary_cera = 0
var next_sorcerer_damage_bonus = 0
var stamina_spent_this_round = 0
var enemy_card_cost_tax = 0
var ghost_phase_available = false
var ended = false
var victory = false
var rewards_claimed = false
var low_health_fear_triggered = false
var stack_turn_owner = "player"
var round_starter = "player"
var enemy_cards_staged_this_round = 0
var initiative_rng = RandomNumberGenerator.new()

func start_combat(p_run_state: RunState, p_enemy: Dictionary) -> void:
	run_state = p_run_state
	enemy = p_enemy.duplicate(true)
	initiative_rng.randomize()
	used_card_ids = []
	staged_card_ids = []
	staged_stack = []
	used_class_bonuses = []
	guard = 0
	enemy_strength_bonus = 0
	weakened_next_intent = 0
	incoming_damage_bonus = 0
	next_damage_multiplier = 1.0
	enemy_cards_staged_this_round = 0
	temporary_cera = 0
	next_sorcerer_damage_bonus = 0
	stamina_spent_this_round = 0
	enemy_card_cost_tax = 0
	ghost_phase_available = run_state.active_class == CardRules.CLASS_GHOST
	ended = false
	victory = false
	rewards_claimed = false
	low_health_fear_triggered = false
	_apply_round_start_class_effects([])
	_start_new_stack_turn([])


func current_intent() -> Dictionary:
	var intents = enemy.get("intents", [])
	if intents.is_empty():
		return {}
	return intents[int(enemy.get("intent_index", 0)) % intents.size()]


func get_card_cost_for_current_intent(card_id: String) -> int:
	var card = GameDatabase.get_card(card_id)
	if card.is_empty():
		return 0
	var cost = GameDatabase.get_base_stamina_cost(card, run_state.active_class, run_state.collection)
	if _will_use_sorcerer_bonus(card):
		cost -= 1
	return max(cost, 0)


func can_play_card(card_id: String) -> bool:
	if ended:
		return false
	if stack_turn_owner != "player":
		return false
	if not run_state.loadout.has(card_id):
		return false
	if used_card_ids.has(card_id):
		return false
	return run_state.stamina >= get_card_cost_for_current_intent(card_id)


func play_card(card_id: String) -> Dictionary:
	if not can_play_card(card_id):
		return {"ok": false, "message": "Non puoi usare questa carta ora."}

	var card = GameDatabase.get_card(card_id)
	var cost = get_card_cost_for_current_intent(card_id)
	var used_sorcerer_bonus = _will_use_sorcerer_bonus(card)
	run_state.stamina -= cost
	stamina_spent_this_round += cost
	used_card_ids.append(card_id)
	if used_sorcerer_bonus:
		used_class_bonuses.append(CardRules.CLASS_SORCERER)

	var level = run_state.get_card_level(card_id)
	var messages = ["%s costa %d stamina." % [card.get("name", card_id), cost]]
	var trigger_count = _get_card_trigger_count(card)
	for trigger_index in range(trigger_count):
		if trigger_index > 0:
			if int(enemy.get("health", 0)) <= 0:
				break
			messages.append("%s si riattiva." % card.get("name", card_id))
		messages.append_array(_apply_card_effects(card, level))
	_check_end_state()
	return {"ok": true, "message": " ".join(messages)}


func stage_card(card_id: String) -> Dictionary:
	if not can_play_card(card_id):
		return {"ok": false, "message": "Non puoi impilare questa carta ora."}

	var card = GameDatabase.get_card(card_id)
	var cost = get_card_cost_for_current_intent(card_id)
	var used_sorcerer_bonus = _will_use_sorcerer_bonus(card)
	run_state.stamina -= cost
	stamina_spent_this_round += cost
	used_card_ids.append(card_id)
	staged_card_ids.append(card_id)
	staged_stack.append({"owner": "player", "card_id": card_id})
	if used_sorcerer_bonus:
		used_class_bonuses.append(CardRules.CLASS_SORCERER)
	var messages = ["Impili %s. Stamina -%d." % [card.get("name", card_id), cost]]
	if round_starter == "player":
		_stage_enemy_card(messages)
	else:
		stack_turn_owner = "resolve"
		messages.append("Sei entrato per secondo: puoi risolvere la pila prima della prossima carta nemica.")
	return {
		"ok": true,
		"message": " ".join(messages),
	}


func has_staged_cards() -> bool:
	return not staged_stack.is_empty()


func get_staged_card_count() -> int:
	return staged_stack.size()


func can_pass_stack_turn() -> bool:
	return (
		not ended
		and round_starter == "enemy"
		and has_staged_cards()
		and (stack_turn_owner == "player" or stack_turn_owner == "resolve")
	)


func pass_stack_turn() -> Dictionary:
	if not can_pass_stack_turn():
		return {"ok": false, "message": "Non puoi passare adesso."}
	var messages = ["Passi il turno senza risolvere la pila."]
	_stage_enemy_card(messages)
	return {"ok": true, "message": " ".join(messages)}


func get_staged_stack_entries() -> Array:
	return staged_stack.duplicate(true)


func get_hand_card_ids() -> Array:
	var cards: Array = []
	for card_id in run_state.loadout:
		if not used_card_ids.has(card_id):
			cards.append(card_id)
	return cards


func get_hand_card_count() -> int:
	return get_hand_card_ids().size()


func get_staged_card_names() -> Array:
	var names: Array = []
	for entry in staged_stack:
		var stack_entry: Dictionary = entry
		if String(stack_entry.get("owner", "")) == "enemy":
			var intent: Dictionary = {}
			if stack_entry.has("intent"):
				intent = stack_entry["intent"]
			names.append("%s: %s" % [enemy.get("name", "Nemico"), intent.get("name", "Intento")])
		else:
			var card_id = String(stack_entry.get("card_id", ""))
			var card = GameDatabase.get_card(card_id)
			names.append(String(card.get("name", card_id)))
	return names


func resolve_staged_cards() -> Dictionary:
	if ended:
		return {"ok": false, "message": "Il combattimento e gia finito."}
	if staged_stack.is_empty():
		return {"ok": false, "message": "Non hai carte nella pila."}

	var stack = staged_stack.duplicate(true)
	staged_card_ids = []
	staged_stack = []
	var messages = ["Risolvi la pila dal basso verso l'alto."]
	var damage_pool = {
		"damage": 0,
		"recover_stamina_on_kill": 0,
		"gain_blood_on_kill": 0,
	}
	var incoming_pool = {"damage": 0}
	var killed_before = int(enemy.get("health", 0)) <= 0
	for entry in stack:
		var stack_entry: Dictionary = entry
		if String(stack_entry.get("owner", "")) == "enemy":
			_apply_enemy_stack_entry(stack_entry, incoming_pool, messages)
		else:
			var card_id = String(stack_entry.get("card_id", ""))
			var card = GameDatabase.get_card(card_id)
			if card.is_empty():
				continue
			var level = run_state.get_card_level(card_id)
			var trigger_count = _get_card_trigger_count(card)
			for trigger_index in range(trigger_count):
				if trigger_index > 0:
					messages.append("%s si riattiva." % card.get("name", card_id))
				else:
					messages.append("%s si risolve." % card.get("name", card_id))
				messages.append_array(_apply_card_effects(card, level, damage_pool))

	_apply_damage_pool(damage_pool, killed_before, messages)
	_apply_incoming_damage_pool(incoming_pool, messages)
	_check_end_state()
	if not ended:
		_apply_end_of_intent_status(messages)
		_tick_temporary_statuses()
		var enemy_cards_played = max(1, enemy_cards_staged_this_round)
		_reset_intent_state()
		_apply_end_of_round_class_effects(messages)
		enemy["intent_index"] = int(enemy.get("intent_index", 0)) + enemy_cards_played
		stamina_spent_this_round = 0
		_apply_round_start_class_effects(messages)
		_start_new_stack_turn(messages)
		_check_end_state()
	return {"ok": true, "message": " ".join(messages)}


func resolve_enemy_intent() -> Dictionary:
	if ended:
		return {"ok": false, "message": "Il combattimento e gia finito."}
	if has_staged_cards():
		return {"ok": false, "message": "Prima devi risolvere la pila di carte."}

	var messages = []
	var intent = current_intent()
	if enemy.get("health", 0) > 0:
		if intent.get("kind") == "attack":
			var incoming = int(intent.get("damage", 0)) + enemy_strength_bonus + incoming_damage_bonus
			incoming = max(0, incoming - enemy_card_cost_tax)
			incoming = max(0, incoming - weakened_next_intent)
			if ghost_phase_available and incoming > 0:
				ghost_phase_available = false
				messages.append("%s ti attraversa: il bonus Fantasma evita il primo attacco." % intent.get("name", "Intento"))
			else:
				var blocked = min(guard, incoming)
				incoming -= blocked
				incoming = ceili(float(incoming) * next_damage_multiplier)
				run_state.health = max(0, run_state.health - incoming)
				messages.append("%s: subisci %d danni, %d bloccati." % [intent.get("name", "Intento"), incoming, blocked])
				_check_low_health_fear(messages)
		elif intent.get("kind") == "buff":
			var strength = max(0, int(intent.get("strength", 0)) - enemy_card_cost_tax)
			enemy_strength_bonus += strength
			messages.append("%s: il nemico diventa piu feroce di %d." % [intent.get("name", "Intento"), strength])

	_apply_end_of_intent_status(messages)
	_tick_temporary_statuses()
	_reset_intent_state()
	_apply_end_of_round_class_effects(messages)
	enemy["intent_index"] = int(enemy.get("intent_index", 0)) + 1
	stamina_spent_this_round = 0
	_apply_round_start_class_effects(messages)
	_check_end_state()
	return {"ok": true, "message": " ".join(messages)}


func claim_enemy_rewards() -> Dictionary:
	if not ended or not victory or rewards_claimed:
		return {"ok": false, "message": ""}
	rewards_claimed = true
	if bool(enemy.get("is_shadow", false)):
		var upgrade_id = String(enemy.get("special_upgrade", "shadow_echo"))
		var recovered_souls = run_state.claim_shadow_victory(bool(enemy.get("second_encounter", false)), upgrade_id)
		var reward_text = GameDatabase.get_shadow_upgrade_name(upgrade_id)
		var bonus_souls = int(enemy.get("soul_reward", 0))
		if bonus_souls < 1:
			bonus_souls = _get_enemy_reward_souls()
		run_state.add_material("anime", bonus_souls)
		run_state.record_victory_rewards({"anime": recovered_souls + bonus_souls})
		return {
			"ok": true,
			"message": "Spezzi l'Ombra: recuperi %d anime perdute, ottieni %d anime bonus e ricevi %s." % [recovered_souls, bonus_souls, reward_text],
		}
	var souls = _get_enemy_reward_souls()
	run_state.add_material("anime", souls)
	run_state.record_victory_rewards({"anime": souls})
	run_state.mark_current_node_resolved()
	var fear_message = run_state.register_combat_without_level_up()
	var message = "Ottieni %d anime." % souls
	if not fear_message.is_empty():
		message += " " + fear_message
	return {"ok": true, "message": message}


func _get_enemy_reward_souls() -> int:
	var souls = int(enemy.get("soul_reward", 0))
	if souls > 0:
		return souls

	souls = 35 + run_state.get_world_level() * 8 + run_state.get_distance_from_start() * 2
	var enemy_type = String(enemy.get("type", ""))
	if bool(enemy.get("is_final_boss", false)):
		souls += 160
	elif enemy_type == "boss":
		souls += 90
	elif enemy_type == "miniboss":
		souls += 45
	if souls < 1:
		souls = 1
	return souls


func _apply_card_effects(card: Dictionary, level: int, damage_pool = null) -> Array:
	var effects = card.get("effects", {})
	var messages: Array = []
	var killed_before = enemy.get("health", 0) <= 0
	var purified = run_state.active_class == CardRules.CLASS_CLERIC

	if effects.has("self_damage") and not purified:
		var self_damage = int(effects.get("self_damage", 0))
		run_state.health = max(0, run_state.health - self_damage)
		messages.append("Perdi %d vita." % self_damage)
		_check_low_health_fear(messages)
	elif effects.has("self_damage") and purified:
		messages.append("Il Chierico purifica il costo maledetto.")

	if effects.has("recover_stamina"):
		var stamina_gain = int(effects.get("recover_stamina", 0)) + level * int(effects.get("recover_stamina_per_level", 0))
		run_state.stamina = min(run_state.max_stamina, run_state.stamina + stamina_gain)
		messages.append("Recuperi %d stamina." % stamina_gain)

	if effects.has("incoming_bonus") and not purified:
		incoming_damage_bonus += int(effects.get("incoming_bonus", 0))
		messages.append("Il prossimo danno subito aumenta di %d." % int(effects.get("incoming_bonus", 0)))
	elif effects.has("incoming_bonus") and purified:
		messages.append("Il Chierico annulla il contraccolpo.")

	if effects.has("guard"):
		var guard_gain = int(effects.get("guard", 0)) + level * int(effects.get("guard_per_level", 0))
		guard += guard_gain
		messages.append("Ottieni %d guardia." % guard_gain)

	if effects.has("weaken_next_intent"):
		var weaken = int(effects.get("weaken_next_intent", 0))
		weakened_next_intent += weaken
		messages.append("Il prossimo intento offensivo perde %d danni." % weaken)

	if effects.has("dodge_multiplier"):
		next_damage_multiplier = min(next_damage_multiplier, float(effects.get("dodge_multiplier", 1.0)))
		if next_damage_multiplier <= 0.0:
			messages.append("Eviti il prossimo danno.")
		else:
			messages.append("Riduci il prossimo danno subito.")

	if effects.has("lose_blood_if_any") and run_state.get_material("sangue") > 0 and not purified:
		run_state.spend_material("sangue", int(effects.get("lose_blood_if_any", 0)))
		messages.append("Perdi sangue.")
	elif effects.has("lose_blood_if_any") and purified:
		messages.append("Il Chierico conserva il sangue contaminato.")

	if effects.has("temporary_cera"):
		temporary_cera += int(effects.get("temporary_cera", 0))
		messages.append("Ottieni cera temporanea.")

	if effects.has("next_sorcerer_damage_bonus"):
		next_sorcerer_damage_bonus += int(effects.get("next_sorcerer_damage_bonus", 0))
		messages.append("La prossima carta Stregone fa piu danni.")

	var damage = int(effects.get("damage", 0)) + level * int(effects.get("damage_per_level", 0))
	if effects.has("bonus_if_enemy_guard") and int(enemy.get("guard", 0)) > 0:
		damage += int(effects.get("bonus_if_enemy_guard", 0))
	if effects.has("execute_bonus") and int(enemy.get("health", 0)) <= floori(float(enemy.get("max_health", 1)) / 2.0):
		damage += int(effects.get("execute_bonus", 0))
	if effects.has("bonus_if_burning") and int(enemy.get("burn", 0)) > 0:
		damage += int(effects.get("bonus_if_burning", 0))
	if card.get("class_id") == CardRules.CLASS_SORCERER and next_sorcerer_damage_bonus > 0 and damage > 0:
		damage += next_sorcerer_damage_bonus
		next_sorcerer_damage_bonus = 0
	if card.get("class_id") == CardRules.CLASS_ELF and bool(enemy.get("marked", false)):
		damage += 2

	var blood_spent = 0
	if effects.has("spend_blood_up_to"):
		blood_spent = min(run_state.get_material("sangue"), int(effects.get("spend_blood_up_to", 0)))
		if blood_spent > 0:
			run_state.spend_material("sangue", blood_spent)
			damage += blood_spent * int(effects.get("damage_per_blood_spent", 0))
			var heal = blood_spent * int(effects.get("heal_per_blood_spent", 0))
			run_state.health = min(run_state.max_health, run_state.health + heal)
			messages.append("Spendi %d sangue e recuperi %d vita." % [blood_spent, heal])

	if damage > 0 and damage_pool == null:
		enemy["health"] = max(0, int(enemy.get("health", 0)) - damage)
		messages.append("Infliggi %d danni." % damage)
		if run_state.active_class == CardRules.CLASS_WEREWOLF:
			enemy["bleed"] = int(enemy.get("bleed", 0)) + damage
			run_state.add_material("sangue", damage)
			messages.append("Il Lupo Mannaro strappa %d sangue." % damage)
	elif damage > 0:
		damage_pool["damage"] = int(damage_pool.get("damage", 0)) + damage
		messages.append("Prepari %d danni." % damage)
		if effects.has("recover_stamina_on_kill"):
			damage_pool["recover_stamina_on_kill"] = int(damage_pool.get("recover_stamina_on_kill", 0)) + int(effects.get("recover_stamina_on_kill", 0))
		if effects.has("gain_blood_on_kill"):
			damage_pool["gain_blood_on_kill"] = int(damage_pool.get("gain_blood_on_kill", 0)) + int(effects.get("gain_blood_on_kill", 0))

	var applies_elf_bonus = (
		run_state.active_class == CardRules.CLASS_ELF
		and card.get("class_id") == CardRules.CLASS_ELF
		and not used_class_bonuses.has(CardRules.CLASS_ELF)
	)
	if effects.has("poison") or applies_elf_bonus:
		var poison = int(effects.get("poison", 0)) + level * int(effects.get("poison_per_level", 0))
		if applies_elf_bonus:
			poison += 1
			used_class_bonuses.append(CardRules.CLASS_ELF)
		enemy["poison"] = int(enemy.get("poison", 0)) + poison
		messages.append("Applichi %d veleno." % poison)

	if effects.has("mark_if_poisoned") and int(enemy.get("poison", 0)) > 0:
		enemy["marked"] = true
		enemy["mark_rounds"] = max(1, int(enemy.get("mark_rounds", 0)))
		messages.append("Il nemico e marchiato.")

	if effects.has("burn"):
		var burn = int(effects.get("burn", 0)) + level * int(effects.get("burn_per_level", 0))
		if effects.has("extra_burn_if_burning") and int(enemy.get("burn", 0)) > 0:
			burn += int(effects.get("extra_burn_if_burning", 0))
		if effects.has("consume_cera_for_extra_burn") and temporary_cera + run_state.get_material("cera") >= int(effects.get("consume_cera_for_extra_burn", 0)):
			_spend_cera_pool(int(effects.get("consume_cera_for_extra_burn", 0)))
			burn *= 2
			messages.append("La cera alimenta il rito.")
		enemy["burn"] = int(enemy.get("burn", 0)) + burn
		messages.append("Applichi %d bruciatura." % burn)

	if effects.has("gain_blood"):
		run_state.add_material("sangue", int(effects.get("gain_blood", 0)))
		messages.append("Guadagni %d sangue." % int(effects.get("gain_blood", 0)))

	if damage_pool == null and not killed_before and enemy.get("health", 0) <= 0:
		if effects.has("recover_stamina_on_kill"):
			var stamina_on_kill = int(effects.get("recover_stamina_on_kill", 0))
			run_state.stamina = min(run_state.max_stamina, run_state.stamina + stamina_on_kill)
			messages.append("Recuperi %d stamina." % stamina_on_kill)
		if effects.has("gain_blood_on_kill"):
			run_state.add_material("sangue", int(effects.get("gain_blood_on_kill", 0)))
			messages.append("Guadagni sangue dal colpo finale.")
		if run_state.active_class == CardRules.CLASS_VAMPIRE:
			run_state.add_material("sangue", 1)
			run_state.health = min(run_state.max_health, run_state.health + 2)
			messages.append("Il bonus Vampiro ti restituisce sangue e vita.")

	return messages


func _apply_damage_pool(damage_pool: Dictionary, killed_before: bool, messages: Array) -> void:
	var total_damage = int(damage_pool.get("damage", 0))
	if total_damage <= 0:
		return

	enemy["health"] = max(0, int(enemy.get("health", 0)) - total_damage)
	messages.append("La pila infligge %d danni in un unico colpo." % total_damage)
	if run_state.active_class == CardRules.CLASS_WEREWOLF:
		enemy["bleed"] = int(enemy.get("bleed", 0)) + total_damage
		run_state.add_material("sangue", total_damage)
		messages.append("Il Lupo Mannaro strappa %d sangue." % total_damage)

	if killed_before or int(enemy.get("health", 0)) > 0:
		return

	var stamina_on_kill = int(damage_pool.get("recover_stamina_on_kill", 0))
	if stamina_on_kill > 0:
		run_state.stamina = min(run_state.max_stamina, run_state.stamina + stamina_on_kill)
		messages.append("Recuperi %d stamina." % stamina_on_kill)

	var blood_on_kill = int(damage_pool.get("gain_blood_on_kill", 0))
	if blood_on_kill > 0:
		run_state.add_material("sangue", blood_on_kill)
		messages.append("Guadagni sangue dal colpo finale.")

	if run_state.active_class == CardRules.CLASS_VAMPIRE:
		run_state.add_material("sangue", 1)
		run_state.health = min(run_state.max_health, run_state.health + 2)
		messages.append("Il bonus Vampiro ti restituisce sangue e vita.")


func _start_new_stack_turn(messages: Array) -> void:
	staged_stack = []
	staged_card_ids = []
	enemy_cards_staged_this_round = 0
	if initiative_rng.randi_range(0, 1) == 0:
		round_starter = "player"
		stack_turn_owner = "player"
		if not messages.is_empty():
			messages.append("Hai l'iniziativa: giochi per primo.")
	else:
		round_starter = "enemy"
		stack_turn_owner = "enemy"
		_stage_enemy_card(messages)


func _stage_enemy_card(messages: Array) -> void:
	if ended:
		return
	var intent = _get_enemy_stack_intent()
	if intent.is_empty():
		stack_turn_owner = "player"
		return
	staged_stack.append({"owner": "enemy", "intent": intent})
	enemy_cards_staged_this_round += 1
	stack_turn_owner = "player"
	if not messages.is_empty():
		messages.append("%s impila %s." % [enemy.get("name", "Nemico"), intent.get("name", "Intento")])


func _get_enemy_stack_intent() -> Dictionary:
	var intents = enemy.get("intents", [])
	if intents.is_empty():
		return {}
	var index = int(enemy.get("intent_index", 0)) + enemy_cards_staged_this_round
	return intents[index % intents.size()].duplicate(true)


func _apply_enemy_stack_entry(entry: Dictionary, incoming_pool: Dictionary, messages: Array) -> void:
	var intent: Dictionary = {}
	if entry.has("intent"):
		intent = entry["intent"]
	var intent_name = String(intent.get("name", "Intento"))
	if intent.get("kind") == "attack":
		var incoming = int(intent.get("damage", 0)) + enemy_strength_bonus + incoming_damage_bonus
		incoming = max(0, incoming - enemy_card_cost_tax)
		incoming = max(0, incoming - weakened_next_intent)
		if ghost_phase_available and incoming > 0:
			ghost_phase_available = false
			messages.append("%s ti attraversa: il bonus Fantasma evita questo attacco." % intent_name)
		else:
			incoming_pool["damage"] = int(incoming_pool.get("damage", 0)) + incoming
			messages.append("%s prepara %d danni." % [intent_name, incoming])
	elif intent.get("kind") == "buff":
		var strength = max(0, int(intent.get("strength", 0)) - enemy_card_cost_tax)
		enemy_strength_bonus += strength
		messages.append("%s: il nemico diventa piu feroce di %d." % [intent_name, strength])


func _apply_incoming_damage_pool(incoming_pool: Dictionary, messages: Array) -> void:
	var incoming = int(incoming_pool.get("damage", 0))
	if incoming <= 0:
		return
	var blocked = min(guard, incoming)
	incoming -= blocked
	incoming = ceili(float(incoming) * next_damage_multiplier)
	run_state.health = max(0, run_state.health - incoming)
	messages.append("La pila nemica infligge %d danni in un unico colpo, %d bloccati." % [incoming, blocked])
	_check_low_health_fear(messages)


func _apply_end_of_intent_status(messages: Array) -> void:
	var poison = int(enemy.get("poison", 0))
	if poison > 0:
		enemy["health"] = max(0, int(enemy.get("health", 0)) - poison)
		enemy["poison"] = max(0, poison - 1)
		messages.append("Il veleno infligge %d danni." % poison)

	var burn = int(enemy.get("burn", 0))
	if burn > 0:
		enemy["health"] = max(0, int(enemy.get("health", 0)) - burn)
		enemy["burn"] = max(0, burn - 1)
		messages.append("La bruciatura infligge %d danni." % burn)

	var bleed = int(enemy.get("bleed", 0))
	if bleed > 0:
		enemy["health"] = max(0, int(enemy.get("health", 0)) - bleed)
		enemy["bleed"] = max(0, bleed - 1)
		messages.append("Il sanguinamento infligge %d danni." % bleed)
		if run_state.active_class == CardRules.CLASS_WEREWOLF:
			run_state.stamina = min(run_state.max_stamina, run_state.stamina + bleed)
			messages.append("Il Lupo Mannaro recupera %d stamina dal sangue perso." % bleed)


func _tick_temporary_statuses() -> void:
	var mark_rounds = int(enemy.get("mark_rounds", 0))
	if mark_rounds > 0:
		mark_rounds -= 1
		enemy["mark_rounds"] = mark_rounds
		if mark_rounds <= 0:
			enemy["marked"] = false


func _apply_round_start_class_effects(messages: Array) -> void:
	if run_state.active_class == CardRules.CLASS_ELF:
		enemy["marked"] = true
		enemy["mark_rounds"] = max(1, int(enemy.get("mark_rounds", 0)))
		if not messages.is_empty():
			messages.append("L'Elfo legge l'intento: il nemico e marchiato.")
	if run_state.active_class == CardRules.CLASS_SORCERER:
		enemy["burn"] = int(enemy.get("burn", 0)) + 1
		if not messages.is_empty():
			messages.append("Lo Stregone mantiene una bruciatura sul nemico.")


func _apply_end_of_round_class_effects(messages: Array) -> void:
	if run_state.active_class == CardRules.CLASS_VAMPIRE:
		if stamina_spent_this_round > 0:
			var heal = max(1, floori(float(stamina_spent_this_round) / 2.0))
			run_state.health = min(run_state.max_health, run_state.health + heal)
			messages.append("Il Vampiro recupera %d vita dalla stamina spesa." % heal)
		var stored_blood = run_state.get_material("sangue")
		if stored_blood > 0:
			weakened_next_intent += stored_blood
			messages.append("Il sangue accumulato sottrae %d stamina al prossimo intento nemico." % stored_blood)
	if run_state.active_class == CardRules.CLASS_ZOMBIE:
		enemy_card_cost_tax += 1
		messages.append("La marcescenza Zombie aumenta di 1 il costo delle carte nemiche.")


func _reset_intent_state() -> void:
	used_card_ids = []
	staged_card_ids = []
	staged_stack = []
	used_class_bonuses = []
	guard = 0
	weakened_next_intent = 0
	incoming_damage_bonus = 0
	next_damage_multiplier = 1.0
	enemy_cards_staged_this_round = 0


func _check_end_state() -> void:
	if enemy.get("health", 0) <= 0:
		ended = true
		victory = true
	elif run_state.health <= 0 or run_state.stamina <= 0:
		ended = true
		victory = false


func _get_card_trigger_count(card: Dictionary) -> int:
	if (
		run_state.active_class == CardRules.CLASS_WARRIOR
		and card.get("class_id") == CardRules.CLASS_WARRIOR
		and card.get("rarity") == CardRules.RARITY_LEGENDARY
	):
		return 3
	return 1


func _will_use_sorcerer_bonus(card: Dictionary) -> bool:
	return (
		run_state.active_class == CardRules.CLASS_SORCERER
		and card.get("class_id") == CardRules.CLASS_SORCERER
		and not used_class_bonuses.has(CardRules.CLASS_SORCERER)
		and temporary_cera + run_state.get_material("cera") > 0
	)


func _spend_cera_pool(amount: int) -> void:
	var from_temp = min(temporary_cera, amount)
	temporary_cera -= from_temp
	var remaining = amount - from_temp
	if remaining > 0:
		run_state.spend_material("cera", remaining)


func _check_low_health_fear(messages: Array) -> void:
	if low_health_fear_triggered:
		return
	if not run_state.is_low_health():
		return
	low_health_fear_triggered = true
	run_state.add_fear(CardRules.FEAR_LOW_HEALTH_GAIN)
	messages.append("La vita scende troppo: la paura sale a %d." % run_state.fear)
