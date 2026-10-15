extends Node2D

const SGScript = preload("res://prototype_sg/scripts/sg.gd")
const HudScript = preload("res://prototype_sg/scripts/hud.gd")

var player: CharacterBody2D

func _ready() -> void:
    RenderingServer.set_default_clear_color(Color("#101621"))
    _setup_input_actions()
    _build_test_stage()
    _spawn_player()
    _spawn_hud()
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _exit_tree() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _setup_input_actions() -> void:
    _add_key_action("move_left", KEY_A)
    _add_key_action("move_right", KEY_D)
    _add_key_action("move_down", KEY_S)
    _add_key_action("jump", KEY_SPACE)
    _add_key_action("shield", KEY_SHIFT)
    _add_key_action("reload", KEY_R)
    _add_mouse_action("attack", MOUSE_BUTTON_LEFT)
    _add_mouse_action("recoil", MOUSE_BUTTON_RIGHT)

func _add_key_action(action: StringName, keycode: Key) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    if InputMap.action_get_events(action).is_empty():
        var event := InputEventKey.new()
        event.physical_keycode = keycode
        InputMap.action_add_event(action, event)

func _add_mouse_action(action: StringName, button: MouseButton) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    if InputMap.action_get_events(action).is_empty():
        var event := InputEventMouseButton.new()
        event.button_index = button
        InputMap.action_add_event(action, event)

func _build_test_stage() -> void:
    # The test course exists only to evaluate movement, aim, jump, recoil and shield mobility.
    _add_platform(Rect2(0, 900, 3900, 180), Color("#273241"), false)
    _add_platform(Rect2(0, -200, 90, 1300), Color("#202b38"), false)
    _add_platform(Rect2(3810, -200, 90, 1300), Color("#202b38"), false)

    _add_platform(Rect2(430, 760, 330, 26), Color("#526273"), true)
    _add_platform(Rect2(900, 640, 300, 26), Color("#526273"), true)
    _add_platform(Rect2(1260, 520, 260, 26), Color("#526273"), true)
    _add_platform(Rect2(1590, 720, 360, 30), Color("#6a5a46"), false)
    _add_platform(Rect2(2110, 610, 390, 30), Color("#6a5a46"), false)
    _add_platform(Rect2(2650, 470, 320, 26), Color("#526273"), true)
    _add_platform(Rect2(3110, 700, 420, 30), Color("#6a5a46"), false)

    # Low ceiling section for jump/aim readability testing.
    _add_platform(Rect2(1990, 385, 620, 30), Color("#313d4d"), false)

    # Simple visual markers for distances without using any external assets.
    for x in range(300, 3700, 300):
        var marker := Polygon2D.new()
        marker.polygon = PackedVector2Array([
            Vector2(x - 2, 865), Vector2(x + 2, 865), Vector2(x + 2, 900), Vector2(x - 2, 900)
        ])
        marker.color = Color(0.5, 0.62, 0.75, 0.26)
        add_child(marker)

func _add_platform(rect: Rect2, tint: Color, one_way: bool) -> void:
    var body := StaticBody2D.new()
    body.position = rect.position + rect.size * 0.5
    body.collision_layer = 1
    body.collision_mask = 0
    if one_way:
        body.add_to_group("one_way")
    add_child(body)

    var collision := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = rect.size
    collision.shape = shape
    collision.one_way_collision = one_way
    collision.one_way_collision_margin = 8.0
    body.add_child(collision)

    var poly := Polygon2D.new()
    var half := rect.size * 0.5
    poly.polygon = PackedVector2Array([
        Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
        Vector2(half.x, half.y), Vector2(-half.x, half.y)
    ])
    poly.color = tint
    body.add_child(poly)

func _spawn_player() -> void:
    player = SGScript.new()
    player.name = "SG"
    player.global_position = Vector2(260, 900)
    add_child(player)

func _spawn_hud() -> void:
    var hud := HudScript.new()
    add_child(hud)
    hud.bind_player(player)
