extends Control

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    var p := get_viewport().get_mouse_position()
    var c := Color(0.92, 0.95, 1.0, 0.92)
    draw_circle(p, 5.0, Color(0.08, 0.1, 0.14, 0.75))
    draw_arc(p, 9.0, 0.0, TAU, 24, c, 2.0)
    draw_line(p + Vector2(-16, 0), p + Vector2(-6, 0), c, 2.0)
    draw_line(p + Vector2(6, 0), p + Vector2(16, 0), c, 2.0)
    draw_line(p + Vector2(0, -16), p + Vector2(0, -6), c, 2.0)
    draw_line(p + Vector2(0, 6), p + Vector2(0, 16), c, 2.0)
