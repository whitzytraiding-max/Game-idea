extends Area2D

@export var objective_description: String = "Get the snack"

@onready var _visual: Polygon2D = $Visual
@onready var _glow: PointLight2D = $Glow
@onready var _audio: AudioStreamPlayer2D = $Audio
@onready var _label: Label = $Label

var _player_inside: bool = false
var _completed: bool = false

signal objective_completed

func _ready() -> void:
	add_to_group("objective")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if _label:
		_label.visible = false
	var s: Resource = load("res://audio/sfx/success.wav")
	if s and _audio:
		_audio.stream = s

func set_mission(mission_text: String) -> void:
	objective_description = mission_text

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player") or _completed:
		return
	_player_inside = true
	if _label:
		_label.text = "TAP TO GRAB"
		_label.visible = true

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = false
	if _label:
		_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside or _completed:
		return
	if event is InputEventScreenTouch and event.pressed:
		_complete()

func _complete() -> void:
	_completed = true
	if _audio and _audio.stream:
		_audio.play()
	if _visual:
		var tween := create_tween()
		tween.tween_property(_visual, "color", Color(1, 1, 0.2, 1), 0.1)
		tween.tween_property(_visual, "scale", Vector2(2.0, 2.0), 0.3)
		tween.tween_property(_visual, "modulate", Color(1, 1, 1, 0), 0.3)
	if _glow:
		_glow.enabled = false
	if _label:
		_label.visible = false
	objective_completed.emit()
	# Phase 1 complete — player now needs to return to bed
	GameManager.complete_phase_one()

func pulse() -> void:
	if not _visual:
		return
	var tween := create_tween().set_loops()
	tween.tween_property(_visual, "color", Color(1.0, 0.9, 0.2, 1.0), 0.6)
	tween.tween_property(_visual, "color", Color(0.8, 0.6, 0.0, 1.0), 0.6)
