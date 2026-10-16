extends Node2D

var aim_dir := Vector2.RIGHT
var shield_active := false
var kick_amount := 0.0
var muzzle_flash_time := 0.0
var recoil_flash_time := 0.0
var reload_pulse := 0.0

const BODY_MAIN := Color("#26384a")
const BODY_DARK := Color("#16212e")
const BODY_ACCENT := Color("#d8a347")
const SKIN := Color("#cf9d7b")
const GUN_DARK := Color("#20242a")
const GUN_METAL := Color("#6f7984")
const SHIELD_MAIN := Color("#43586d")
const SHIELD_EDGE := Color("#bcc7d0")

func trigger_fire(recoil_mode := false) -> void:
    kick_amount = 1.0
    muzzle_flash_time = 0.07 if not recoil_mode else 0.1
    recoil_flash_time = 0.12 if recoil_mode else 0.0
    queue_redraw()

func trigger_reload() -> void:
    reload_pulse = 1.0

func _process(delta: float) -> void:
    # Runs after Camera2D has scrolled, so the gun tracks this frame's cursor.
    # Gameplay shot direction is sampled separately in SG's 60 Hz physics loop.
    var raw := get_global_mouse_position() - (global_position + Vector2(0, -116))
    if raw.length_squared() > 0.001:
        aim_dir = raw.normalized()
    kick_amount = move_toward(kick_amount, 0.0, delta * 7.5)
    muzzle_flash_time = maxf(0.0, muzzle_flash_time - delta)
    recoil_flash_time = maxf(0.0, recoil_flash_time - delta)
    reload_pulse = move_toward(reload_pulse, 0.0, delta * 5.0)
    queue_redraw()

func _draw() -> void:
    var facing := 1.0 if aim_dir.x >= 0.0 else -1.0

    # Ground shadow.
    _draw_shadow_ellipse(Vector2(0, -3), Vector2(42, 9), Color(0, 0, 0, 0.3), 20)

    # Legs: intentionally simple procedural placeholder, not final character art.
    draw_polygon(PackedVector2Array([
        Vector2(-27, -57), Vector2(-4, -57), Vector2(-7, -8), Vector2(-28, -8)
    ]), PackedColorArray([BODY_DARK]))
    draw_polygon(PackedVector2Array([
        Vector2(4, -57), Vector2(27, -57), Vector2(28, -8), Vector2(7, -8)
    ]), PackedColorArray([BODY_DARK]))
    draw_rect(Rect2(-31, -13, 31, 13), Color("#111820"))
    draw_rect(Rect2(4, -13, 31, 13), Color("#111820"))

    # Torso and armor silhouette: broad-shouldered SG prototype.
    draw_polygon(PackedVector2Array([
        Vector2(-43, -126), Vector2(-30, -146), Vector2(30, -146), Vector2(43, -126),
        Vector2(33, -65), Vector2(-33, -65)
    ]), PackedColorArray([BODY_MAIN]))
    draw_rect(Rect2(-35, -119, 70, 18), BODY_ACCENT)
    draw_rect(Rect2(-42, -143, 16, 25), BODY_DARK)
    draw_rect(Rect2(26, -143, 16, 25), BODY_DARK)

    # Head.
    draw_circle(Vector2(0, -168), 20, SKIN)
    draw_rect(Rect2(-20, -183, 40, 10), BODY_DARK)
    draw_line(Vector2(5 * facing, -168), Vector2(17 * facing, -168), Color("#2b201c"), 3.0)

    # Shield remains a left/right frontal tool; vertical aiming does not rotate it around the body.
    if shield_active:
        var sx := 54.0 * facing
        var shield_points := PackedVector2Array([
            Vector2(sx - 14 * facing, -139),
            Vector2(sx + 23 * facing, -126),
            Vector2(sx + 27 * facing, -75),
            Vector2(sx, -48),
            Vector2(sx - 21 * facing, -72)
        ])
        draw_polygon(shield_points, PackedColorArray([SHIELD_MAIN]))
        for i in range(shield_points.size()):
            draw_line(shield_points[i], shield_points[(i + 1) % shield_points.size()], SHIELD_EDGE, 4.0)

    # Arms + shotgun are independent from the body and follow the free aim angle.
    var pivot := Vector2(0, -116)
    var angle := aim_dir.angle()
    draw_set_transform(pivot, angle, Vector2.ONE)
    var kick_px := kick_amount * 12.0
    draw_line(Vector2(-7 - kick_px, 0), Vector2(30 - kick_px, 0), SKIN, 11.0)
    draw_rect(Rect2(16 - kick_px, -8, 82, 16), GUN_DARK)
    draw_rect(Rect2(34 - kick_px, -5, 72, 10), GUN_METAL)
    draw_rect(Rect2(73 - kick_px, -10, 23, 20), BODY_ACCENT)
    draw_rect(Rect2(-8 - kick_px, -10, 28, 20), Color("#5a3d2b"))

    if reload_pulse > 0.0:
        draw_circle(Vector2(22, 16), 5.0 + 4.0 * reload_pulse, Color(0.95, 0.78, 0.35, reload_pulse))

    if muzzle_flash_time > 0.0:
        var flash_scale := 1.0 + muzzle_flash_time * 5.0
        draw_polygon(PackedVector2Array([
            Vector2(102 - kick_px, 0),
            Vector2(126 - kick_px, -12 * flash_scale),
            Vector2(119 - kick_px, 0),
            Vector2(126 - kick_px, 12 * flash_scale)
        ]), PackedColorArray([Color("#ffd76a")]))
        draw_circle(Vector2(105 - kick_px, 0), 9.0 * flash_scale, Color(1.0, 0.55, 0.16, 0.8))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

    if recoil_flash_time > 0.0:
        var a := recoil_flash_time / 0.12
        draw_arc(Vector2.ZERO, 64.0 + (1.0 - a) * 35.0, 0.0, TAU, 32, Color(0.8, 0.9, 1.0, a * 0.65), 4.0)

func _draw_shadow_ellipse(center: Vector2, radii: Vector2, tint: Color, segments: int) -> void:
    var points := PackedVector2Array()
    for i in range(segments):
        var t := TAU * float(i) / float(segments)
        points.append(center + Vector2(cos(t) * radii.x, sin(t) * radii.y))
    draw_polygon(points, PackedColorArray([tint]))
