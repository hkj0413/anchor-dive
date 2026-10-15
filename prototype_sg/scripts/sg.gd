extends CharacterBody2D

signal prototype_event(text: String)

const SGVisualScript = preload("res://prototype_sg/scripts/sg_visual.gd")
const TracerScript = preload("res://prototype_sg/scripts/tracer.gd")
const ShotAudio = preload("res://prototype_sg/audio/sg_attack.wav")
const RecoilAudio = preload("res://prototype_sg/audio/sg_recoil.wav")
const ReloadAudio = preload("res://prototype_sg/audio/sg_reload.wav")
const ShieldAudio = preload("res://prototype_sg/audio/sg_shield.wav")

# Prototype dimensions at the 1920x1080 reference resolution.
const COLLIDER_SIZE := Vector2(48, 110)
const BODY_VISUAL_HEIGHT := 175.0

var move_speed := 430.0
var acceleration := 2900.0
var friction := 3300.0
var air_control := 0.62
var gravity := 2450.0
var jump_speed := 900.0

var max_ammo := 6
var ammo := 6
var attack_interval := 0.42
var attack_timer := 0.0
var recoil_interval := 0.18
var recoil_timer := 0.0
var recoil_impulse := 900.0
var recoil_control_lock := 0.18
var recoil_lock_timer := 0.0
var reload_shell_time := 0.56
var reload_timer := 0.0
var reloading := false

var shield_energy_max := 100.0
var shield_energy := 100.0
var shield_drain_per_second := 40.0
var shield_recharge_per_second := 34.0
var shield_recharge_delay := 0.75
var shield_recharge_wait := 0.0
var shield_move_multiplier := 0.58
var shield_jump_multiplier := 0.76
var shield_recoil_multiplier := 0.55
var shield_active := false
var _shield_was_active := false

var aim_dir := Vector2.RIGHT
var spawn_position := Vector2.ZERO

var visual
var camera: Camera2D
var shot_audio: AudioStreamPlayer2D
var recoil_audio: AudioStreamPlayer2D
var reload_audio: AudioStreamPlayer2D
var shield_audio: AudioStreamPlayer2D

func _ready() -> void:
    spawn_position = global_position
    collision_layer = 2
    collision_mask = 1

    var collision := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = COLLIDER_SIZE
    collision.shape = shape
    collision.position = Vector2(0, -COLLIDER_SIZE.y * 0.5)
    add_child(collision)

    visual = SGVisualScript.new()
    add_child(visual)

    camera = Camera2D.new()
    camera.position = Vector2(0, -180)
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 8.0
    camera.limit_left = 0
    camera.limit_right = 3900
    camera.limit_top = -450
    camera.limit_bottom = 1180
    add_child(camera)
    camera.make_current()

    shot_audio = _make_audio_player(ShotAudio, -5.0)
    recoil_audio = _make_audio_player(RecoilAudio, -4.0)
    reload_audio = _make_audio_player(ReloadAudio, -8.0)
    shield_audio = _make_audio_player(ShieldAudio, -9.0)

func _make_audio_player(stream: AudioStream, volume_db: float) -> AudioStreamPlayer2D:
    var player := AudioStreamPlayer2D.new()
    player.stream = stream
    player.volume_db = volume_db
    player.max_distance = 1600.0
    add_child(player)
    return player

func _physics_process(delta: float) -> void:
    _update_aim()
    _update_timers(delta)
    _update_shield(delta)
    _update_reload(delta)
    _handle_actions()
    _handle_movement(delta)

    move_and_slide()

    if global_position.y > 1280.0:
        global_position = spawn_position
        velocity = Vector2.ZERO
        emit_signal("prototype_event", "낙하 리셋")

    _update_visual_and_camera(delta)

func _update_aim() -> void:
    var shoulder := global_position + Vector2(0, -116)
    var raw := get_global_mouse_position() - shoulder
    if raw.length_squared() > 0.001:
        aim_dir = raw.normalized()

func _update_timers(delta: float) -> void:
    attack_timer = maxf(0.0, attack_timer - delta)
    recoil_timer = maxf(0.0, recoil_timer - delta)
    recoil_lock_timer = maxf(0.0, recoil_lock_timer - delta)

func _update_shield(delta: float) -> void:
    var wants_shield := Input.is_action_pressed("shield")
    shield_active = wants_shield and shield_energy > 0.01

    if shield_active:
        shield_energy = maxf(0.0, shield_energy - shield_drain_per_second * delta)
        shield_recharge_wait = shield_recharge_delay
        if shield_energy <= 0.01:
            shield_active = false
    else:
        shield_recharge_wait = maxf(0.0, shield_recharge_wait - delta)
        if shield_recharge_wait <= 0.0:
            shield_energy = minf(shield_energy_max, shield_energy + shield_recharge_per_second * delta)

    if shield_active and not _shield_was_active:
        shield_audio.play()
    _shield_was_active = shield_active

func _update_reload(delta: float) -> void:
    if not reloading:
        return
    reload_timer -= delta
    if reload_timer > 0.0:
        return

    ammo = mini(max_ammo, ammo + 1)
    reload_audio.play()
    if visual:
        visual.trigger_reload()
    emit_signal("prototype_event", "장전 %d / %d" % [ammo, max_ammo])

    if ammo >= max_ammo:
        reloading = false
    else:
        reload_timer = reload_shell_time

func _handle_actions() -> void:
    if Input.is_action_just_pressed("reload"):
        _start_reload()

    if Input.is_action_pressed("attack") and attack_timer <= 0.0:
        _cancel_reload_for_action()
        _fire_attack()

    if Input.is_action_just_pressed("recoil") and recoil_timer <= 0.0:
        _cancel_reload_for_action()
        _fire_recoil()

func _handle_movement(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta

    if Input.is_action_just_pressed("jump"):
        if is_on_floor() and Input.is_action_pressed("move_down") and _standing_on_one_way():
            position.y += 28.0
            velocity.y = 180.0
        elif is_on_floor():
            var jump_mult := shield_jump_multiplier if shield_active else 1.0
            velocity.y = -jump_speed * jump_mult

    var axis := Input.get_axis("move_left", "move_right")
    var speed_mult := shield_move_multiplier if shield_active else 1.0
    var target_speed := axis * move_speed * speed_mult

    if recoil_lock_timer > 0.0:
        var drag := 520.0 if is_on_floor() else 180.0
        velocity.x = move_toward(velocity.x, 0.0, drag * delta)
        return

    var control := 1.0 if is_on_floor() else air_control
    if absf(axis) > 0.01:
        velocity.x = move_toward(velocity.x, target_speed, acceleration * control * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, friction * control * delta)

func _standing_on_one_way() -> bool:
    for i in range(get_slide_collision_count()):
        var hit := get_slide_collision(i)
        if hit.get_normal().y < -0.65:
            var collider := hit.get_collider()
            if collider is Node and collider.is_in_group("one_way"):
                return true
    return false

func _start_reload() -> void:
    if ammo >= max_ammo or reloading:
        return
    reloading = true
    reload_timer = reload_shell_time
    emit_signal("prototype_event", "장전 시작")

func _cancel_reload_for_action() -> void:
    if reloading:
        reloading = false
        emit_signal("prototype_event", "장전 중단")

func _fire_attack() -> void:
    if ammo <= 0:
        _start_reload()
        return

    ammo -= 1
    attack_timer = attack_interval
    shot_audio.play()
    if visual:
        visual.trigger_fire(false)

    var muzzle := global_position + Vector2(0, -116) + aim_dir * 108.0
    var space := get_world_2d().direct_space_state
    var pellet_count := 8
    var spread_radians := deg_to_rad(13.0)

    for _i in range(pellet_count):
        var offset := randf_range(-spread_radians * 0.5, spread_radians * 0.5)
        var dir := aim_dir.rotated(offset)
        var target := muzzle + dir * 1050.0
        var query := PhysicsRayQueryParameters2D.create(muzzle, target, 1, [get_rid()])
        var hit := space.intersect_ray(query)
        if not hit.is_empty():
            target = hit["position"]
        _spawn_tracer(muzzle, target, Color(1.0, 0.78, 0.31, 0.95), 2.8)

    emit_signal("prototype_event", "좌클릭 공격 | 탄약 %d / %d" % [ammo, max_ammo])

func _fire_recoil() -> void:
    if ammo <= 0:
        _start_reload()
        return

    ammo -= 1
    recoil_timer = recoil_interval
    recoil_lock_timer = recoil_control_lock
    recoil_audio.play()
    if visual:
        visual.trigger_fire(true)

    var impulse_mult := shield_recoil_multiplier if shield_active else 1.0
    var impulse := -aim_dir * recoil_impulse * impulse_mult
    velocity += impulse
    velocity.x = clampf(velocity.x, -1250.0, 1250.0)
    velocity.y = clampf(velocity.y, -1250.0, 1250.0)

    var muzzle := global_position + Vector2(0, -116) + aim_dir * 108.0
    _spawn_tracer(muzzle, muzzle + aim_dir * 220.0, Color(0.72, 0.9, 1.0, 0.9), 5.0)
    emit_signal("prototype_event", "우클릭 반동 | 탄약 %d / %d" % [ammo, max_ammo])

func _spawn_tracer(from: Vector2, to: Vector2, tint: Color, line_width: float) -> void:
    var tracer := TracerScript.new()
    get_tree().current_scene.add_child(tracer)
    tracer.setup(from, to, tint, 0.09, line_width)

func _update_visual_and_camera(delta: float) -> void:
    if visual:
        visual.aim_dir = aim_dir
        visual.shield_active = shield_active

    if camera:
        var target := Vector2(aim_dir.x * 165.0, -180.0 + aim_dir.y * 90.0)
        camera.position = camera.position.lerp(target, 1.0 - exp(-8.0 * delta))
