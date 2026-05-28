extends Node2D

@onready var _level_container: Node2D = $LevelContainer
@onready var _player: CharacterBody2D = $Player
@onready var _dad: CharacterBody2D = $Dad
@onready var _camera: Camera2D = $Camera2D
@onready var _hud: CanvasLayer = $HUD
@onready var _revive_overlay: CanvasLayer = $ReviveOverlay
@onready var _light_flicker: ColorRect = $LightFlicker

var _current_level: Node = null
var _revive_timer: float = 0.0
var _is_revive_pending: bool = false
var _hide_spots: Array = []

func _ready() -> void:
	_load_level()
	GameManager.start_run()
	_player.player_caught.connect(_on_player_caught)
	_dad.dad_woke_up.connect(_on_dad_woke_up)
	_dad.dad_returned_to_bed.connect(_on_dad_returned)
	EventManager.event_fired.connect(_on_event_fired)
	_dad.player = _player
	if _revive_overlay:
		_revive_overlay.visible = false
		var revive_btn = _revive_overlay.get_node_or_null("ReviveButton")
		var no_btn     = _revive_overlay.get_node_or_null("NoReviveButton")
		if revive_btn:
			revive_btn.pressed.connect(_on_revive_button_pressed)
		if no_btn:
			no_btn.pressed.connect(_on_no_revive_button_pressed)

func _load_level() -> void:
	var level_scene := load(GameManager.get_current_level_scene())
	if level_scene:
		_current_level = level_scene.instantiate()
		_level_container.add_child(_current_level)
		_position_entities()
		_collect_hide_spots()
		_collect_objectives()

func _position_entities() -> void:
	var player_start: Node = _current_level.get_node_or_null("PlayerStart")
	var dad_start: Node    = _current_level.get_node_or_null("DadStart")
	if player_start:
		_player.global_position = player_start.global_position
		_player.target_position = player_start.global_position
	if dad_start:
		_dad.global_position = dad_start.global_position
		_dad.bed_position    = dad_start.global_position

func _collect_hide_spots() -> void:
	_hide_spots = []
	for node in _get_nodes_in_group_from(_current_level, "hide_spot"):
		_hide_spots.append(node)

func _collect_objectives() -> void:
	for node in _get_nodes_in_group_from(_current_level, "objective"):
		if node.has_method("pulse"):
			node.pulse()

func _get_nodes_in_group_from(root: Node, group: String) -> Array:
	var result := []
	for child in root.get_children():
		if child.is_in_group(group):
			result.append(child)
		result.append_array(_get_nodes_in_group_from(child, group))
	return result

func _process(delta: float) -> void:
	_camera.position = _player.global_position
	_clamp_camera()
	if _is_revive_pending:
		_revive_timer -= delta
		if _revive_overlay:
			var countdown_label: Label = _revive_overlay.get_node_or_null("CountdownLabel")
			if countdown_label:
				countdown_label.text = str(ceili(_revive_timer))
		if _revive_timer <= 0.0:
			_decline_revive()

func _clamp_camera() -> void:
	if not _current_level:
		return
	var level_size: Vector2 = _current_level.get_node_or_null("Background") and \
		_current_level.get_node("Background").size or Vector2(390, 1400)
	var hw := 390.0 * 0.5
	var hh := 844.0 * 0.5
	_camera.position.x = clamp(_camera.position.x, hw, level_size.x - hw)
	_camera.position.y = clamp(_camera.position.y, hh, level_size.y - hh)

func _on_player_caught() -> void:
	if GameManager.revives_used_this_run < 2:
		_show_revive_prompt()
	else:
		_trigger_game_over()

func _show_revive_prompt() -> void:
	_is_revive_pending = true
	_revive_timer = 4.0
	Engine.time_scale = 0.15
	if _revive_overlay:
		_revive_overlay.visible = true

func _on_revive_accepted() -> void:
	Engine.time_scale = 1.0
	_is_revive_pending = false
	if _revive_overlay:
		_revive_overlay.visible = false
	if GameManager.use_revive():
		var nearest := _find_nearest_hide_spot()
		if nearest:
			_player.respawn_at(nearest.global_position)
		else:
			_player.respawn_at(_player.global_position + Vector2(0, -60))
		_dad.set_state(_dad.State.RETURNING)

func _on_revive_declined() -> void:
	_decline_revive()

func _decline_revive() -> void:
	Engine.time_scale = 1.0
	_is_revive_pending = false
	if _revive_overlay:
		_revive_overlay.visible = false
	_trigger_game_over()

func _trigger_game_over() -> void:
	var total: float = 1400.0
	var player_y: float = _player.global_position.y
	var pct: float = clamp(((total - player_y) / total) * 100.0, 5.0, 99.0)
	GameManager.fail_run(pct)

func _on_dad_woke_up() -> void:
	_flash_lights()
	for spot in _hide_spots:
		if spot.has_method("glow_for_dad"):
			spot.glow_for_dad()

func _on_dad_returned() -> void:
	for spot in _hide_spots:
		if spot.has_method("stop_glow"):
			spot.stop_glow()

func _flash_lights() -> void:
	if not _light_flicker:
		return
	var tween := create_tween()
	for i in range(6):
		tween.tween_property(_light_flicker, "modulate:a", 0.6, 0.05)
		tween.tween_property(_light_flicker, "modulate:a", 0.0, 0.05)

func _on_event_fired(event_name: String, _data: Dictionary) -> void:
	match event_name:
		"flicker":
			_flash_lights()
		"dad_fake_stir":
			_dad.set_state(_dad.State.STIRRING)
			await get_tree().create_timer(1.5).timeout
			if _dad.state == _dad.State.STIRRING:
				_dad.set_state(_dad.State.SLEEPING)
				NoiseMeter.reset(max(NoiseMeter.current_noise - 20, 0))
		"lego_spawn":
			_spawn_random_lego()

func _spawn_random_lego() -> void:
	if not _current_level:
		return
	var lego_scene := load("res://entities/noise_object.tscn")
	if not lego_scene:
		return
	var lego: Area2D = lego_scene.instantiate()
	lego.noise_value = 75.0
	lego.object_type = "lego"
	var px := randf_range(80, 310)
	var player_y := _player.global_position.y
	lego.global_position = Vector2(px, player_y - randf_range(80, 200))
	_current_level.add_child(lego)

func _find_nearest_hide_spot() -> Node:
	var nearest: Node = null
	var best_dist := INF
	for spot in _hide_spots:
		var d := _player.global_position.distance_to(spot.global_position)
		if d < best_dist:
			best_dist = d
			nearest = spot
	return nearest

func _on_revive_button_pressed() -> void:
	_on_revive_accepted()

func _on_no_revive_button_pressed() -> void:
	_on_revive_declined()
