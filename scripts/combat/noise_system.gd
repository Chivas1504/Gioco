class_name NoiseSystem
extends RefCounted


const INVALID_CELL := Vector2i(-1, -1)

const DEFAULT_WORLD_NOISE_DURATION := 0.35


var last_noise_cell: Vector2i = INVALID_CELL
var has_noise: bool = false


var last_world_noise_position: Vector2 = Vector2.ZERO
var has_world_noise: bool = false
var world_noise_remaining: float = 0.0


func emit_noise(
	cell: Vector2i
) -> void:
	last_noise_cell = cell
	has_noise = true


func clear_noise() -> void:
	last_noise_cell = INVALID_CELL
	has_noise = false


func has_active_noise() -> bool:
	return has_noise


func get_last_noise_cell() -> Vector2i:
	return last_noise_cell


func emit_world_noise(
	world_position: Vector2,
	duration: float = DEFAULT_WORLD_NOISE_DURATION
) -> void:
	last_world_noise_position = world_position
	has_world_noise = true
	world_noise_remaining = duration


func clear_world_noise() -> void:
	has_world_noise = false
	world_noise_remaining = 0.0


func has_active_world_noise() -> bool:
	return has_world_noise


func get_last_world_noise_position() -> Vector2:
	return last_world_noise_position


func tick(
	delta: float
) -> void:
	if not has_world_noise:
		return

	world_noise_remaining -= delta

	if world_noise_remaining <= 0.0:
		clear_world_noise()
