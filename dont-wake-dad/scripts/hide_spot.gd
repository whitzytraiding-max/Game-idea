extends Area2D

@export var spot_name: String = "hide spot"

@onready var _visual: Polygon2D = $Visual
@onready var _prompt_label: Label = $PromptLabel

var _player_inside: bool = false
var _current_player: Node = null

# Outline-only polygons drawn around the visual for the "nearby" indicator
var _outline_nodes: Array = []

signal player_entered_hide_spot
signal player_exited_hide_spot

func _ready() -> void:
	add_to_group("hide_spot")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if _prompt_label:
		_prompt_label.visible = false
	# Invisible by default — the furniture the generator drew IS the visual
	if _visual:
		_visual.color = Color(0.2, 0.8, 0.3, 0.0)
	GameManager.run_started.connect(_on_run_started)

func _on_run_started(_obj: String) -> void:
	if _prompt_label:
		_prompt_label.visible = false

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = true
	_current_player = body
	_show_outline(true)

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = false
	if body.is_hiding:
		body.stop_hiding()
	_current_player = null
	player_exited_hide_spot.emit()
	_show_outline(false)
	if _visual:
		_visual.color = Color(0.2, 0.8, 0.3, 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside or _current_player == null:
		return
	if event is InputEventScreenTouch and event.pressed:
		_toggle_hide()

func _toggle_hide() -> void:
	if _current_player.is_hiding:
		_current_player.stop_hiding()
		player_exited_hide_spot.emit()
		# Back to outline-only
		if _visual:
			_visual.color = Color(0.2, 0.8, 0.3, 0.0)
		_show_outline(true)
	else:
		_current_player.start_hiding()
		player_entered_hide_spot.emit()
		# Fill appears when actually hiding inside the object
		if _visual:
			_visual.color = Color(0.15, 0.65, 0.15, 0.42)
		_show_outline(false)

func _process(_delta: float) -> void:
	if _player_inside and _prompt_label:
		_prompt_label.visible = true
		_prompt_label.text = "TAP TO HIDE" if not (_current_player and _current_player.is_hiding) else "TAP TO LEAVE"
	elif _prompt_label:
		_prompt_label.visible = false

# ── Outline effect ────────────────────────────────────────────────────────────

func _show_outline(visible: bool) -> void:
	for n in _outline_nodes:
		if is_instance_valid(n):
			n.visible = visible
	if visible and _outline_nodes.is_empty() and _visual:
		_build_outline()

func _build_outline() -> void:
	if not _visual or _visual.polygon.size() < 3:
		return
	# Draw 4 offset copies of the polygon in outline green to fake a border
	var offsets: Array = [Vector2(-2,0), Vector2(2,0), Vector2(0,-2), Vector2(0,2)]
	for off: Vector2 in offsets:
		var outline := Polygon2D.new()
		outline.polygon = _visual.polygon
		outline.color = Color(0.25, 0.90, 0.30, 0.55)
		outline.position = off
		add_child(outline)
		_outline_nodes.append(outline)

# ── Called by game.gd when dad wakes ─────────────────────────────────────────

func glow_for_dad() -> void:
	if _visual:
		_visual.color = Color(0.8, 0.8, 0.1, 0.55)
		var tween := create_tween().set_loops()
		tween.tween_property(_visual, "color", Color(0.8, 0.8, 0.1, 0.75), 0.35)
		tween.tween_property(_visual, "color", Color(0.8, 0.8, 0.1, 0.35), 0.35)

func stop_glow() -> void:
	if _visual:
		var tween := create_tween()
		tween.tween_property(_visual, "color", Color(0.2, 0.8, 0.3, 0.0), 0.3)
