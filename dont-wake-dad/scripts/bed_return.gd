extends Area2D

# Phase 2 target — activated after player collects the objective.
# Player taps this to complete the run.

@onready var _visual: Polygon2D = $Visual
@onready var _prompt: Label     = $PromptLabel

signal bed_reached

var active: bool  = false
var _player_inside: bool = false

func _ready() -> void:
	add_to_group("bed_return")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameManager.phase_one_complete.connect(_on_phase_one_complete)
	if _prompt:
		_prompt.visible = false
	# Hidden until player needs to return
	if _visual:
		_visual.color = Color(0.18, 0.26, 0.50, 0.0)

func _on_phase_one_complete(_obj: String) -> void:
	activate()

func activate() -> void:
	active = true
	if _visual:
		# Flash white briefly then settle into gold pulse
		var tween := create_tween()
		tween.tween_property(_visual, "color", Color(1.0, 1.0, 1.0, 1.0), 0.08)
		tween.tween_property(_visual, "color", Color(1.0, 0.88, 0.1, 0.95), 0.12)
		tween.tween_callback(func():
			var loop := create_tween().set_loops()
			loop.tween_property(_visual, "color", Color(1.0, 0.95, 0.15, 0.95), 0.4)
			loop.tween_property(_visual, "color", Color(0.85, 0.55, 0.05, 0.55), 0.4)
		)
	if _prompt and _player_inside:
		_prompt.visible = true
		_prompt.text = "TAP TO SLEEP 🛏️"

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = true
	if active and _prompt:
		_prompt.visible = true
		_prompt.text = "TAP TO SLEEP 🛏️"

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = false
	if _prompt:
		_prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not active or not _player_inside:
		return
	if event is InputEventScreenTouch and event.pressed:
		bed_reached.emit()
		GameManager.complete_run()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if active and _player_inside and _prompt and not _prompt.visible:
		_prompt.visible = true
		_prompt.text = "TAP TO SLEEP 🛏️"
