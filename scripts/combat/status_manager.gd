class_name StatusManager
extends RefCounted


const BLEEDING := "Sanguinamento"
const FRACTURE := "Frattura"
const BURN := "Ustione"
const STUN := "Stordimento"
const IMMOBILIZED := "Immobilizzato"
const BLINDED := "Accecato"
const SLOWED := "Rallentato"
const MARKED := "Marcato"

const MAX_BLEEDING_STACKS := 3
const BLEEDING_DURATION := 3


var statuses: Dictionary = {}
var fractures: Dictionary = {}


func add_status(
	status_name: String,
	duration: int = 1,
	stacks: int = 1
) -> void:
	if status_name == BLEEDING:
		_add_bleeding(stacks)
		return

	if status_name == FRACTURE:
		return

	if status_name == MARKED:
		statuses[MARKED] = {
			"duration": -1,
			"stacks": 1
		}
		return

	var current_duration: int = 0

	if statuses.has(status_name):
		var current: Dictionary = statuses[status_name]
		current_duration = int(
			current.get("duration", 0)
		)

	statuses[status_name] = {
		"duration": maxi(
			current_duration,
			duration
		),
		"stacks": maxi(stacks, 1)
	}


func _add_bleeding(stacks_to_add: int) -> void:
	var current_stacks: int = 0

	if statuses.has(BLEEDING):
		var current: Dictionary = statuses[BLEEDING]

		current_stacks = int(
			current.get("stacks", 0)
		)

	var new_stacks: int = mini(
		current_stacks + stacks_to_add,
		MAX_BLEEDING_STACKS
	)

	statuses[BLEEDING] = {
		"duration": BLEEDING_DURATION,
		"stacks": new_stacks
	}


func add_fracture(part_name: String) -> void:
	if part_name.is_empty():
		return

	fractures[part_name] = true


func has_fracture(part_name: String) -> bool:
	return fractures.has(part_name)


func remove_fracture(part_name: String) -> void:
	fractures.erase(part_name)


func has_status(status_name: String) -> bool:
	return statuses.has(status_name)


func get_stacks(status_name: String) -> int:
	if not statuses.has(status_name):
		return 0

	var status: Dictionary = statuses[status_name]

	return int(
		status.get("stacks", 0)
	)


func get_duration(status_name: String) -> int:
	if not statuses.has(status_name):
		return 0

	var status: Dictionary = statuses[status_name]

	return int(
		status.get("duration", 0)
	)


func begin_activation() -> Dictionary:
	var result: Dictionary = {
		"burn_damage": 0,
		"stunned": false
	}

	if has_status(BURN):
		result["burn_damage"] = 2

	if has_status(STUN):
		result["stunned"] = true

		# Stordimento vale soltanto
		# per questa attivazione.
		statuses.erase(STUN)

	return result


func end_activation() -> Dictionary:
	var result: Dictionary = {
		"bleeding_damage": 0
	}

	if has_status(BLEEDING):
		result["bleeding_damage"] = (
			get_stacks(BLEEDING)
		)

	_tick_durations()

	return result


func _tick_durations() -> void:
	var names: Array = statuses.keys()

	for status_name_variant in names:
		var status_name: String = str(
			status_name_variant
		)

		if status_name == MARKED:
			continue

		if status_name == STUN:
			continue

		var status: Dictionary = statuses[
			status_name
		]

		var duration: int = int(
			status.get("duration", 0)
		)

		if duration < 0:
			continue

		duration -= 1

		if duration <= 0:
			statuses.erase(status_name)
		else:
			status["duration"] = duration
			statuses[status_name] = status


func consume_marked() -> bool:
	if not has_status(MARKED):
		return false

	statuses.erase(MARKED)
	return true


func is_immobilized() -> bool:
	return has_status(IMMOBILIZED)


func is_blinded() -> bool:
	return has_status(BLINDED)


func is_slowed() -> bool:
	return has_status(SLOWED)


func clear_all() -> void:
	statuses.clear()
	fractures.clear()


func get_status_summary() -> Array[String]:
	var result: Array[String] = []

	for status_name_variant in statuses.keys():
		var status_name: String = str(
			status_name_variant
		)

		if status_name == BLEEDING:
			result.append(
				status_name
				+ " x"
				+ str(
					get_stacks(status_name)
				)
				+ " ("
				+ str(
					get_duration(status_name)
				)
				+ ")"
			)

		elif status_name == MARKED:
			result.append(status_name)

		else:
			result.append(
				status_name
				+ " ("
				+ str(
					get_duration(status_name)
				)
				+ ")"
			)

	for part_name_variant in fractures.keys():
		var part_name: String = str(
			part_name_variant
		)

		result.append(
			"Frattura: "
			+ part_name
		)

	return result
