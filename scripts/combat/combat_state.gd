class_name CombatState
extends RefCounted

var run_state: RunState
var enemy := {}
var used_card_ids: Array = []
var used_class_bonuses: Array = []
var guard := 0
var enemy_strength_bonus := 0
var weakened_next_intent := 0
var incoming_damage_bonus := 0
var next_damage_multiplier := 1.0
var temporary_cera := 0
var next_mage_damage_bonus := 0
var ended := false
var victory := false
var rewards_claimed := false

func start_combat(p_run_state: RunState, p_enemy: Dictionary) -> void:
	run_state = p_run_state
	enemy = p_enemy.duplicate(true)
	used_card_ids = []
	used_class_bonuses = []
	guard = 0
	enemy_strength_bonus = 0
	weakened_next_intent = 0
	incoming_damage_bonus = 0
	next_damage_multiplier = 1.0
	temporary_cera = 0
	next_mage_damage_bonus = 0
	ended = false
	victory = false
	rewards_claimed = false


func current_intent() -> Dictionary:
	var intents: Array = enemy.get("intents", [])
	if intents.is_empty():
		return {}
	return intents[int(enemy.get("intent_index", 0)) % intents.size()]


func get_card_cost_for_current_intent(card_id: String) -> int:
	var card := GameDatabase.get_card(card_id)
	if card.is_empty():
		return 0
	var cost := GameDatabase.get_base_stamina_cost(card, run_state.active_class)
	if _will_use_warrior_bonus(card):
		cost -= 1
	if _will_use_mage_bonus(card):
		cost -= 1
	return max(cost, 0)


func can_play_card(card_id: String) -> bool:
	if ended:
		return false
	if not run_state.loadout.has(card_id):
		return false
	if used_card_ids.has(card_id):
		return false
	return run_state.stamina >= get_card_cost_for_current_intent(card_id)


func play_card(card_id: String) -> Dictionary:
	if not can_play_card(card_id):
		return {"ok": false, "message": "Non puoi usare questa carta ora."}

	var card := GameDatabase.get_card(card_id)
	var cost := get_card_cost_for_current_intent(card_id)
	var used_warrior_bonus := _will_use_warrior_bonus(card)
	var used_mage_bonus := _will_use_mage_bonus(card)
	run_state.stamina -= cost
	used_card_ids.append(card_id)
	if used_warrior_bonus:
		used_class_bonuses.append(CardRules.CLASS_WARRIOR)
	if used_mage_bonus:
		used_class_bonuses.append(CardRules.CLASS_MAGE)

	var level := run_state.get_card_level(card_id)
	var messages := ["%s costa %d stamina." % [card.get("name", card_id), cost]]
	messages.append_array(_apply_card_effects(card, level))
	_check_end_state()
	return {"ok": true, "message": " ".join(messages)}


func resolve_enemy_intent() -> Dictionary:
	if ended:
		return {"ok": false, "message": "Il combattimento e gia finito."}

	var messages := []
	var intent := current_intent()
	if enemy.get("health", 0) > 0:
		if intent.get("kind") == "attack":
			var incoming := int(intent.get("damage", 0)) + enemy_strength_bonus + incoming_damage_bonus
			incoming = max(0, incoming - weakened_next_intent)
			var blocked := min(guard, incoming)
			incoming -= blocked
			incoming = ceili(float(incoming) * next_damage_multiplier)
			run_state.health = max(0, run_state.health - incoming)
			messages.append("%s: subisci %d danni, %d bloccati." % [intent.get("name", "Intento"), incoming, blocked])
		elif intent.get("kind") == "buff":
			enemy_strength_bonus += int(intent.get("strength", 0))
			messages.append("%s: il nemico diventa piu feroce." % intent.get("name", "Intento"))

	_apply_end_of_intent_status(messages)
	_reset_intent_state()
	enemy["intent_index"] = int(enemy.get("intent_index", 0)) + 1
	_check_end_state()
	return {"ok": true, "message": " ".join(messages)}


func claim_enemy_rewards() -> Dictionary:
	if not ended or not victory or rewards_claimed:
		return {"ok": false, "message": ""}
	rewards_claimed = true
	var souls := int(enemy.get("soul_reward", 0))
	run_state.add_material("anime", souls)
	return {"ok": true, "message": "Ottieni %d anime." % souls}


func _apply_card_effects(card: Dictionary, level: int) -> Array:
	var effects: Dictionary = card.get("effects", {})
	var messages: Array = []
	var killed_before := enemy.get("health", 0) <= 0

	if effects.has("self_damage"):
		var self_damage := int(effects.get("self_damage", 0))
		run_state.health = max(0, run_state.health - self_damage)
		messages.append("Perdi %d vita." % self_damage)

	if effects.has("recover_stamina"):
		var stamina_gain := int(effects.get("recover_stamina", 0)) + level * int(effects.get("recover_stamina_per_level", 0))
		run_state.stamina = min(run_state.max_stamina, run_state.stamina + stamina_gain)
		messages.append("Recuperi %d stamina." % stamina_gain)

	if effects.has("incoming_bonus"):
		incoming_damage_bonus += int(effects.get("incoming_bonus", 0))
		messages.append("Il prossimo danno subito aumenta di %d." % int(effects.get("incoming_bonus", 0)))

	if effects.has("guard"):
		var guard_gain := int(effects.get("guard", 0)) + level * int(effects.get("guard_per_level", 0))
		guard += guard_gain
		messages.append("Ottieni %d guardia." % guard_gain)

	if effects.has("dodge_multiplier"):
		next_damage_multiplier = min(next_damage_multiplier, float(effects.get("dodge_multiplier", 1.0)))
		if next_damage_multiplier <= 0.0:
			messages.append("Eviti il prossimo danno.")
		else:
			messages.append("Riduci il prossimo danno subito.")

	if effects.has("lose_blood_if_any") and run_state.get_material("sangue") > 0:
		run_state.spend_material("sangue", int(effects.get("lose_blood_if_any", 0)))
		messages.append("Perdi sangue.")

	if effects.has("temporary_cera"):
		temporary_cera += int(effects.get("temporary_cera", 0))
		messages.append("Ottieni cera temporanea.")

	if effects.has("next_mage_damage_bonus"):
		next_mage_damage_bonus += int(effects.get("next_mage_damage_bonus", 0))
		messages.append("La prossima carta Mago fa piu danni.")

	var damage := int(effects.get("damage", 0)) + level * int(effects.get("damage_per_level", 0))
	if effects.has("bonus_if_enemy_guard") and int(enemy.get("guard", 0)) > 0:
		damage += int(effects.get("bonus_if_enemy_guard", 0))
	if effects.has("execute_bonus") and int(enemy.get("health", 0)) <= floori(float(enemy.get("max_health", 1)) / 2.0):
		damage += int(effects.get("execute_bonus", 0))
	if card.get("class_id") == CardRules.CLASS_MAGE and next_mage_damage_bonus > 0 and damage > 0:
		damage += next_mage_damage_bonus
		next_mage_damage_bonus = 0
	if card.get("class_id") == CardRules.CLASS_RANGER and bool(enemy.get("marked", false)):
		damage += 2

	var blood_spent := 0
	if effects.has("spend_blood_up_to"):
		blood_spent = min(run_state.get_material("sangue"), int(effects.get("spend_blood_up_to", 0)))
		if blood_spent > 0:
			run_state.spend_material("sangue", blood_spent)
			damage += blood_spent * int(effects.get("damage_per_blood_spent", 0))
			var heal := blood_spent * int(effects.get("heal_per_blood_spent", 0))
			run_state.health = min(run_state.max_health, run_state.health + heal)
			messages.append("Spendi %d sangue e recuperi %d vita." % [blood_spent, heal])

	if damage > 0:
		enemy["health"] = max(0, int(enemy.get("health", 0)) - damage)
		messages.append("Infliggi %d danni." % damage)

	var applies_ranger_bonus := (
		run_state.active_class == CardRules.CLASS_RANGER
		and card.get("class_id") == CardRules.CLASS_RANGER
		and not used_class_bonuses.has(CardRules.CLASS_RANGER)
	)
	if effects.has("poison") or applies_ranger_bonus:
		var poison := int(effects.get("poison", 0)) + level * int(effects.get("poison_per_level", 0))
		if applies_ranger_bonus:
			poison += 1
			used_class_bonuses.append(CardRules.CLASS_RANGER)
		enemy["poison"] = int(enemy.get("poison", 0)) + poison
		messages.append("Applichi %d veleno." % poison)

	if effects.has("mark_if_poisoned") and int(enemy.get("poison", 0)) > 0:
		enemy["marked"] = true
		messages.append("Il nemico e marchiato.")

	if effects.has("burn"):
		var burn := int(effects.get("burn", 0)) + level * int(effects.get("burn_per_level", 0))
		if effects.has("consume_cera_for_extra_burn") and temporary_cera + run_state.get_material("cera") >= int(effects.get("consume_cera_for_extra_burn", 0)):
			_spend_cera_pool(int(effects.get("consume_cera_for_extra_burn", 0)))
			burn *= 2
			messages.append("La cera alimenta il rito.")
		enemy["burn"] = int(enemy.get("burn", 0)) + burn
		messages.append("Applichi %d bruciatura." % burn)

	if effects.has("gain_blood"):
		run_state.add_material("sangue", int(effects.get("gain_blood", 0)))
		messages.append("Guadagni %d sangue." % int(effects.get("gain_blood", 0)))

	if not killed_before and enemy.get("health", 0) <= 0:
		if effects.has("recover_stamina_on_kill"):
			var stamina_on_kill := int(effects.get("recover_stamina_on_kill", 0))
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


func _apply_end_of_intent_status(messages: Array) -> void:
	var poison := int(enemy.get("poison", 0))
	if poison > 0:
		enemy["health"] = max(0, int(enemy.get("health", 0)) - poison)
		enemy["poison"] = max(0, poison - 1)
		messages.append("Il veleno infligge %d danni." % poison)

	var burn := int(enemy.get("burn", 0))
	if burn > 0:
		enemy["health"] = max(0, int(enemy.get("health", 0)) - burn)
		enemy["burn"] = max(0, burn - 1)
		messages.append("La bruciatura infligge %d danni." % burn)


func _reset_intent_state() -> void:
	used_card_ids = []
	used_class_bonuses = []
	guard = 0
	weakened_next_intent = 0
	incoming_damage_bonus = 0
	next_damage_multiplier = 1.0


func _check_end_state() -> void:
	if run_state.health <= 0 or run_state.stamina <= 0:
		ended = true
		victory = false
	elif enemy.get("health", 0) <= 0:
		ended = true
		victory = true


func _will_use_warrior_bonus(card: Dictionary) -> bool:
	return (
		run_state.active_class == CardRules.CLASS_WARRIOR
		and card.get("class_id") == CardRules.CLASS_WARRIOR
		and not used_class_bonuses.has(CardRules.CLASS_WARRIOR)
	)


func _will_use_mage_bonus(card: Dictionary) -> bool:
	return (
		run_state.active_class == CardRules.CLASS_MAGE
		and card.get("class_id") == CardRules.CLASS_MAGE
		and not used_class_bonuses.has(CardRules.CLASS_MAGE)
		and temporary_cera + run_state.get_material("cera") > 0
	)


func _spend_cera_pool(amount: int) -> void:
	var from_temp := min(temporary_cera, amount)
	temporary_cera -= from_temp
	var remaining := amount - from_temp
	if remaining > 0:
		run_state.spend_material("cera", remaining)
