extends CanvasLayer

@onready var _noise_bar: ProgressBar = $NoiseBar
@onready var _dad_status: Label      = $DadStatus
@onready var _objective_label: Label = $ObjectiveLabel
@onready var _run_label: Label       = $RunLabel
@onready var _dad_pill: ColorRect    = $DadPill
@onready var _pulse_tween: Tween     = null

func _ready() -> void:
	NoiseMeter.noise_changed.connect(_on_noise_changed)
	GameManager.run_started.connect(_on_run_started)
	GameManager.phase_one_complete.connect(_on_phase_one_complete)
	_update_bar(0.0)
	_update_dad_status(0.0)

func _on_run_started(objective: String) -> void:
	if _objective_label:
		_objective_label.text = "🎯  " + objective
		_objective_label.modulate = Color(0.85, 0.85, 1.0, 0.95)
	if _run_label:
		_run_label.text = "⭐ %d  |  RUN %d" % [GameManager.total_stars, GameManager.current_run]

func _on_phase_one_complete(_obj: String) -> void:
	if _objective_label:
		_objective_label.text = "🛏️   GET BACK TO BED!"
		_objective_label.modulate = Color(1.0, 0.92, 0.15, 1.0)
		var tween := create_tween().set_loops(4)
		tween.tween_property(_objective_label, "modulate:a", 0.4, 0.25)
		tween.tween_property(_objective_label, "modulate:a", 1.0, 0.25)

func _on_noise_changed(value: float) -> void:
	_update_bar(value)
	_update_dad_status(value)

func _update_bar(value: float) -> void:
	if not _noise_bar:
		return
	_noise_bar.value = value
	var pct := value / 100.0
	if pct < 0.5:
		_noise_bar.modulate = Color(0.3 + pct * 1.4, 0.9, 0.2, 1.0)
	elif pct < 0.8:
		_noise_bar.modulate = Color(1.0, 0.9 - (pct - 0.5) * 2.0, 0.1, 1.0)
	else:
		_noise_bar.modulate = Color(1.0, 0.1, 0.1, 1.0)
		_trigger_pulse()

func _trigger_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_running():
		return
	var loops := 5 if NoiseMeter.get_percentage() > 90.0 else 3
	_pulse_tween = create_tween().set_loops(loops)
	_pulse_tween.tween_property(_noise_bar, "scale", Vector2(1.05, 1.25), 0.10)
	_pulse_tween.tween_property(_noise_bar, "scale", Vector2(1.0, 1.0), 0.10)
	if OS.has_feature("mobile"):
		var intensity := 150 if NoiseMeter.get_percentage() > 90.0 else 80
		Input.vibrate_handheld(intensity)

func _update_dad_status(value: float) -> void:
	if not _dad_status:
		return
	if value < 80.0:
		_dad_status.text = "💤  DAD: SLEEPING"
		_dad_status.modulate = Color(0.45, 1.0, 0.45, 1.0)
		if _dad_pill: _dad_pill.color = Color(0.08, 0.14, 0.08, 0.85)
	elif value < 100.0:
		_dad_status.text = "😤  DAD: STIRRING..."
		_dad_status.modulate = Color(1.0, 0.75, 0.1, 1.0)
		if _dad_pill: _dad_pill.color = Color(0.18, 0.12, 0.04, 0.90)
	else:
		_dad_status.text = "😡  DAD: COMING!"
		_dad_status.modulate = Color(1.0, 0.15, 0.1, 1.0)
		if _dad_pill: _dad_pill.color = Color(0.22, 0.04, 0.04, 0.92)
		if OS.has_feature("mobile"):
			Input.vibrate_handheld(200)
