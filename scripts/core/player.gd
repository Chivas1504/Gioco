extends Node2D


const RADIUS := 20.0


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(
		Vector2(0.0, -18.0),
		15.0,
		Color(0.95, 0.86, 0.72)
	)

	draw_rect(
		Rect2(-16.0, -3.0, 32.0, 30.0),
		Color(0.86, 0.86, 0.86)
	)

	draw_circle(
		Vector2(-5.0, -20.0),
		2.0,
		Color.BLACK
	)

	draw_circle(
		Vector2(5.0, -20.0),
		2.0,
		Color.BLACK
	)

	draw_line(
		Vector2(-18.0, 28.0),
		Vector2(18.0, 28.0),
		Color.BLACK,
		3.0
	)
