extends Node2D

var start_point := Vector2.ZERO
var end_point := Vector2.ZERO
var color := Color(1.0, 0.82, 0.4, 1.0)
var lifetime := 0.09
var max_lifetime := 0.09
var width := 3.0

func setup(from: Vector2, to: Vector2, tint: Color, life := 0.09, line_width := 3.0) -> void:
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
    var alpha := clampf(lifetime / max_lifetime, 0.0, 1.0)
    var c := Color(color.r, color.g, color.b, color.a * alpha)
    draw_line(start_point, end_point, c, width, true)
