class_name CardData
extends Resource


var card_name: String = ""

var action_cost: int = 1

var damage: int = 0
var healing: int = 0

var attack_range: int = 0

var pull_distance: int = 0
var push_distance: int = 0

var tags: Array[String] = []


# Stato applicato normalmente quando la carta colpisce.
var status_to_apply: String = ""
var status_duration: int = 0
var status_stacks: int = 1


# Alcune carte possono applicare Frattura
# alla parte attualmente selezionata.
var fracture_selected_part: bool = false


# Stato applicato soltanto se l'effetto
# provoca una collisione contro un ostacolo.
var collision_status_to_apply: String = ""
var collision_status_duration: int = 0
var collision_status_stacks: int = 1


func _init(
	new_name: String = "",
	new_action_cost: int = 1,
	new_damage: int = 0,
	new_healing: int = 0,
	new_attack_range: int = 0,
	new_pull_distance: int = 0,
	new_push_distance: int = 0,
	new_tags: Array[String] = []
) -> void:
	card_name = new_name
	action_cost = new_action_cost

	damage = new_damage
	healing = new_healing

	attack_range = new_attack_range

	pull_distance = new_pull_distance
	push_distance = new_push_distance

	tags = new_tags
