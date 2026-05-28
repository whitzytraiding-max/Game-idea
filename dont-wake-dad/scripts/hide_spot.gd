extends Area2D

@export var spot_name: String = "hide spot"

@onready var _visual: Polygon2D = $Visual
@onready var _prompt_label: Label = $PromptLabel

var _player_inside: bool = false
var _current_player: Node = null

signal player_entered_hide_spot
signal player_exited_hide_spot

func _ready() -> void:
	add_to_group("hide_spot")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if _prompt_label:
		_prompt_label.visible = false
	GameManager.run_started.connect(_on_run_started)

func _on_run_started(_obj: String) -> void:
	if _prompt_label:
		_prompt_label.visible = false

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = true
	_current_player = body

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = false
	if body.is_hiding:
		body.stop_hiding()
	_current_player = null
	player_exited_hide_spot.emit()
	if _visual:
		_visual.color = Color(0.2, 0.5, 0.2, 0.5)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside or _current_player == null:
		return
	if event is InputEventScreenTouch and event.pressed:
		_toggle_hide()

func _toggle_hide() -> void:
	if _current_player.is_hiding:
		_current_player.stop_hiding()
		player_exited_hide_spot.emit()
		if _visual:
			_visual.color = Color(0.2, 0.5, 0.2, 0.5)
	else:
		_current_player.start_hiding()
		player_entered_hide_spot.emit()
		if _visual:
			_visual.color = Color(0.1, 0.8, 0.1, 0.7)

func _process(_delta: float) -> void:
	if _player_inside and _prompt_label:
		_prompt_label.visible = true
		_prompt_label.text = "TAP TO HIDE" if not (_current_player and _current_player.is_hiding) else "TAP TO LEAVE"
	elif _prompt_label:
		_prompt_label.visible = false

func glow_for_dad() -> void:
	if _visual:
		var tween := create_tween().set_loops()
		tween.tween_property(_visual, "color", Color(0.8, 0.8, 0.1, 0.8), 0.4)
		tween.tween_property(_visual, "color", Color(0.2, 0.5, 0.2, 0.5), 0.4)

func stop_glow() -> void:
	if _visual:
		var tween := create_tween()
		tween.tween_property(_visual, "color", Color(0.2, 0.5, 0.2, 0.5), 0.2)
