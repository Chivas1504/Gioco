class_name GameDatabase
extends RefCounted

const CLASSES = {
	CardRules.CLASS_NEUTRAL: {
		"name": "Senzaclasse",
		"rarity": CardRules.RARITY_COMMON,
		"bonus": "Nessun bonus. Le carte neutrali non hanno penalita.",
	},
	CardRules.CLASS_WARRIOR: {
		"name": "Guerriero",
		"rarity": CardRules.RARITY_COMMON,
		"bonus": "La carta leggendaria Guerriero si riattiva fino a due volte.",
	},
	CardRules.CLASS_ELF: {
		"name": "Elfo",
		"rarity": CardRules.RARITY_COMMON,
		"bonus": "Vedi l'intento e il nemico e marchiato durante il tuo round.",
	},
	CardRules.CLASS_SORCERER: {
		"name": "Stregone",
		"rarity": CardRules.RARITY_COMMON,
		"bonus": "Il nemico e bruciato durante il tuo round; alcune carte scalano sulla bruciatura.",
	},
	CardRules.CLASS_VAMPIRE: {
		"name": "Vampiro",
		"rarity": CardRules.RARITY_RARE,
		"bonus": "A fine round recuperi vita dalla stamina spesa e indebolisci il nemico con il sangue accumulato.",
	},
	CardRules.CLASS_WEREWOLF: {
		"name": "Lupo Mannaro",
		"rarity": CardRules.RARITY_RARE,
		"bonus": "Il danno inflitto genera sangue; a fine round il sanguinamento del nemico ti restituisce stamina.",
	},
	CardRules.CLASS_ZOMBIE: {
		"name": "Zombie",
		"rarity": CardRules.RARITY_UNCOMMON,
		"bonus": "Dopo ogni round le carte del nemico diventano piu pesanti e perdono efficacia.",
	},
	CardRules.CLASS_GHOST: {
		"name": "Fantasma",
		"rarity": CardRules.RARITY_RARE,
		"bonus": "Il primo attacco nemico del combattimento ti attraversa.",
	},
	CardRules.CLASS_CLERIC: {
		"name": "Chierico",
		"rarity": CardRules.RARITY_UNCOMMON,
		"bonus": "Le carte maledette sono purificate e ignorano i debuff.",
	},
	CardRules.CLASS_NECROMANCER: {
		"name": "Necromante",
		"rarity": CardRules.RARITY_RARE,
		"bonus": "Le carte Zombie e Fantasma sono considerate carte di classe.",
	},
	CardRules.CLASS_MONSTER_HUNTER: {
		"name": "Cacciatore di Mostri",
		"rarity": CardRules.RARITY_UNCOMMON,
		"bonus": "Una sola carta per ogni classe mostro in collezione non subisce penalita fuori classe.",
	},
	CardRules.CLASS_THIEF: {
		"name": "Ladro",
		"rarity": CardRules.RARITY_UNCOMMON,
		"bonus": "Quando muori, la nuova run riparte con meta delle anime dell'ultimo fight vinto.",
	},
	CardRules.CLASS_DJIN: {
		"name": "Djin",
		"rarity": CardRules.RARITY_LEGENDARY,
		"bonus": "Classe nascosta legata a patti e desideri proibiti.",
	},
}

const BUILD_CARDS = [
	{
		"id": "neutral_rough_strike",
		"name": "Colpo Rozzo",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_NEUTRAL,
		"rarity": CardRules.RARITY_COMMON,
		"cost": 1,
		"effect_text": "Infliggi 3 danni.",
		"effects": {"damage": 3, "damage_per_level": 1},
	},
	{
		"id": "neutral_parry",
		"name": "Parata",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_NEUTRAL,
		"rarity": CardRules.RARITY_COMMON,
		"cost": 1,
		"effect_text": "Ottieni 4 guardia.",
		"effects": {"guard": 4, "guard_per_level": 1},
	},
	{
		"id": "neutral_dodge",
		"name": "Schivata",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_NEUTRAL,
		"rarity": CardRules.RARITY_COMMON,
		"cost": 1,
		"effect_text": "Riduci del 50% il prossimo danno subito.",
		"effects": {"dodge_multiplier": 0.5},
	},
	{
		"id": "neutral_catch_breath",
		"name": "Riprendi Fiato",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_NEUTRAL,
		"rarity": CardRules.RARITY_COMMON,
		"cost": 0,
		"effect_text": "Recuperi 3 stamina. Il prossimo danno subito aumenta di 2.",
		"effects": {"recover_stamina": 3, "recover_stamina_per_level": 1, "incoming_bonus": 2},
	},
	{
		"id": "warrior_clean_slash",
		"name": "Fendente Pulito",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_WARRIOR,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 2,
		"effect_text": "Infliggi 5 danni.",
		"effects": {"damage": 5, "damage_per_level": 2},
	},
	{
		"id": "warrior_shieldbreaker",
		"name": "Spaccascudo",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_WARRIOR,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 2,
		"effect_text": "Infliggi 3 danni. Se il nemico ha guardia, infliggi +3 danni.",
		"effects": {"damage": 3, "damage_per_level": 1, "bonus_if_enemy_guard": 3},
	},
	{
		"id": "warrior_execution",
		"name": "Esecuzione",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_WARRIOR,
		"rarity": CardRules.RARITY_RARE,
		"cost": 3,
		"effect_text": "Infliggi 8 danni. Se il nemico ha meta vita o meno, infliggi +4 danni.",
		"effects": {"damage": 8, "damage_per_level": 2, "execute_bonus": 4},
	},
	{
		"id": "warrior_last_iron_ember",
		"name": "Ultima Brace del Ferro",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_WARRIOR,
		"rarity": CardRules.RARITY_LEGENDARY,
		"cost": 8,
		"effect_text": "Infliggi 18 danni. Se uccide, recuperi 4 stamina.",
		"effects": {"damage": 18, "damage_per_level": 4, "recover_stamina_on_kill": 4},
	},
	{
		"id": "elf_quick_shot",
		"name": "Tiro Rapido",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_ELF,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 1,
		"effect_text": "Infliggi 2 danni.",
		"effects": {"damage": 2, "damage_per_level": 1},
	},
	{
		"id": "elf_poison_arrow",
		"name": "Freccia Avvelenata",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_ELF,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 2,
		"effect_text": "Infliggi 2 danni e applichi 3 veleno.",
		"effects": {"damage": 2, "poison": 3, "poison_per_level": 1},
	},
	{
		"id": "elf_hook_trap",
		"name": "Trappola a Gancio",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_ELF,
		"rarity": CardRules.RARITY_RARE,
		"cost": 3,
		"effect_text": "Infliggi 4 danni. Il prossimo intento offensivo del nemico infligge -4 danni.",
		"effects": {"damage": 4, "damage_per_level": 1, "weaken_next_intent": 4},
	},
	{
		"id": "elf_cold_moon_hunt",
		"name": "Caccia della Luna Fredda",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_ELF,
		"rarity": CardRules.RARITY_LEGENDARY,
		"cost": 8,
		"effect_text": "Infliggi 6 danni e applichi 8 veleno. Se il nemico e gia avvelenato, lo marchi.",
		"effects": {"damage": 6, "damage_per_level": 2, "poison": 8, "poison_per_level": 1, "mark_if_poisoned": true},
	},
	{
		"id": "sorcerer_occult_dart",
		"name": "Dardo Occulto",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_SORCERER,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 2,
		"effect_text": "Infliggi 6 danni. Se il nemico brucia, infliggi +2 danni.",
		"effects": {"damage": 6, "damage_per_level": 2, "bonus_if_burning": 2},
	},
	{
		"id": "sorcerer_wax_sigil",
		"name": "Sigillo di Cera",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_SORCERER,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 1,
		"effect_text": "Guadagni 1 cera temporanea. La prossima carta Stregone infligge +2 danni.",
		"effects": {"temporary_cera": 1, "next_sorcerer_damage_bonus": 2},
	},
	{
		"id": "sorcerer_black_flame",
		"name": "Fiamma Nera",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_SORCERER,
		"rarity": CardRules.RARITY_RARE,
		"cost": 3,
		"effect_text": "Infliggi 5 danni e applichi 3 bruciatura. Se il nemico brucia, applichi +1 bruciatura.",
		"effects": {"damage": 5, "damage_per_level": 2, "burn": 3, "burn_per_level": 1, "extra_burn_if_burning": 1},
	},
	{
		"id": "sorcerer_black_sun",
		"name": "Sole Nero",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_SORCERER,
		"rarity": CardRules.RARITY_LEGENDARY,
		"cost": 8,
		"effect_text": "Infliggi 10 danni e applichi 4 bruciatura. Con 3 cera, ripeti la bruciatura.",
		"effects": {"damage": 10, "damage_per_level": 3, "burn": 4, "burn_per_level": 1, "consume_cera_for_extra_burn": 3},
	},
	{
		"id": "vampire_crimson_bite",
		"name": "Morso Cremisi",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_VAMPIRE,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 2,
		"effect_text": "Infliggi 3 danni e guadagni 1 sangue.",
		"effects": {"damage": 3, "damage_per_level": 1, "gain_blood": 1},
	},
	{
		"id": "vampire_grave_mist",
		"name": "Nebbia del Sepolcro",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_VAMPIRE,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 2,
		"effect_text": "Eviti il prossimo danno. Perdi 1 sangue, se ne hai.",
		"effects": {"dodge_multiplier": 0.0, "lose_blood_if_any": 1},
	},
	{
		"id": "vampire_thirst",
		"name": "Sete",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_VAMPIRE,
		"rarity": CardRules.RARITY_RARE,
		"cost": 3,
		"effect_text": "Guadagni 3 sangue e perdi 2 vita.",
		"effects": {"gain_blood": 3, "self_damage": 2},
	},
	{
		"id": "vampire_crimson_communion",
		"name": "Comunione Cremisi",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_VAMPIRE,
		"rarity": CardRules.RARITY_LEGENDARY,
		"cost": 8,
		"effect_text": "Spendi fino a 5 sangue. Infliggi 4 danni e recuperi 1 vita per sangue speso.",
		"effects": {"spend_blood_up_to": 5, "damage_per_blood_spent": 4, "heal_per_blood_spent": 1, "gain_blood_on_kill": 2},
	},
	{
		"id": "werewolf_moon_rend",
		"name": "Squarcio Lunare",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_WEREWOLF,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 2,
		"effect_text": "Infliggi 5 danni. Se uccide, recuperi 2 stamina.",
		"effects": {"damage": 5, "damage_per_level": 2, "recover_stamina_on_kill": 2},
	},
	{
		"id": "zombie_bone_guard",
		"name": "Guardia d'Ossa",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_ZOMBIE,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 2,
		"effect_text": "Infliggi 2 danni e ottieni 6 guardia.",
		"effects": {"damage": 2, "damage_per_level": 1, "guard": 6, "guard_per_level": 2},
	},
	{
		"id": "ghost_phase_touch",
		"name": "Tocco Fase",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_GHOST,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 1,
		"effect_text": "Infliggi 2 danni e dimezzi il prossimo danno subito.",
		"effects": {"damage": 2, "damage_per_level": 1, "dodge_multiplier": 0.5},
	},
	{
		"id": "cleric_blessed_mace",
		"name": "Mazza Benedetta",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_CLERIC,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 2,
		"effect_text": "Infliggi 4 danni e ottieni 3 guardia.",
		"effects": {"damage": 4, "damage_per_level": 1, "guard": 3, "guard_per_level": 1},
	},
	{
		"id": "necromancer_grave_pact",
		"name": "Patto di Fossa",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_NECROMANCER,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 2,
		"effect_text": "Perdi 1 vita, infliggi 5 danni e ottieni 1 cera temporanea.",
		"effects": {"self_damage": 1, "damage": 5, "damage_per_level": 2, "temporary_cera": 1},
	},
	{
		"id": "monster_hunter_silver_cut",
		"name": "Taglio d'Argento",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_MONSTER_HUNTER,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 2,
		"effect_text": "Infliggi 5 danni. Il prossimo intento offensivo del nemico infligge -2 danni.",
		"effects": {"damage": 5, "damage_per_level": 1, "weaken_next_intent": 2},
	},
	{
		"id": "thief_backstab",
		"name": "Colpo alle Spalle",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_THIEF,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 1,
		"effect_text": "Infliggi 3 danni e dimezzi il prossimo danno subito.",
		"effects": {"damage": 3, "damage_per_level": 1, "dodge_multiplier": 0.5},
	},
	{
		"id": "djin_sealed_wish",
		"name": "Desiderio Sigillato",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_DJIN,
		"rarity": CardRules.RARITY_RARE,
		"cost": 3,
		"effect_text": "Infliggi 4 danni e recuperi 4 stamina. Carta nascosta.",
		"effects": {"damage": 4, "damage_per_level": 2, "recover_stamina": 4, "recover_stamina_per_level": 1},
	},
]

const CONSUMABLES = [
	{
		"id": "black_blood_vial",
		"name": "Ampolla di Sangue Nero",
		"cost": {"sangue": 2},
		"effect_text": "Recuperi 6 vita. Aggiungi 1 corruzione.",
	},
	{
		"id": "dead_candle",
		"name": "Candela dei Morti",
		"cost": {"cera": 1},
		"effect_text": "Il prossimo intento nemico e indebolito di 3 danni.",
	},
	{
		"id": "silver_knife",
		"name": "Coltello d'Argento",
		"cost": {"argento": 1},
		"effect_text": "Infliggi 8 danni. Infligge +8 contro bestie e vampiri.",
	},
	{
		"id": "blessed_bone",
		"name": "Osso Benedetto",
		"cost": {"ossa": 1},
		"effect_text": "Rimuove un effetto negativo.",
	},
]

const ARTIFACTS = [
	{
		"id": "duelist_rosary",
		"name": "Rosario del Duellante",
		"effect_text": "Se inizi un combattimento con 6 o meno carte build, ottieni +3 stamina iniziale.",
	},
	{
		"id": "tooth_in_ash",
		"name": "Dente nella Cenere",
		"effect_text": "La prima volta che scendi sotto 10 vita in un combattimento, guadagni 2 sangue.",
	},
]

const SHADOW_UPGRADES = {
	"shadow_echo": {
		"name": "Eco del Caduto",
		"effect_text": "Promemoria speciale: hai sconfitto la tua Ombra e recuperato le anime perdute.",
	},
	"deep_shadow_echo": {
		"name": "Eco della Notte Profonda",
		"effect_text": "Promemoria speciale: hai sconfitto l'Ombra ritornata dopo la fuga.",
	},
}

static func get_card(card_id: String) -> Dictionary:
	for card in BUILD_CARDS:
		if card.get("id") == card_id:
			return card.duplicate(true)
	return {}


static func get_cards_by_class(class_id: String) -> Array:
	var cards = []
	for card in BUILD_CARDS:
		if card.get("class_id") == class_id:
			cards.append(card.duplicate(true))
	return cards


static func get_class_name(class_id: String) -> String:
	var class_data = CLASSES.get(class_id, CLASSES[CardRules.CLASS_NEUTRAL])
	return String(class_data.get("name", "Senzaclasse"))


static func get_class_rarity(class_id: String) -> String:
	var class_data = CLASSES.get(class_id, CLASSES[CardRules.CLASS_NEUTRAL])
	return String(class_data.get("rarity", CardRules.RARITY_COMMON))


static func get_reward_offers(collection: Array, active_class: String, acquired_classes: Array) -> Array:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var offers = []
	offers.append_array(_pick_reward_cards(collection, active_class, acquired_classes, true, 1, offers, rng))
	offers.append_array(_pick_reward_cards(collection, active_class, acquired_classes, false, 3, offers, rng))
	if offers.size() < 4:
		offers.append_array(_pick_reward_cards(collection, active_class, acquired_classes, false, 4 - offers.size(), offers, rng))
	return offers


static func _pick_reward_cards(collection: Array, active_class: String, acquired_classes: Array, class_slot: bool, count: int, excluded_ids: Array, rng: RandomNumberGenerator) -> Array:
	var candidates = []
	for card in BUILD_CARDS:
		var card_id = String(card.get("id", ""))
		if card_id.is_empty() or collection.has(card_id) or excluded_ids.has(card_id):
			continue
		if class_slot and not _is_class_slot_candidate(card, active_class, acquired_classes):
			continue
		if not class_slot and _is_class_reward_candidate(card, active_class, acquired_classes):
			continue
		candidates.append({
			"id": card_id,
			"weight": _get_reward_weight(card, active_class, acquired_classes, class_slot),
		})
	return _take_weighted_cards(candidates, count, rng)


static func _is_class_slot_candidate(card: Dictionary, active_class: String, acquired_classes: Array) -> bool:
	var card_class = String(card.get("class_id", CardRules.CLASS_NEUTRAL))
	if card_class == CardRules.CLASS_NEUTRAL:
		return false
	if active_class != CardRules.CLASS_NEUTRAL:
		return CardRules.is_class_match(card_class, active_class)
	if not acquired_classes.is_empty():
		return acquired_classes.has(card_class)
	return true


static func _is_class_reward_candidate(card: Dictionary, active_class: String, acquired_classes: Array) -> bool:
	var card_class = String(card.get("class_id", CardRules.CLASS_NEUTRAL))
	if card_class == CardRules.CLASS_NEUTRAL:
		return false
	if active_class != CardRules.CLASS_NEUTRAL:
		return CardRules.is_class_match(card_class, active_class)
	if not acquired_classes.is_empty():
		return acquired_classes.has(card_class)
	return false


static func _get_reward_weight(card: Dictionary, active_class: String, acquired_classes: Array, class_slot: bool) -> float:
	var card_class = String(card.get("class_id", CardRules.CLASS_NEUTRAL))
	var card_rarity = String(card.get("rarity", CardRules.RARITY_COMMON))
	var weight = _card_rarity_reward_weight(card_rarity) * _class_rarity_reward_multiplier(get_class_rarity(card_class))
	if active_class != CardRules.CLASS_NEUTRAL and CardRules.is_class_match(card_class, active_class):
		weight *= 2.25
	elif acquired_classes.has(card_class):
		weight *= 1.45
	elif card_class == CardRules.CLASS_NEUTRAL:
		weight *= 0.85
	if class_slot:
		weight *= 1.8
	if card_class == CardRules.CLASS_DJIN:
		weight *= 0.25
	return max(weight, 1.0)


static func _card_rarity_reward_weight(rarity: String) -> float:
	match rarity:
		CardRules.RARITY_COMMON:
			return 95.0
		CardRules.RARITY_UNCOMMON:
			return 58.0
		CardRules.RARITY_RARE:
			return 24.0
		CardRules.RARITY_LEGENDARY:
			return 5.0
		_:
			return 20.0


static func _class_rarity_reward_multiplier(rarity: String) -> float:
	match rarity:
		CardRules.RARITY_COMMON:
			return 1.25
		CardRules.RARITY_UNCOMMON:
			return 1.0
		CardRules.RARITY_RARE:
			return 0.62
		CardRules.RARITY_LEGENDARY:
			return 0.18
		_:
			return 1.0


static func _take_weighted_cards(candidates: Array, count: int, rng: RandomNumberGenerator) -> Array:
	var picked = []
	var remaining = candidates.duplicate(true)
	while picked.size() < count and not remaining.is_empty():
		var total_weight = 0.0
		for candidate in remaining:
			total_weight += float(candidate.get("weight", 0.0))
		if total_weight <= 0.0:
			break
		var roll = rng.randf_range(0.0, total_weight)
		var running = 0.0
		var selected_index = 0
		for index in range(remaining.size()):
			running += float(remaining[index].get("weight", 0.0))
			if roll <= running:
				selected_index = index
				break
		var selected = remaining[selected_index]
		picked.append(String(selected.get("id", "")))
		remaining.remove_at(selected_index)
	return picked


static func get_base_stamina_cost(card: Dictionary, active_class: String, collection: Array = []) -> int:
	var cost = int(card.get("cost", 0))
	if _has_off_class_stamina_penalty(card, active_class, collection):
		cost += CardRules.out_of_class_penalty(card.get("rarity", CardRules.RARITY_COMMON))
	return cost


static func _has_off_class_stamina_penalty(card: Dictionary, active_class: String, collection: Array) -> bool:
	if not CardRules.is_off_class(card, active_class):
		return false
	var card_class = String(card.get("class_id", CardRules.CLASS_NEUTRAL))
	if active_class == CardRules.CLASS_MONSTER_HUNTER and CardRules.is_monster_class(card_class):
		var class_count = 0
		for card_id in collection:
			var owned_card = get_card(card_id)
			if String(owned_card.get("class_id", CardRules.CLASS_NEUTRAL)) == card_class:
				class_count += 1
		return class_count > 1
	return true


static func get_card_power(card_id: String, card_level: int) -> int:
	var card = get_card(card_id)
	if card.is_empty():
		return 0
	return CardRules.rarity_power(card.get("rarity", CardRules.RARITY_COMMON)) + card_level


static func get_world_level(collection: Array, card_levels: Dictionary) -> int:
	var collection_power = 0
	for card_id in collection:
		collection_power += get_card_power(card_id, int(card_levels.get(card_id, 0)))
	return floori(float(collection_power) / 5.0)


static func make_affamato_del_borgo(world_level: int) -> Dictionary:
	var damage_bonus = floori(float(world_level) * 0.75)
	return {
		"id": "affamato_del_borgo",
		"name": "Affamato del Borgo",
		"type": "hollow",
		"max_health": 16 + world_level * 3,
		"health": 16 + world_level * 3,
		"guard": 0,
		"poison": 0,
		"burn": 0,
		"marked": false,
		"intent_index": 0,
		"soul_reward": 35 + world_level * 8,
		"intents": [
			{"name": "Graffio", "kind": "attack", "damage": 4 + damage_bonus},
			{"name": "Morso", "kind": "attack", "damage": 6 + damage_bonus},
			{"name": "Ringhio", "kind": "buff", "strength": 2},
		],
	}


static func make_grid_enemy(node_data: Dictionary, world_level: int, active_class: String) -> Dictionary:
	var node_type = String(node_data.get("type", "combat"))
	var distance = int(node_data.get("distance", 0))
	var active_class_label = get_class_name(active_class)
	var health_bonus = distance + world_level * 3
	var damage_bonus = floori(float(distance) / 2.0) + world_level
	var enemy_name = "Affamato del Borgo"
	var enemy_id = "grid_combat"
	var soul_reward = 35 + world_level * 8 + distance * 2

	if node_type == "miniboss":
		enemy_name = "Mini-boss del Crocevia"
		enemy_id = "grid_miniboss"
		health_bonus += 18
		damage_bonus += 3
		soul_reward += 45
	elif node_type == "boss":
		enemy_name = "Orrore del Crocevia"
		enemy_id = "grid_boss"
		health_bonus += 34
		damage_bonus += 5
		soul_reward += 90
	elif node_type == "class_boss":
		enemy_name = "Boss finale: %s" % active_class_label
		enemy_id = "class_final_boss"
		health_bonus += 55
		damage_bonus += 8
		soul_reward += 160

	var max_health = 16 + health_bonus
	return {
		"id": enemy_id,
		"name": enemy_name,
		"type": node_type,
		"is_final_boss": node_type == "class_boss",
		"max_health": max_health,
		"health": max_health,
		"guard": 0,
		"poison": 0,
		"burn": 0,
		"marked": false,
		"intent_index": 0,
		"soul_reward": soul_reward,
		"intents": [
			{"name": "Assalto", "kind": "attack", "damage": 4 + damage_bonus},
			{"name": "Pressione", "kind": "buff", "strength": 2 + floori(float(world_level) / 3.0)},
			{"name": "Colpo feroce", "kind": "attack", "damage": 6 + damage_bonus},
		],
	}


static func make_shadow_boss(shadow_memory: Dictionary, fear: int, second_encounter: bool) -> Dictionary:
	var old_loadout = shadow_memory.get("loadout", [])
	var old_levels = shadow_memory.get("card_levels", {})
	var shadow_world_level = int(shadow_memory.get("world_level", 0))
	var lost_souls = int(shadow_memory.get("lost_souls", 0))
	var fear_bonus = floori(float(fear) / 10.0)
	var build_power = 0
	for card_id in old_loadout:
		build_power += get_card_power(card_id, int(old_levels.get(card_id, 0)))

	var power_bonus = floori(float(build_power) / 4.0)
	var health = 34 + shadow_world_level * 4 + power_bonus * 2 + fear_bonus * 2
	var damage = 7 + shadow_world_level + fear_bonus + floori(float(power_bonus) / 2.0)
	var soul_reward = 25 + shadow_world_level * 10
	var boss_name = "Ombra del Caduto"
	var special_upgrade = "shadow_echo"
	if second_encounter:
		health = floori(float(health) * 1.35)
		damage = floori(float(damage) * 1.25) + 2
		soul_reward += 40
		boss_name = "Ombra Divorante"
		special_upgrade = "deep_shadow_echo"

	return {
		"id": "shadow_boss",
		"name": boss_name,
		"type": "shadow",
		"is_shadow": true,
		"second_encounter": second_encounter,
		"max_health": health,
		"health": health,
		"guard": 0,
		"poison": 0,
		"burn": 0,
		"marked": false,
		"intent_index": 0,
		"soul_reward": soul_reward,
		"lost_souls": lost_souls,
		"special_upgrade": special_upgrade,
		"intents": [
			{"name": "Eco della vecchia build", "kind": "attack", "damage": damage},
			{"name": "Ricordo spezzato", "kind": "buff", "strength": 3 if second_encounter else 2},
			{"name": "Colpo d'Ombra", "kind": "attack", "damage": damage + 3},
		],
	}


static func get_shadow_upgrade_name(upgrade_id: String) -> String:
	var upgrade = SHADOW_UPGRADES.get(upgrade_id, {})
	if typeof(upgrade) != TYPE_DICTIONARY:
		return upgrade_id
	return String(upgrade.get("name", upgrade_id))
