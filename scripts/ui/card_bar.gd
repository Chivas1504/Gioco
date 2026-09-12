class_name CardBar
extends HBoxContainer


signal card_selected(card: CardData)


var card_buttons: Dictionary = {}


func set_cards(
	cards: Array[CardData]
) -> void:
	_clear_cards()

	for card in cards:
		if card == null:
			continue

		var button: CardButton = (
			CardButton.new()
		)

		button.setup(card)

		button.card_clicked.connect(
			_on_card_clicked
		)

		add_child(button)

		card_buttons[
			card.card_name
		] = button


func set_card_available(
	card: CardData,
	available: bool
) -> void:
	if card == null:
		return

	if not card_buttons.has(
		card.card_name
	):
		return

	var button: CardButton = (
		card_buttons[
			card.card_name
		]
	)

	button.set_card_available(
		available
	)


func _clear_cards() -> void:
	card_buttons.clear()

	for child in get_children():
		remove_child(child)
		child.queue_free()


func _on_card_clicked(
	card: CardData
) -> void:
	card_selected.emit(card)
