class_name RoomDatabase
extends RefCounted


const LIMBO_ROOM_A := "limbo_room_a"
const LIMBO_ROOM_B := "limbo_room_b"


static func get_room(
	room_id: String
) -> RoomData:
	match room_id:
		LIMBO_ROOM_A:
			return _create_limbo_room_a()

		LIMBO_ROOM_B:
			return _create_limbo_room_b()

		_:
			push_error(
				"Stanza sconosciuta: "
				+ room_id
			)

			return null


static func get_limbo_test_rooms() -> Array[RoomData]:
	return [
		_create_limbo_room_a(),
		_create_limbo_room_b()
	]


static func _create_limbo_room_a() -> RoomData:
	return RoomData.new(
		LIMBO_ROOM_A,
		"Camera dei Condannati",
		[
			"room_a"
		],
		false,
		false,
		true
	)


static func _create_limbo_room_b() -> RoomData:
	return RoomData.new(
		LIMBO_ROOM_B,
		"Camera del Sordo",
		[
			"room_b"
		],
		false,
		false,
		true
	)
