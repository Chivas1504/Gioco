class_name CardData
extends Resource


var card_name: String = ""

var action_cost: int = 1
var effort_generated: int = 0

var damage: int = 0
var healing: int = 0

var tags: Array[String] = []


# Stato applicato quando la carta colpisce.
# La probabilita puo cambiare in base
# alla situazione del bersaglio.
var status_to_apply: String = ""
var status_duration: int = 0
var status_stacks: int = 1
var status_chance: float = 0.0
var marked_status_bonus: float = 0.0
var conditional_status_name: String = ""
var conditional_status_bonus: float = 0.0


# Alcune carte possono applicare Frattura
# alla parte selezionata. La probabilita
# viene calcolata dal combattimento usando
# l'integrita residua della parte.
var fracture_selected_part: bool = false


# Requisito da finisher: 0.20 significa
# usabile solo sotto il 20% di Vitalita.
var low_vitality_required_ratio: float = 0.0


# Reazioni preparate senza finestre di timing.
var reaction_block: int = 0
var reaction_effort_relief: int = 0


func _init(
	new_name: String = "",
	new_action_cost: int = 1,
	new_effort_generated: int = 0,
	new_damage: int = 0,
	new_healing: int = 0,
	new_tags: Array[String] = []
) -> void:
	card_name = new_name
	action_cost = new_action_cost
	effort_generated = new_effort_generated

	damage = new_damage
	healing = new_healing

	tags = new_tags


func uses_body_target() -> bool:
	return (
		"Mira" in tags
		or fracture_selected_part
	)


func is_reaction() -> bool:
	return (
		"Reazione" in tags
		or reaction_block > 0
	)
