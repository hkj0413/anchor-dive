extends Node2D

var start_point: Vector2 = Vector2.ZERO
var end_point: Vector2 = Vector2.ZERO
var color: Color = Color(1.0, 0.82, 0.4, 1.0)
var lifetime: float = 0.09
var max_lifetime: float = 0.09
var width: float = 3.0

func setup(from: Vector2, to: Vector2, tint: Color, life: float = 0.09, line_width: float = 3.0) -> void:
	start_point = from
	end_point = to
	color = tint
	lifetime = life
	max_lifetime = life
	width = line_width
	queue_redraw()

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var alpha: float = clampf(lifetime / max_lifetime, 0.0, 1.0)
	var line_color: Color = Color(color.r, color.g, color.b, color.a * alpha)
	draw_line(start_point, end_point, line_color, width, true)
