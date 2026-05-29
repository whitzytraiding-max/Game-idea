extends CanvasLayer

@onready var _noise_bar: ProgressBar = $NoiseBar
@onready var _dad_status: Label      = $DadStatus
@onready var _objective_label: Label = $ObjectiveLabel
@onready var _pulse_tween: Tween     = null

func _ready() -> void:
	NoiseMeter.noise_changed.connect(_on_noise_changed)
	GameManager.run_started.connect(_on_run_started)
	GameManager.phase_one_complete.connect(_on_phase_one_complete)
	_update_bar(0.0)
	_update_dad_status(0.0)

func _on_run_started(objective: String) -> void:
	if _objective_label:
		_objective_label.text = "🎯 " + objective

func _on_phase_one_complete(_obj: String) -> void:
	if _objective_label:
		_objective_label.text = "🛏️  GET BACK TO BED!"
		_objective_label.modulate = Color(1.0, 0.9, 0.2, 1.0)

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
		_dad_status.text = "😴  DAD: SLEEPING"
		_dad_status.modulate = Color(0.5, 1.0, 0.5, 1.0)
	elif value < 100.0:
		_dad_status.text = "😤  DAD: STIRRING"
		_dad_status.modulate = Color(1.0, 0.7, 0.1, 1.0)
	else:
		_dad_status.text = "😡  DAD: AWAKE!"
		_dad_status.modulate = Color(1.0, 0.1, 0.1, 1.0)
		if OS.has_feature("mobile"):
			Input.vibrate_handheld(200)
