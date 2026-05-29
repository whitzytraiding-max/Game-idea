extends CharacterBody2D

signal dad_woke_up
signal player_caught_by_dad
signal dad_returned_to_bed

enum State { SLEEPING, STIRRING, CHASING, SEARCHING, RETURNING }

@onready var _visual: Polygon2D              = $Visual
@onready var _eye_glow: PointLight2D         = $EyeGlow
@onready var _snore_audio: AudioStreamPlayer2D = $SnoreAudio
@onready var _footstep_audio: AudioStreamPlayer2D = $FootstepAudio
@onready var _yell_audio: AudioStreamPlayer2D  = $YellAudio
@onready var _catch_area: Area2D             = $CatchArea
@onready var _stir_label: Label              = $StirLabel

var state: State = State.SLEEPING
var player: Node2D = null
var bed_position: Vector2 = Vector2.ZERO
var last_known_player_pos: Vector2 = Vector2.ZERO

var _stir_timer: float = 0.0
var _search_timer: float = 0.0
var _chase_speed_timer: float = 0.0
var _current_speed: float = 0.0
var _step_dist: float = 0.0
var _dad_woke_triggered: bool = false

func _ready() -> void:
	bed_position = global_position
	_current_speed = 0.0
	NoiseMeter.dad_should_stir.connect(_on_should_stir)
	NoiseMeter.dad_should_wake.connect(_on_should_wake)
	NoiseMeter.dad_can_sleep.connect(_on_noise_calmed)
	_catch_area.body_entered.connect(_on_catch_area_body_entered)
	if _eye_glow:
		_eye_glow.enabled = false
	_load_audio()
	if _snore_audio and _snore_audio.stream:
		_snore_audio.play()

func _load_audio() -> void:
	var snore: Resource = load("res://audio/dad/dad_snore.wav")
	if snore and _snore_audio:
		_snore_audio.stream = snore
		# Loop snoring by reconnecting on finish
		_snore_audio.finished.connect(_on_snore_finished)
	var yell: Resource = load("res://audio/dad/dad_yell.wav")
	if yell and _yell_audio:
		_yell_audio.stream = yell
	var step: Resource = load("res://audio/dad/dad_footstep.wav")
	if step and _footstep_audio:
		_footstep_audio.stream = step

func _on_snore_finished() -> void:
	if (state == State.SLEEPING or state == State.STIRRING) and _snore_audio:
		_snore_audio.play()

func _physics_process(delta: float) -> void:
	match state:
		State.SLEEPING:
			velocity = Vector2.ZERO

		State.STIRRING:
			velocity = Vector2.ZERO
			_stir_timer -= delta
			if _stir_timer <= 0.0:
				_enter_chase()

		State.CHASING:
			if not player:
				_enter_returning()
				return
			if player.is_hiding:
				last_known_player_pos = player.global_position
				_enter_searching()
				return
			last_known_player_pos = player.global_position
			_move_toward(player.global_position, delta)
			_chase_speed_timer += delta
			if _chase_speed_timer >= 5.0:
				_chase_speed_timer = 0.0
				_current_speed = min(_current_speed + 10.0, 220.0)

		State.SEARCHING:
			var d := global_position.distance_to(last_known_player_pos)
			if d > 24.0:
				_move_toward(last_known_player_pos, delta, 0.7)
			else:
				velocity = Vector2.ZERO
				_search_timer -= delta
				if _search_timer <= 0.0:
					_enter_returning()

		State.RETURNING:
			var d := global_position.distance_to(bed_position)
			if d > 16.0:
				_move_toward(bed_position, delta, 0.5)
			else:
				global_position = bed_position
				velocity = Vector2.ZERO
				_enter_sleeping()

func _move_toward(target: Vector2, _delta: float, speed_mult: float = 1.0) -> void:
	var dir := (target - global_position).normalized()
	velocity = dir * _current_speed * speed_mult
	var prev := global_position
	move_and_slide()
	_step_dist += global_position.distance_to(prev)
	if _step_dist >= 28.0:
		_step_dist = 0.0
		if _footstep_audio and _footstep_audio.stream:
			_footstep_audio.pitch_scale = randf_range(0.85, 1.0)
			_footstep_audio.play()
	_visual.rotation = dir.angle() + PI * 0.5

func _on_should_stir() -> void:
	if state == State.SLEEPING:
		_stir_timer = DifficultyManager.config["stir_window"]
		set_state(State.STIRRING)

func _on_noise_calmed() -> void:
	if state == State.STIRRING:
		set_state(State.SLEEPING)
		if _snore_audio and _snore_audio.stream:
			_snore_audio.play()

func _on_should_wake() -> void:
	if state == State.SLEEPING or state == State.STIRRING:
		_enter_chase()

func _enter_chase() -> void:
	if state == State.CHASING:
		return
	set_state(State.CHASING)
	_dad_woke_triggered = true
	var base_speed: float = DifficultyManager.config["dad_base_speed"]
	var mult: float = DifficultyManager.config["dad_chase_multiplier"]
	_current_speed = base_speed * mult
	_chase_speed_timer = 0.0
	if _snore_audio:
		_snore_audio.stop()
	if _eye_glow:
		_eye_glow.enabled = true
	if _yell_audio and _yell_audio.stream:
		_yell_audio.play()
	dad_woke_up.emit()
	var tween := create_tween()
	tween.tween_property(_visual, "scale", Vector2(1.15, 1.15), 0.2)
	tween.tween_property(_visual, "scale", Vector2(1.0, 1.0), 0.3)

func _enter_searching() -> void:
	set_state(State.SEARCHING)
	_search_timer = DifficultyManager.config["search_duration"]

func _enter_returning() -> void:
	set_state(State.RETURNING)
	if _eye_glow:
		_eye_glow.enabled = false

func _enter_sleeping() -> void:
	set_state(State.SLEEPING)
	_dad_woke_triggered = false
	NoiseMeter.reset(40.0)
	if _snore_audio and _snore_audio.stream:
		_snore_audio.play()
	dad_returned_to_bed.emit()

func set_state(new_state: State) -> void:
	state = new_state
	_update_visuals()

func _update_visuals() -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT)
	match state:
		State.SLEEPING:
			tween.tween_property(_visual, "color", Color(0.35, 0.1, 0.08, 1.0), 0.4)
			if _stir_label:
				_stir_label.visible = true
				_stir_label.text = "z z z"
				_stir_label.modulate = Color(0.6, 0.8, 1.0, 0.75)
		State.STIRRING:
			tween.tween_property(_visual, "color", Color(0.7, 0.35, 0.05, 1.0), 0.2)
			if _stir_label:
				_stir_label.visible = true
				_stir_label.text = "...?"
				_stir_label.modulate = Color(1.0, 0.8, 0.3, 1.0)
		State.CHASING:
			tween.tween_property(_visual, "color", Color(1.0, 0.08, 0.05, 1.0), 0.1)
			if _stir_label:
				_stir_label.visible = true
				_stir_label.text = "!!!"
				_stir_label.modulate = Color(1.0, 0.2, 0.2, 1.0)
		State.SEARCHING:
			tween.tween_property(_visual, "color", Color(0.85, 0.25, 0.08, 1.0), 0.25)
			if _stir_label:
				_stir_label.visible = true
				_stir_label.text = "?"
				_stir_label.modulate = Color(1.0, 0.6, 0.2, 1.0)
		State.RETURNING:
			tween.tween_property(_visual, "color", Color(0.4, 0.12, 0.1, 1.0), 0.5)
			if _stir_label:
				_stir_label.visible = true
				_stir_label.text = "hmph..."
				_stir_label.modulate = Color(0.7, 0.7, 0.7, 0.6)

func _on_catch_area_body_entered(body: Node) -> void:
	if body.is_in_group("player") and state == State.CHASING:
		if not body.is_hiding and not body.is_caught:
			body.get_caught_by_dad()
			player_caught_by_dad.emit()

func is_awake() -> bool:
	return state == State.CHASING or state == State.STIRRING or state == State.SEARCHING
