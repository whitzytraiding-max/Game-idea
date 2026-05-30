extends Control

@onready var _play_button: Button  = $VBox/PlayButton
@onready var _mission_label: Label = $VBox/MissionLabel
@onready var _stars_label: Label   = $VBox/StarsLabel
@onready var _title_label: Label   = $TitleLabel
@onready var _door_light: ColorRect = $DoorLight

@onready var _ambience: AudioStreamPlayer = $AmbiencePlayer

var _flicker_tween: Tween = null

func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_refresh_ui()
	_start_ambient_flicker()
	_start_ambient_audio()

func _start_ambient_audio() -> void:
	if not _ambience:
		return
	var s: Resource = load("res://audio/ambient/house_hum.wav")
	if s:
		_ambience.stream = s
		_ambience.play()
		_ambience.finished.connect(func(): if _ambience: _ambience.play())

func _refresh_ui() -> void:
	var obj_pool: Array = GameManager.OBJECTIVES_L1 + GameManager.OBJECTIVES_L2
	var preview: String = obj_pool[randi() % obj_pool.size()]
	if _mission_label:
		_mission_label.text = "Tonight:\n\"" + preview + "\""
	if _stars_label:
		_stars_label.text = "⭐ Total Stars: " + str(GameManager.total_stars)
	if _title_label:
		var tween := create_tween().set_loops()
		tween.tween_property(_title_label, "modulate", Color(1.0, 0.85, 0.85, 1.0), 1.2)
		tween.tween_property(_title_label, "modulate", Color(0.7, 0.1, 0.1, 1.0), 1.2)

func _on_play_pressed() -> void:
	GameManager.go_to_game()

func _start_ambient_flicker() -> void:
	if not _door_light:
		return
	_flicker_tween = create_tween().set_loops()
	_flicker_tween.tween_property(_door_light, "modulate:a", 0.05, randf_range(2.0, 5.0))
	_flicker_tween.tween_property(_door_light, "modulate:a", 0.12, randf_range(1.0, 3.0))
