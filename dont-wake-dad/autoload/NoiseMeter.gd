extends Node

signal noise_changed(value: float)
signal dad_should_stir
signal dad_should_wake

var current_noise: float = 0.0
var max_noise: float = 100.0
var decay_rate: float = 10.0
var is_active: bool = false
var player_is_still: bool = false

var _peak_noise_this_run: float = 0.0

func _process(delta: float) -> void:
	if not is_active:
		return
	if player_is_still and current_noise > 0.0:
		current_noise = max(current_noise - decay_rate * delta, 0.0)
		noise_changed.emit(current_noise)

func add_noise(value: float) -> void:
	if not is_active:
		return
	current_noise = min(current_noise + value, max_noise)
	if current_noise > _peak_noise_this_run:
		_peak_noise_this_run = current_noise
	noise_changed.emit(current_noise)
	if current_noise >= 100.0:
		dad_should_wake.emit()
	elif current_noise >= 80.0:
		dad_should_stir.emit()

func reset(to_value: float = 0.0) -> void:
	current_noise = to_value
	noise_changed.emit(current_noise)

func activate() -> void:
	is_active = true
	_peak_noise_this_run = 0.0

func deactivate() -> void:
	is_active = false

func get_peak() -> float:
	return _peak_noise_this_run

func get_percentage() -> float:
	return (current_noise / max_noise) * 100.0
