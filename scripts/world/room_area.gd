class_name RoomArea
extends Area2D


signal player_entered_room(room_id: String)
signal player_exited_room(room_id: String)


@export var room_id: String = ""


func _ready() -> void:
	add_to_group("room_areas")

	monitoring = true
	monitorable = true

	body_entered.connect(
		_on_body_entered
	)

	body_exited.connect(
		_on_body_exited
	)

	print(
		"RoomArea pronta: ",
		room_id
	)


func _on_body_entered(
	body: Node2D
) -> void:
	if body is CharacterBody2D:
		print(
			"Player rilevato dentro ",
			room_id
		)

		player_entered_room.emit(
			room_id
		)


func _on_body_exited(
	body: Node2D
) -> void:
	if body is CharacterBody2D:
		print(
			"Player uscito da ",
			room_id
		)

		player_exited_room.emit(
			room_id
		)
