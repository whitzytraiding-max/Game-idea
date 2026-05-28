extends Node2D

@onready var _level_container: Node2D = $LevelContainer
@onready var _player: CharacterBody2D = $Player
@onready var _dad: CharacterBody2D = $Dad
@onready var _camera: Camera2D = $Camera2D
@onready var _hud: CanvasLayer = $HUD
@onready var _caught_overlay: CanvasLayer = $CaughtOverlay
@onready var _light_flicker: ColorRect = $LightFlicker

var _current_level: Node = null
var _hide_spots: Array = []
var _checkpoint_position: Vector2 = Vector2.ZERO
var _player_start_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	_load_level()
	GameManager.start_run()
	_player.player_caught.connect(_on_player_caught)
	_dad.dad_woke_up.connect(_on_dad_woke_up)
	_dad.dad_returned_to_bed.connect(_on_dad_returned)
	EventManager.event_fired.connect(_on_event_fired)
	_dad.player = _player
	if _caught_overlay:
		_caught_overlay.visible = false
		_caught_overlay.get_node("GiveUpButton").pressed.connect(_on_give_up)
		_caught_overlay.get_node("ExtraLifeButton").pressed.connect(_on_extra_life)

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
		_player_start_position  = player_start.global_position
		_checkpoint_position    = player_start.global_position
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

func _process(_delta: float) -> void:
	_camera.position = _player.global_position
	_clamp_camera()
	_update_checkpoint()

func _update_checkpoint() -> void:
	# Save checkpoint as player moves deeper into the level (lower y = closer to goal)
	if _player.global_position.y < _checkpoint_position.y - 80:
		_checkpoint_position = _player.global_position

func _clamp_camera() -> void:
	if not _current_level:
		return
	var bg = _current_level.get_node_or_null("Background")
	var level_h: float = bg.size.y if bg else 1400.0
	var hw := 390.0 * 0.5
	var hh := 844.0 * 0.5
	_camera.position.x = clamp(_camera.position.x, hw, 390.0 - hw)
	_camera.position.y = clamp(_camera.position.y, hh, level_h - hh)

# ─── CAUGHT FLOW ─────────────────────────────────────────────────────────────

func _on_player_caught() -> void:
	get_tree().paused = true
	if _caught_overlay:
		_caught_overlay.visible = true
		# Hide extra life button if already used twice
		_caught_overlay.get_node("ExtraLifeButton").visible = GameManager.revives_used_this_run < 2

func _on_give_up() -> void:
	get_tree().paused = false
	_caught_overlay.visible = false
	_trigger_game_over()

func _on_extra_life() -> void:
	# TODO: show real AdMob rewarded ad here
	# Wire your AdMob reward callback to call _grant_extra_life()
	# For now grants immediately — remove this line in production:
	_grant_extra_life()

func _grant_extra_life() -> void:
	get_tree().paused = false
	_caught_overlay.visible = false
	GameManager.use_revive()
	_play_phone_distraction()

func _play_phone_distraction() -> void:
	# Dad's phone rings — he stops, looks confused, walks back
	NoiseMeter.deactivate()
	_dad.set_state(_dad.State.RETURNING)

	# Show funny distraction label on Dad
	var label := Label.new()
	label.text = "📱 ..."
	label.theme_override_font_sizes = {"font_size": 20}
	label.position = _dad.global_position + Vector2(-20, -50)
	_current_level.add_child(label)

	await get_tree().create_timer(2.0).timeout

	# Respawn player at last checkpoint, reset noise
	_player.respawn_at(_checkpoint_position)
	NoiseMeter.reset(40.0)
	NoiseMeter.activate()
	label.queue_free()

func _trigger_game_over() -> void:
	var level_h := 1400.0
	var pct := clamp(((level_h - _player.global_position.y) / level_h) * 100.0, 5.0, 99.0)
	GameManager.fail_run(pct)

# ─── DAD EVENTS ──────────────────────────────────────────────────────────────

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

# ─── RANDOM EVENTS ───────────────────────────────────────────────────────────

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
	lego.global_position = Vector2(
		randf_range(80, 310),
		_player.global_position.y - randf_range(80, 200)
	)
	_current_level.add_child(lego)
