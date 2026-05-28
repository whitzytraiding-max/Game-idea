extends Area2D

@export var noise_value: float = 40.0
@export var object_type: String = "generic"
@export var one_shot: bool = false

@onready var _visual: Polygon2D = $Visual
@onready var _audio: AudioStreamPlayer2D = $Audio
@onready var _label: Label = $Label

var _triggered: bool = false
var _original_color: Color

signal noise_triggered(value: float, source: String)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if _visual:
		_original_color = _visual.color

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if one_shot and _triggered:
		return
	_triggered = true
	NoiseMeter.add_noise(noise_value)
	noise_triggered.emit(noise_value, object_type)
	_play_feedback()
	# Shake camera proportional to noise — Lego hits hardest
	if noise_value >= 50.0:
		var games := get_tree().get_nodes_in_group("game")
		if games.size() > 0:
			games[0].add_screen_shake(noise_value / 100.0 * 0.65)

func _play_feedback() -> void:
	if _audio and _audio.stream:
		_audio.play()
	if _visual:
		var tween := create_tween()
		tween.tween_property(_visual, "color", Color(1, 0.3, 0.3, 1), 0.1)
		tween.tween_property(_visual, "color", _original_color, 0.4)
	if _label:
		_label.text = _get_noise_emoji()
		_label.visible = true
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(_label):
			_label.visible = false

func _get_noise_emoji() -> String:
	match object_type:
		"lego":    return "💀 LEGO!"
		"dog":     return "🐕 WOOF!"
		"fridge":  return "🧊 CREAK!"
		"floor":   return "😬 CREAK!"
		"fart":    return "💨 ..."
		"phone":   return "📱 BUZZ!"
		_:         return "💥 BANG!"
