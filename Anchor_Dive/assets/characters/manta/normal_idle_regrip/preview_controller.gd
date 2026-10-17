extends Node2D
var paused:=false
@onready var small: AnimatedSprite2D=$GameSize
@onready var detail: AnimatedSprite2D=$Detail
@onready var phase: Label=$Phase
var frame_start_seconds: PackedFloat32Array = PackedFloat32Array()
var frame_duration_seconds: PackedFloat32Array = PackedFloat32Array()
func _ready() -> void:
	var frames: SpriteFrames = detail.sprite_frames
	var animation_name: StringName = detail.animation
	var rate: float = frames.get_animation_speed(animation_name)
	var elapsed: float = 0.0
	for index in range(frames.get_frame_count(animation_name)):
		var seconds: float = frames.get_frame_duration(animation_name, index) / rate
		frame_start_seconds.append(elapsed)
		frame_duration_seconds.append(seconds)
		elapsed += seconds
func _process(_delta: float) -> void:
	var t: float = frame_start_seconds[detail.frame] + frame_duration_seconds[detail.frame] * detail.frame_progress
	var action:="REST"
	if t>=0.36 and t<0.72: action="GLANCE / PREPARE"
	elif t>=0.72 and t<1.18: action="LIFT / REGRIP"
	elif t>=1.18 and t<1.68: action="HOLD / WEIGHT"
	elif t>=1.68 and t<2.62: action="LOWER / EXHALE"
	elif t>=2.62 and t<3.50: action="HAIR + GEAR / SETTLE"
	elif t>=3.60 and t<3.77: action="BLINK"
	phase.text="%s     %.2f s / 4.80 s"%[action,t]
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_SPACE:
			paused=not paused
			if paused:
				small.pause();detail.pause()
			else:
				small.play();detail.play()
		if event.keycode==KEY_R:
			small.stop();detail.stop()
			small.play();detail.play()
			paused=false
