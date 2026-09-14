class_name RunState
extends RefCounted

var player_level := 1
var max_health := CardRules.STARTING_HEALTH
var health := CardRules.STARTING_HEALTH
var max_stamina := CardRules.STARTING_STAMINA
var stamina := CardRules.STARTING_STAMINA

var active_class := CardRules.CLASS_NEUTRAL
var acquired_classes: Array[String] = []
var collection: Array[String] = []
var loadout: Array[String] = []
var consumable_slots: Array[String] = []
var card_levels := {}
var artifacts: Array[String] = []

var materials := {
	"anime": 0,
	"sangue": 0,
	"ossa": 0,
	"cera": 0,
	"argento": 0,
	"cenere": 0,
	"frammenti_lunari": 0,
}

func start_new_run() -> void:
	player_level = 1
	max_health = CardRules.STARTING_HEALTH
	health = max_health
	max_stamina = CardRules.STARTING_STAMINA
	stamina = max_stamina
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
	materials = {
		"anime": 0,
		"sangue": 0,
		"ossa": 0,
		"cera": 0,
		"argento": 0,
		"cenere": 0,
		"frammenti_lunari": 0,
	}


func acquire_card(card_id: String) -> bool:
	if collection.size() >= CardRules.COLLECTION_MAX:
		return false
	if GameDatabase.get_card(card_id).is_empty():
		return false
	collection.append(card_id)
	card_levels[card_id] = int(card_levels.get(card_id, 0))

	var card := GameDatabase.get_card(card_id)
	var card_class := card.get("class_id", CardRules.CLASS_NEUTRAL)
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
	var cost := next_level_cost()
	if get_material("anime") < cost:
		return false
	spend_material("anime", cost)
	level_up(card_id)
	return true


func level_up(card_id: String) -> void:
	player_level += 1
	if max_health < CardRules.STAT_CAP:
		var health_gain := min(CardRules.LEVEL_STAT_GAIN, CardRules.STAT_CAP - max_health)
		max_health += health_gain
		health = min(max_health, health + health_gain)
	if max_stamina < CardRules.STAT_CAP:
		var stamina_gain := min(CardRules.LEVEL_STAT_GAIN, CardRules.STAT_CAP - max_stamina)
		max_stamina += stamina_gain
		stamina = min(max_stamina, stamina + stamina_gain)
	if collection.has(card_id):
		card_levels[card_id] = get_card_level(card_id) + 1


func get_world_level() -> int:
	return GameDatabase.get_world_level(collection, card_levels)


func is_dead() -> bool:
	return health <= 0 or stamina <= 0
