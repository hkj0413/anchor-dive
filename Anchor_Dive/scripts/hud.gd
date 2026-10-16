extends CanvasLayer

const CrosshairScript = preload("res://scripts/crosshair.gd")

var player = null
var ammo_label: Label
var state_label: Label
var velocity_label: Label
var shield_bar: ProgressBar
var event_label: Label
var event_time := 0.0

func bind_player(value) -> void:
    player = value
    if player != null and player.has_signal("prototype_event"):
        player.connect("prototype_event", Callable(self, "_on_prototype_event"))

func _ready() -> void:
    layer = 20

    var panel := ColorRect.new()
    panel.position = Vector2(24, 24)
    panel.size = Vector2(560, 238)
    panel.color = Color(0.035, 0.05, 0.075, 0.88)
    add_child(panel)

    var title := Label.new()
    title.position = Vector2(22, 16)
    title.text = "SG PROTOTYPE / 1920×1080"
    title.add_theme_font_size_override("font_size", 26)
    panel.add_child(title)

    ammo_label = Label.new()
    ammo_label.position = Vector2(22, 58)
    ammo_label.add_theme_font_size_override("font_size", 30)
    panel.add_child(ammo_label)

    var shield_text := Label.new()
    shield_text.position = Vector2(22, 104)
    shield_text.text = "SHIELD"
    shield_text.add_theme_font_size_override("font_size", 18)
    panel.add_child(shield_text)

    shield_bar = ProgressBar.new()
    shield_bar.position = Vector2(120, 104)
    shield_bar.size = Vector2(400, 28)
    shield_bar.min_value = 0.0
    shield_bar.max_value = 100.0
    shield_bar.show_percentage = false
    panel.add_child(shield_bar)

    state_label = Label.new()
    state_label.position = Vector2(22, 145)
    state_label.add_theme_font_size_override("font_size", 18)
    panel.add_child(state_label)

    velocity_label = Label.new()
    velocity_label.position = Vector2(22, 174)
    velocity_label.add_theme_font_size_override("font_size", 17)
    panel.add_child(velocity_label)

    event_label = Label.new()
    event_label.position = Vector2(22, 203)
    event_label.add_theme_font_size_override("font_size", 16)
    event_label.modulate = Color(1.0, 0.82, 0.45)
    panel.add_child(event_label)

    var controls := Label.new()
    controls.position = Vector2(24, 985)
    controls.text = "A/D 이동   SPACE 점프   마우스 조준   LMB 공격   RMB 반동   SHIFT 방패   R 한발씩 장전   S+SPACE 발판 내려가기"
    controls.add_theme_font_size_override("font_size", 22)
    add_child(controls)

    var crosshair := CrosshairScript.new()
    add_child(crosshair)

func _process(delta: float) -> void:
    if not is_instance_valid(player):
        return

    ammo_label.text = "AMMO  %d / %d" % [player.ammo, player.max_ammo]
    shield_bar.max_value = player.shield_energy_max
    shield_bar.value = player.shield_energy

    var state_parts: Array[String] = []
    if player.shield_active:
        state_parts.append("방패 전개")
    if player.reloading:
        state_parts.append("장전 중")
    if player.is_on_floor():
        state_parts.append("지상")
    else:
        state_parts.append("공중")
    state_label.text = "STATE  " + " / ".join(state_parts)
    velocity_label.text = "VELOCITY  X %.0f   Y %.0f" % [player.velocity.x, player.velocity.y]

    event_time = maxf(0.0, event_time - delta)
    if event_time <= 0.0:
        event_label.text = ""

func _on_prototype_event(text: String) -> void:
    event_label.text = text
    event_time = 1.25
