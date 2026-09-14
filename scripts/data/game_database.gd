class_name GameDatabase
extends RefCounted

const CLASSES = {
	CardRules.CLASS_NEUTRAL: {
		"name": "Senzaclasse",
		"bonus": "Nessun bonus. Le carte neutrali non hanno penalita.",
	},
	CardRules.CLASS_WARRIOR: {
		"name": "Guerriero",
		"bonus": "La prima carta Guerriero usata contro ogni intento costa 1 stamina in meno.",
	},
	CardRules.CLASS_RANGER: {
		"name": "Ranger",
		"bonus": "La prima carta Ranger usata contro ogni intento applica +1 veleno.",
	},
	CardRules.CLASS_MAGE: {
		"name": "Mago",
		"bonus": "La prima carta Mago usata contro ogni intento costa 1 stamina in meno se hai cera.",
	},
	CardRules.CLASS_VAMPIRE: {
		"name": "Vampiro",
		"bonus": "Quando uccidi un nemico, guadagni 1 sangue e recuperi 2 vita.",
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
		"id": "ranger_quick_shot",
		"name": "Tiro Rapido",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_RANGER,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 1,
		"effect_text": "Infliggi 2 danni.",
		"effects": {"damage": 2, "damage_per_level": 1},
	},
	{
		"id": "ranger_poison_arrow",
		"name": "Freccia Avvelenata",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_RANGER,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 2,
		"effect_text": "Infliggi 2 danni e applichi 3 veleno.",
		"effects": {"damage": 2, "poison": 3, "poison_per_level": 1},
	},
	{
		"id": "ranger_hook_trap",
		"name": "Trappola a Gancio",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_RANGER,
		"rarity": CardRules.RARITY_RARE,
		"cost": 3,
		"effect_text": "Infliggi 4 danni. Il prossimo intento offensivo del nemico infligge -4 danni.",
		"effects": {"damage": 4, "damage_per_level": 1, "weaken_next_intent": 4},
	},
	{
		"id": "ranger_cold_moon_hunt",
		"name": "Caccia della Luna Fredda",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_RANGER,
		"rarity": CardRules.RARITY_LEGENDARY,
		"cost": 8,
		"effect_text": "Infliggi 6 danni e applichi 8 veleno. Se il nemico e gia avvelenato, lo marchi.",
		"effects": {"damage": 6, "damage_per_level": 2, "poison": 8, "poison_per_level": 1, "mark_if_poisoned": true},
	},
	{
		"id": "mage_occult_dart",
		"name": "Dardo Occulto",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_MAGE,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 2,
		"effect_text": "Infliggi 6 danni.",
		"effects": {"damage": 6, "damage_per_level": 2},
	},
	{
		"id": "mage_wax_sigil",
		"name": "Sigillo di Cera",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_MAGE,
		"rarity": CardRules.RARITY_UNCOMMON,
		"cost": 1,
		"effect_text": "Guadagni 1 cera temporanea. La prossima carta Mago infligge +2 danni.",
		"effects": {"temporary_cera": 1, "next_mage_damage_bonus": 2},
	},
	{
		"id": "mage_black_flame",
		"name": "Fiamma Nera",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_MAGE,
		"rarity": CardRules.RARITY_RARE,
		"cost": 3,
		"effect_text": "Infliggi 5 danni e applichi 3 bruciatura.",
		"effects": {"damage": 5, "damage_per_level": 2, "burn": 3, "burn_per_level": 1},
	},
	{
		"id": "mage_black_sun",
		"name": "Sole Nero",
		"type": CardRules.TYPE_BUILD,
		"class_id": CardRules.CLASS_MAGE,
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
	return CLASSES.get(class_id, CLASSES[CardRules.CLASS_NEUTRAL]).get("name", "Senzaclasse")


static func get_base_stamina_cost(card: Dictionary, active_class: String) -> int:
	var cost = int(card.get("cost", 0))
	if CardRules.is_off_class(card, active_class):
		cost += CardRules.out_of_class_penalty(card.get("rarity", CardRules.RARITY_COMMON))
	return cost


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
