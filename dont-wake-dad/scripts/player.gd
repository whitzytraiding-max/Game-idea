extends CharacterBody2D

signal stepped(noise_value: float)
signal player_caught

const WALK_SPEED    := 90.0
const CREEP_SPEED   := 40.0
const STEP_DISTANCE := 20.0
const CATCH_DISTANCE := 28.0

@onready var _visual: Polygon2D              = $Visual
@onready var _flashlight: PointLight2D       = $Flashlight
@onready var _step_audio: AudioStreamPlayer2D = $StepAudio
@onready var _caught_audio: AudioStreamPlayer2D = $CaughtAudio
@onready var _interaction_area: Area2D        = $InteractionArea

var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var is_creeping: bool = false
var is_hiding: bool = false
var is_caught: bool = false
var floor_noise_value: float = 20.0

var _dist_since_last_step: float = 0.0
var _touch_start_time: float = 0.0
var _touch_holding: bool = false
var _touch_start_pos: Vector2 = Vector2.ZERO
var _step_count: int = 0

# Cached audio streams — loaded once in _ready()
var _stream_carpet: AudioStream = null
var _stream_wood_a: AudioStream = null
var _stream_wood_b: AudioStream = null
var _stream_tile: AudioStream = null

func _ready() -> void:
	target_position = global_position
	add_to_group("player")
	_interaction_area.area_entered.connect(_on_floor_zone_entered)
	_interaction_area.area_exited.connect(_on_floor_zone_exited)
	_load_audio()

func _load_audio() -> void:
	_stream_carpet = load("res://audio/footsteps/step_carpet.wav")
	_stream_wood_a = load("res://audio/footsteps/step_wood_1.wav")
	_stream_wood_b = load("res://audio/footsteps/step_wood_2.wav")
	_stream_tile   = load("res://audio/footsteps/step_tile.wav")
	var caught_stream: Resource = load("res://audio/sfx/caught.wav")
	if caught_stream and _caught_audio:
		_caught_audio.stream = caught_stream

func _on_floor_zone_entered(area: Area2D) -> void:
	if area.has_meta("floor_noise"):
		floor_noise_value = float(area.get_meta("floor_noise"))

func _on_floor_zone_exited(_area: Area2D) -> void:
	floor_noise_value = 20.0

func _unhandled_input(event: InputEvent) -> void:
	if is_caught or is_hiding:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start_time = Time.get_ticks_msec() / 1000.0
			_touch_start_pos = event.position
			_touch_holding = true
		else:
			_touch_holding = false
			var held: float = Time.get_ticks_msec() / 1000.0 - _touch_start_time
			is_creeping = held > 0.35
			_set_target_from_screen(event.position)
	elif event is InputEventScreenDrag:
		if _touch_holding:
			is_creeping = true
			_set_target_from_screen(event.position)

func _set_target_from_screen(screen_pos: Vector2) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam:
		var offset := cam.get_screen_center_position() - Vector2(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height")
		) * 0.5
		target_position = screen_pos + offset
	else:
		target_position = screen_pos

func _physics_process(delta: float) -> void:
	if is_caught or is_hiding:
		velocity = Vector2.ZERO
		return

	var dist := global_position.distance_to(target_position)
	if dist < 4.0:
		velocity = Vector2.ZERO
		is_moving = false
		NoiseMeter.player_is_still = true
		return

	is_moving = true
	NoiseMeter.player_is_still = false
	var speed := CREEP_SPEED if is_creeping else WALK_SPEED
	var dir := (target_position - global_position).normalized()
	velocity = dir * speed
	var prev_pos := global_position
	move_and_slide()

	_dist_since_last_step += global_position.distance_to(prev_pos)
	if _dist_since_last_step >= STEP_DISTANCE:
		_dist_since_last_step = 0.0
		_emit_step()

	_visual.rotation = dir.angle() + PI * 0.5

func _emit_step() -> void:
	var noise: float = floor_noise_value * (0.4 if is_creeping else 1.0)
	NoiseMeter.add_noise(noise)
	stepped.emit(noise)
	if _step_audio:
		# Pick stream based on floor type, alternate for variety
		_step_count = (_step_count + 1) % 2
		if floor_noise_value <= 5.0 and _stream_carpet:
			_step_audio.stream = _stream_carpet
		elif floor_noise_value <= 15.0 and _stream_tile:
			_step_audio.stream = _stream_tile
		elif _step_count == 0 and _stream_wood_a:
			_step_audio.stream = _stream_wood_a
		elif _stream_wood_b:
			_step_audio.stream = _stream_wood_b
		if _step_audio.stream:
			_step_audio.pitch_scale = randf_range(0.88, 1.12)
			_step_audio.volume_db = -14.0 if is_creeping else -6.0
			_step_audio.play()

func set_floor_noise(value: float) -> void:
	floor_noise_value = value

func start_hiding() -> void:
	is_hiding = true
	is_moving = false
	target_position = global_position
	velocity = Vector2.ZERO
	NoiseMeter.player_is_still = true
	_visual.modulate = Color(0.3, 0.3, 0.3, 0.5)

func stop_hiding() -> void:
	is_hiding = false
	_visual.modulate = Color(1, 1, 1, 1)

func get_caught_by_dad() -> void:
	if is_caught:
		return
	is_caught = true
	is_moving = false
	velocity = Vector2.ZERO
	if _caught_audio and _caught_audio.stream:
		_caught_audio.play()
	player_caught.emit()

func respawn_at(pos: Vector2) -> void:
	global_position = pos
	target_position = pos
	is_caught = false
	is_hiding = false
	is_moving = false
	_visual.modulate = Color(1, 1, 1, 1)
