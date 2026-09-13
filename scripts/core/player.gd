extends Node2D


const RADIUS := 20.0


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color.WHITE)
