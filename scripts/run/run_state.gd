class_name RunState
extends RefCounted

var player_level = 1
var max_health = CardRules.STARTING_HEALTH
var health = CardRules.STARTING_HEALTH
var max_stamina = CardRules.STARTING_STAMINA
var stamina = CardRules.STARTING_STAMINA

var active_class = CardRules.CLASS_NEUTRAL
var acquired_classes: Array = []
var collection: Array = []
var loadout: Array = []
var consumable_slots: Array = []
var card_levels = {}
var artifacts: Array = []
var special_upgrades: Array = []

var fear = 0
var combats_since_level_up = 0
var shadow_memory = {}
var shadow_first_encounter_fled = false
var shadow_defeated = false

var materials = {
	"anime": 0,
	"sangue": 0,
	"ossa": 0,
	"cera": 0,
	"argento": 0,
	"cenere": 0,
	"frammenti_lunari": 0,
}

func start_new_run(keep_shadow: bool = true) -> void:
	var preserved_shadow = shadow_memory.duplicate(true)
	var preserved_shadow_fled = shadow_first_encounter_fled
	var preserved_shadow_defeated = shadow_defeated
	player_level = 1
	max_health = CardRules.STARTING_HEALTH
	health = max_health
	max_stamina = CardRules.STARTING_STAMINA
	stamina = max_stamina
	fear = 0
	combats_since_level_up = 0
	active_class = CardRules.CLASS_NEUTRAL
	acquired_classes = []
	collection = [
		"neutral_rough_strike",
		"neutral_parry",
		"neutral_dodge",
		"neutral_catch_breath",
	]
	loadout = collection.duplicate()
	consumable_slots = []
	card_levels = {}
	artifacts = []
	special_upgrades = []
	materials = {
		"anime": 0,
		"sangue": 0,
		"ossa": 0,
		"cera": 0,
		"argento": 0,
		"cenere": 0,
		"frammenti_lunari": 0,
	}
	if keep_shadow:
		shadow_memory = preserved_shadow
		shadow_first_encounter_fled = preserved_shadow_fled
		shadow_defeated = preserved_shadow_defeated
	else:
		shadow_memory = {}
		shadow_first_encounter_fled = false
		shadow_defeated = false


func acquire_card(card_id: String) -> bool:
	if collection.size() >= CardRules.COLLECTION_MAX:
		return false
	if GameDatabase.get_card(card_id).is_empty():
		return false
	collection.append(card_id)
	card_levels[card_id] = int(card_levels.get(card_id, 0))

	var card = GameDatabase.get_card(card_id)
	var card_class = card.get("class_id", CardRules.CLASS_NEUTRAL)
	if card_class != CardRules.CLASS_NEUTRAL and not acquired_classes.has(card_class):
		acquired_classes.append(card_class)
		if active_class == CardRules.CLASS_NEUTRAL:
			active_class = card_class

	if loadout.size() < CardRules.LOADOUT_MAX:
		loadout.append(card_id)
	return true


func set_active_class(class_id: String) -> bool:
	if class_id == CardRules.CLASS_NEUTRAL:
		active_class = class_id
		return true
	if not acquired_classes.has(class_id):
		return false
	active_class = class_id
	return true


func add_material(material_id: String, amount: int) -> void:
	materials[material_id] = int(materials.get(material_id, 0)) + amount


func get_material(material_id: String) -> int:
	return int(materials.get(material_id, 0))


func spend_material(material_id: String, amount: int) -> bool:
	if get_material(material_id) < amount:
		return false
	materials[material_id] = get_material(material_id) - amount
	return true


func get_card_level(card_id: String) -> int:
	return int(card_levels.get(card_id, 0))


func next_level_cost() -> int:
	return 40 + player_level * 20


func buy_level_up(card_id: String) -> bool:
	var cost = next_level_cost()
	if get_material("anime") < cost:
		return false
	spend_material("anime", cost)
	level_up(card_id)
	return true


func level_up(card_id: String) -> void:
	player_level += 1
	combats_since_level_up = 0
	if max_health < CardRules.STAT_CAP:
		var health_gain = min(CardRules.LEVEL_STAT_GAIN, CardRules.STAT_CAP - max_health)
		max_health += health_gain
		health = min(max_health, health + health_gain)
	if max_stamina < CardRules.STAT_CAP:
		var stamina_gain = min(CardRules.LEVEL_STAT_GAIN, CardRules.STAT_CAP - max_stamina)
		max_stamina += stamina_gain
		stamina = min(max_stamina, stamina + stamina_gain)
	if collection.has(card_id):
		card_levels[card_id] = get_card_level(card_id) + 1


func get_world_level() -> int:
	return GameDatabase.get_world_level(collection, card_levels)


func is_dead() -> bool:
	return health <= 0 or stamina <= 0


func add_fear(amount: int) -> int:
	fear = clamp(fear + amount, 0, CardRules.FEAR_MAX)
	return fear


func is_low_health() -> bool:
	return health <= floori(float(max_health) * CardRules.FEAR_LOW_HEALTH_THRESHOLD)


func register_combat_without_level_up() -> String:
	combats_since_level_up += 1
	if combats_since_level_up < CardRules.FEAR_NO_LEVEL_COMBAT_LIMIT:
		return ""
	add_fear(CardRules.FEAR_NO_LEVEL_GAIN)
	combats_since_level_up = 0
	return "Non sali di livello da troppo: la paura aumenta a %d." % fear


func create_shadow_from_current_run() -> Dictionary:
	var lost_souls = get_material("anime")
	shadow_memory = {
		"active_class": active_class,
		"collection": collection.duplicate(),
		"loadout": loadout.duplicate(),
		"card_levels": card_levels.duplicate(true),
		"player_level": player_level,
		"world_level": get_world_level(),
		"lost_souls": lost_souls,
		"max_health": max_health,
		"max_stamina": max_stamina,
	}
	shadow_first_encounter_fled = false
	shadow_defeated = false
	materials["anime"] = 0
	return shadow_memory


func has_shadow() -> bool:
	return not shadow_memory.is_empty() and not shadow_defeated


func can_start_first_shadow_encounter() -> bool:
	return has_shadow() and not shadow_first_encounter_fled


func can_start_forced_shadow_encounter() -> bool:
	return has_shadow() and shadow_first_encounter_fled and fear >= CardRules.FEAR_SHADOW_RETURN_THRESHOLD


func flee_shadow() -> int:
	shadow_first_encounter_fled = true
	return add_fear(CardRules.FEAR_SHADOW_ESCAPE_GAIN)


func claim_shadow_victory(second_encounter: bool, upgrade_id: String) -> int:
	var recovered_souls = int(shadow_memory.get("lost_souls", 0))
	add_material("anime", recovered_souls)
	shadow_defeated = true
	shadow_first_encounter_fled = false
	shadow_memory = {}
	if not special_upgrades.has(upgrade_id):
		special_upgrades.append(upgrade_id)
	if second_encounter:
		fear = max(0, fear - 50)
	return recovered_souls
