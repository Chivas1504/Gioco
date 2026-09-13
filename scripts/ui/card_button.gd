class_name CardButton
extends Button


signal card_clicked(card: CardData)


var card_data: CardData


func _ready() -> void:
	pressed.connect(
		_on_pressed
	)

	custom_minimum_size = Vector2(
		0.0,
		115.0
	)
	
	size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL)


func setup(
	card: CardData
) -> void:
	card_data = card

	_update_card_text()
	_update_tooltip()


func set_card_available(
	available: bool
) -> void:
	disabled = not available


func _update_card_text() -> void:
	if card_data == null:
		text = "Carta"
		return

	var lines: Array[String] = []

	lines.append(
		card_data.card_name
	)

	lines.append(
		"PA: "
		+ str(card_data.action_cost)
	)

	if card_data.effort_generated != 0:
		var effort_prefix: String = "+"

		if card_data.effort_generated < 0:
			effort_prefix = ""

		lines.append(
			"Sforzo: "
			+ effort_prefix
			+ str(card_data.effort_generated)
		)

	if card_data.damage > 0:
		lines.append(
			"Danno: "
			+ str(card_data.damage)
		)

	if card_data.healing > 0:
		lines.append(
			"Cura: "
			+ str(card_data.healing)
		)

	var effect_text: String = (
		_get_effect_text()
	)

	if not effect_text.is_empty():
		lines.append(effect_text)

	text = "\n".join(lines)


func _update_tooltip() -> void:
	if card_data == null:
		tooltip_text = ""
		return

	var tooltip_lines: Array[String] = []

	if not card_data.tags.is_empty():
		tooltip_lines.append(
			"Tag: "
			+ ", ".join(card_data.tags)
		)

	var effect_text: String = (
		_get_effect_text()
	)

	if not effect_text.is_empty():
		tooltip_lines.append(
			"Effetto: "
			+ effect_text
		)

	if card_data.low_vitality_required_ratio > 0.0:
		tooltip_lines.append(
			"Richiede Vitalita bersaglio sotto "
			+ str(
				roundi(
					card_data.low_vitality_required_ratio
					* 100.0
				)
			)
			+ "%"
		)

	if card_data.reaction_block > 0:
		tooltip_lines.append(
			"Prepara una riduzione danno: "
			+ str(card_data.reaction_block)
		)

	tooltip_text = "\n".join(
		tooltip_lines
	)


func _get_effect_text() -> String:
	if card_data == null:
		return ""

	if card_data.fracture_selected_part:
		return "Frattura condizionale"

	if not card_data.status_to_apply.is_empty():
		var chance_text: String = ""

		if card_data.status_chance > 0.0:
			chance_text = (
				" "
				+ str(
					roundi(
						card_data.status_chance
						* 100.0
					)
				)
				+ "%"
			)

		if (
			card_data.status_to_apply
			== StatusManager.BLEEDING
		):
			return (
				"Sanguinamento +"
				+ str(
					card_data.status_stacks
				)
				+ chance_text
			)

		return (
			card_data.status_to_apply
			+ chance_text
		)

	if card_data.reaction_block > 0:
		return (
			"Reazione: -"
			+ str(card_data.reaction_block)
			+ " danno"
		)

	return ""


func _on_pressed() -> void:
	if card_data == null:
		return

	card_clicked.emit(
		card_data
	)
