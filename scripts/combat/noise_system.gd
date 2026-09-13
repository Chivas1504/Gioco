class_name NoiseSystem
extends RefCounted


var last_noise_cell: Vector2i = Vector2i(-1, -1)
var has_noise: bool = false


func emit_noise(
	cell: Vector2i
) -> void:
	last_noise_cell = cell
	has_noise = true


func clear_noise() -> void:
	last_noise_cell = Vector2i(-1, -1)
	has_noise = false


func has_active_noise() -> bool:
	return has_noise


func get_last_noise_cell() -> Vector2i:
	return last_noise_cell
