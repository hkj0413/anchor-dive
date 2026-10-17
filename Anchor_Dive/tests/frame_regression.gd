extends SceneTree

# Run the same physics-tick inputs at different render caps. The fixed gameplay
# aim isolates simulation invariance from intentional camera/aim responsiveness.
class FixedAimSG extends "res://scripts/sg.gd":
	func _update_aim() -> void:
		aim_dir = Vector2.RIGHT

class TestStage extends "res://scripts/main.gd":
	func _spawn_player() -> void:
		player = FixedAimSG.new()
		player.name = "SG"
		player.global_position = Vector2(260, 900)
		add_child(player)

class FrameObserver extends Node:
	var runner: SceneTree
	func _process(_delta: float) -> void:
		runner.observe_frame()

var player
var tick := 0
var frames := 0
var snapshots: Array = []
var events: Array = []
var failures: Array[String] = []
var between_tick_motion := 0
var between_tick_camera := 0
var between_tick_aim := 0
var last_tick := -1
var last_visual := Vector2.ZERO
var last_camera := Vector2.ZERO
var last_aim := Vector2.RIGHT
var testing_presentation := false
var output_path: String

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("Usage: --script res://tests/frame_regression.gd -- <60|120> <output.json>")
		quit(1)
		return
	Engine.max_fps = int(args[0])
	output_path = args[1]
	seed(12345)
	call_deferred("start")

func start() -> void:
	# The headless display starts square unless a window size is supplied.
	root.size = Vector2i(1600, 900)
	var stage := TestStage.new()
	root.add_child(stage)
	current_scene = stage
	player = stage.player
	testing_presentation = player.has_method("_reset_presentation")
	player.prototype_event.connect(func(message: String): events.append([tick, message]))
	var observer := FrameObserver.new()
	observer.runner = self
	observer.process_priority = 100
	root.add_child(observer)
	physics_frame.connect(before_physics)

func before_physics() -> void:
	if tick > 0 and tick <= 360:
		snapshots.append([
			tick, player.position.x, player.position.y,
			player.velocity.x, player.velocity.y, player.ammo,
			player.attack_timer, player.recoil_timer, player.reload_timer,
			player.reloading, player.shield_active, player.shield_energy,
			player.is_on_floor()
		])
		if player.position.x < 113.0:
			failures.append("Player crossed left wall")
	tick += 1
	match tick:
		1: Input.action_press("move_right")
		30: Input.action_press("jump")
		31: Input.action_release("jump")
		60: Input.action_release("move_right")
		70: Input.action_press("attack")
		80: Input.action_press("shield")
		120: Input.action_release("shield")
		130: Input.action_press("recoil")
		131: Input.action_release("recoil")
		160: Input.action_release("attack")
		170: Input.action_press("reload")
		171: Input.action_release("reload")
		361:
			player.global_position = Vector2(1000, 1400)
			player.velocity = Vector2.ZERO
		362:
			if not player.global_position.is_equal_approx(player.spawn_position):
				failures.append("Fall reset did not restore spawn")
			if testing_presentation:
				if not player.visual.global_position.is_equal_approx(player.spawn_position):
					failures.append("Fall reset left visual at old position")
				if not player._previous_physics_position.is_equal_approx(player.spawn_position):
					failures.append("Fall reset did not reset interpolation history")
			finish()

func observe_frame() -> void:
	frames += 1
	if testing_presentation and tick > 2 and tick < 361:
		var raw: Vector2 = player.visual.get_global_mouse_position() - (
			player.visual.global_position + Vector2(0, -116))
		if raw.length_squared() > 0.001:
			if not player.visual.aim_dir.is_equal_approx(raw.normalized()):
				failures.append("Visual aim used stale camera coordinates")
		if player.aim_dir != Vector2.RIGHT:
			failures.append("Presentation overwrote physics aim")
		if tick == last_tick:
			if player.visual.global_position.distance_to(last_visual) > 0.001:
				between_tick_motion += 1
			if player.camera.get_screen_center_position().distance_to(last_camera) > 0.001:
				between_tick_camera += 1
			if player.visual.aim_dir.distance_to(last_aim) > 0.00001:
				between_tick_aim += 1
	last_tick = tick
	last_visual = player.visual.global_position
	last_camera = player.camera.get_screen_center_position()
	last_aim = player.visual.aim_dir

func finish() -> void:
	if snapshots.size() != 360 or player.ammo != player.max_ammo:
		failures.append("Incomplete physics sequence or reload")
	if testing_presentation and Engine.max_fps == 120:
		if between_tick_motion == 0 or between_tick_camera == 0 or between_tick_aim == 0:
			failures.append("Presentation did not advance between physics ticks")
	var result := {
		"render_cap": Engine.max_fps, "physics_hz": Engine.physics_ticks_per_second,
		"frames": frames, "physics_samples": snapshots.size(),
		"between_tick_motion": between_tick_motion,
		"between_tick_camera": between_tick_camera,
		"between_tick_aim": between_tick_aim,
		"events": events, "snapshots": snapshots, "failures": failures,
	}
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	print("Regression cap=", Engine.max_fps, " samples=", snapshots.size(),
		" frames=", frames, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
