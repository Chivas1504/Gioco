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
var last_victory_rewards = {}
var pending_thief_restart_rewards = {}

var fear = 0
var combats_since_level_up = 0
var normal_combat_victories = 0
var shadow_memory = {}
var shadow_first_encounter_fled = false
var shadow_defeated = false
var map_position = Vector2i(CardRules.START_MAP_X, CardRules.START_MAP_Y)
var final_boss_position = Vector2i(CardRules.FINAL_BOSS_X, CardRules.FINAL_BOSS_Y)
var map_nodes = {}
var current_node = {}
var game_won = false

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
	var preserved_thief_rewards = pending_thief_restart_rewards.duplicate(true)
	player_level = 1
	max_health = CardRules.STARTING_HEALTH
	health = max_health
	max_stamina = CardRules.STARTING_STAMINA
	stamina = max_stamina
	fear = 0
	combats_since_level_up = 0
	normal_combat_victories = 0
	map_position = Vector2i(CardRules.START_MAP_X, CardRules.START_MAP_Y)
	final_boss_position = Vector2i(CardRules.FINAL_BOSS_X, CardRules.FINAL_BOSS_Y)
	map_nodes = {}
	current_node = _get_or_create_node(map_position)
	current_node["resolved"] = true
	game_won = false
	active_class = CardRules.CLASS_NEUTRAL
	acquired_classes = []
	collection = [
		"neutral_rough_strike",
		"neutral_parry",
		"neutral_dodge",
		"neutral_catch_breath",
		"neutral_uncertain_lunge",
		"neutral_low_cut",
		"neutral_heavy_swing",
		"neutral_shield_bash",
	]
	loadout = collection.duplicate()
	consumable_slots = []
	card_levels = {}
	artifacts = []
	special_upgrades = []
	last_victory_rewards = {}
	pending_thief_restart_rewards = preserved_thief_rewards
	materials = {
		"anime": 0,
		"sangue": 0,
		"ossa": 0,
		"cera": 0,
		"argento": 0,
		"cenere": 0,
		"frammenti_lunari": 0,
	}
	_apply_pending_thief_restart_rewards()
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
	return health <= 0


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
	_prepare_thief_restart_rewards()
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


func record_victory_rewards(rewards: Dictionary) -> void:
	last_victory_rewards = rewards.duplicate(true)


func _prepare_thief_restart_rewards() -> void:
	if active_class != CardRules.CLASS_THIEF:
		return
	pending_thief_restart_rewards = {}
	for material_id in last_victory_rewards.keys():
		var reward = floori(float(int(last_victory_rewards.get(material_id, 0))) * 0.5)
		if reward > 0:
			pending_thief_restart_rewards[material_id] = reward


func _apply_pending_thief_restart_rewards() -> void:
	if pending_thief_restart_rewards.is_empty():
		return
	for material_id in pending_thief_restart_rewards.keys():
		add_material(String(material_id), int(pending_thief_restart_rewards.get(material_id, 0)))
	pending_thief_restart_rewards = {}


func get_pending_thief_restart_rewards() -> Dictionary:
	return pending_thief_restart_rewards.duplicate(true)


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


func move_to_direction(direction: String) -> Dictionary:
	var offset = Vector2i.ZERO
	if direction == "north":
		offset = Vector2i(0, -1)
	elif direction == "south":
		offset = Vector2i(0, 1)
	elif direction == "east":
		offset = Vector2i(1, 0)
	elif direction == "west":
		offset = Vector2i(-1, 0)
	map_position += offset
	current_node = _get_or_create_node(map_position)
	return current_node


func mark_current_node_resolved() -> void:
	if current_node.is_empty():
		return
	current_node["resolved"] = true
	map_nodes[_node_key(map_position)] = current_node
	if String(current_node.get("type", "")) == "class_boss":
		game_won = true


func get_current_node_name() -> String:
	if current_node.is_empty():
		return "Sconosciuto"
	return String(current_node.get("name", "Sconosciuto"))


func get_current_node_type() -> String:
	if current_node.is_empty():
		return "unknown"
	return String(current_node.get("type", "unknown"))


func get_distance_from_start() -> int:
	return abs(map_position.x - CardRules.START_MAP_X) + abs(map_position.y - CardRules.START_MAP_Y)


func get_distance_to_final_boss() -> int:
	return abs(map_position.x - final_boss_position.x) + abs(map_position.y - final_boss_position.y)


func _get_or_create_node(position: Vector2i) -> Dictionary:
	var key = _node_key(position)
	if map_nodes.has(key):
		var existing_node = map_nodes[key]
		if typeof(existing_node) == TYPE_DICTIONARY:
			return existing_node
		return {}
	var node = _generate_node(position)
	map_nodes[key] = node
	return node


func _generate_node(position: Vector2i) -> Dictionary:
	var distance = abs(position.x - CardRules.START_MAP_X) + abs(position.y - CardRules.START_MAP_Y)
	var node_type = "combat"
	var node_name = "Strada infestata"
	if position == Vector2i(CardRules.START_MAP_X, CardRules.START_MAP_Y):
		node_type = "campfire"
		node_name = "Falò iniziale"
	elif position == final_boss_position:
		node_type = "class_boss"
		node_name = "Soglia del Boss finale"
	else:
		var seed_value = abs(position.x * 92821 + position.y * 68917)
		if seed_value % 17 == 0 and distance > 3:
			node_type = "boss"
			node_name = "Tana del Boss"
		elif seed_value % 11 == 0 and distance > 2:
			node_type = "miniboss"
			node_name = "Covo del Mini-boss"
		elif seed_value % 5 == 0:
			node_type = "event"
			node_name = "Evento oscuro"

	return {
		"key": _node_key(position),
		"x": position.x,
		"y": position.y,
		"type": node_type,
		"name": node_name,
		"distance": distance,
		"resolved": false,
	}


func _node_key(position: Vector2i) -> String:
	return "%d,%d" % [position.x, position.y]
