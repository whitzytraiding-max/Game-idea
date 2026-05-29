extends Node2D

@onready var _level_container: Node2D     = $LevelContainer
@onready var _player: CharacterBody2D    = $Player
@onready var _dad: CharacterBody2D       = $Dad
@onready var _camera: Camera2D           = $Camera2D
@onready var _caught_overlay: CanvasLayer = $CaughtOverlay
@onready var _light_flicker: ColorRect   = $LightFlicker
@onready var _noise_vignette: ColorRect  = $NoiseVignette/VignetteRect
@onready var _jump_scare: CanvasLayer    = $JumpScare
@onready var _jump_scare_bg: ColorRect   = $JumpScare/BG
@onready var _jump_scare_face: Label     = $JumpScare/DadFaceLabel
@onready var _jump_scare_text: Label     = $JumpScare/JumpText
@onready var _ambience_player: AudioStreamPlayer = $AmbiencePlayer
@onready var _heartbeat_player: AudioStreamPlayer = $HeartbeatPlayer
@onready var _music_player: AudioStreamPlayer = $MusicPlayer

var _current_level: Node = null
var _hide_spots: Array = []
var _checkpoint_position: Vector2 = Vector2.ZERO
var _player_start_position: Vector2 = Vector2.ZERO

# Trauma-based screen shake: shake intensity = trauma²
var _shake_trauma: float = 0.0
var _vignette_alpha: float = 0.0

func _ready() -> void:
	add_to_group("game")
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
	# Load and start ambient audio
	_load_audio()
	if _ambience_player and _ambience_player.stream:
		_ambience_player.play()

func _load_audio() -> void:
	var amb: Resource = load("res://audio/ambient/tense_ambient.wav")
	if amb and _ambience_player:
		_ambience_player.stream = amb
		_ambience_player.finished.connect(func():
			if _ambience_player: _ambience_player.play()
		)
	var hb: Resource = load("res://audio/ambient/heartbeat.wav")
	if hb and _heartbeat_player:
		_heartbeat_player.stream = hb
		_heartbeat_player.finished.connect(func():
			if _heartbeat_player and _heartbeat_player.playing: _heartbeat_player.play()
		)
	var music: Resource = load("res://audio/ambient/chase_music.wav")
	if music and _music_player:
		_music_player.stream = music
		_music_player.finished.connect(func():
			if _music_player and _music_player.playing: _music_player.play()
		)

func _load_level() -> void:
	var level_scene: Resource = load(GameManager.get_current_level_scene())
	if level_scene:
		_current_level = level_scene.instantiate()
		_level_container.add_child(_current_level)
		_position_entities()
		_collect_hide_spots()
		_collect_objectives()
		# Snap camera directly to player on first frame — no lerp lag at start
		_camera.global_position = _player.global_position
		_clamp_camera()

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

func _process(delta: float) -> void:
	# Smooth camera follow with lerp
	_camera.global_position = _camera.global_position.lerp(
		_player.global_position, min(delta * 7.0, 1.0)
	)
	_clamp_camera()
	_update_checkpoint()
	_update_shake(delta)
	_update_noise_vignette(delta)

func _update_checkpoint() -> void:
	if _player.global_position.y < _checkpoint_position.y - 80:
		_checkpoint_position = _player.global_position

func _clamp_camera() -> void:
	if not _current_level:
		return
	var bg = _current_level.get_node_or_null("Background")
	var level_h: float = bg.size.y if bg else 1400.0
	var hw := 390.0 * 0.5
	var hh := 844.0 * 0.5
	_camera.global_position.x = clamp(_camera.global_position.x, hw, 390.0 - hw)
	_camera.global_position.y = clamp(_camera.global_position.y, hh, level_h - hh)

func _update_shake(delta: float) -> void:
	if _shake_trauma > 0.0:
		_shake_trauma = max(_shake_trauma - delta * 1.8, 0.0)
		var shake := _shake_trauma * _shake_trauma
		_camera.offset = Vector2(
			randf_range(-1.0, 1.0) * 14.0 * shake,
			randf_range(-1.0, 1.0) * 14.0 * shake
		)
	else:
		_camera.offset = Vector2.ZERO

func add_screen_shake(trauma: float) -> void:
	_shake_trauma = min(_shake_trauma + trauma, 1.0)

func _update_noise_vignette(delta: float) -> void:
	if not _noise_vignette:
		return
	var noise_pct := NoiseMeter.get_percentage() / 100.0
	var target_alpha := 0.0
	if noise_pct > 0.5:
		target_alpha = (noise_pct - 0.5) * 2.0 * 0.38
	if noise_pct > 0.85:
		target_alpha += sin(Time.get_ticks_msec() * 0.006) * 0.09
	_vignette_alpha = lerpf(_vignette_alpha, target_alpha, delta * 4.0)
	_noise_vignette.modulate = Color(1.0, 0.05, 0.05, clamp(_vignette_alpha, 0.0, 0.5))
	# Heartbeat rises with noise
	if _heartbeat_player and _heartbeat_player.stream:
		var noise_pct2: float = NoiseMeter.get_percentage() / 100.0
		if noise_pct2 > 0.4:
			if not _heartbeat_player.playing:
				_heartbeat_player.play()
			_heartbeat_player.volume_db = lerpf(-40.0, -8.0, (noise_pct2 - 0.4) / 0.6)
			_heartbeat_player.pitch_scale = lerpf(0.8, 1.5, (noise_pct2 - 0.4) / 0.6)
		else:
			_heartbeat_player.stop()

# ─── CAUGHT FLOW ─────────────────────────────────────────────────────────────

func _on_player_caught() -> void:
	add_screen_shake(0.9)
	get_tree().paused = true
	if _caught_overlay:
		_caught_overlay.visible = true
		_caught_overlay.get_node("ExtraLifeButton").visible = GameManager.revives_used_this_run < 2

func _on_give_up() -> void:
	get_tree().paused = false
	_caught_overlay.visible = false
	NoiseMeter.deactivate()
	EventManager.stop_events()
	GameManager.go_to_main_menu()

func _on_extra_life() -> void:
	_grant_extra_life()

func _grant_extra_life() -> void:
	get_tree().paused = false
	_caught_overlay.visible = false
	GameManager.use_revive()
	_play_phone_distraction()

func _play_phone_distraction() -> void:
	NoiseMeter.deactivate()
	_dad.set_state(_dad.State.RETURNING)
	var label := Label.new()
	label.text = "📱 ..."
	label.add_theme_font_size_override("font_size", 20)
	label.position = _dad.global_position + Vector2(-20, -50)
	_current_level.add_child(label)
	await get_tree().create_timer(2.0).timeout
	_player.respawn_at(_checkpoint_position)
	NoiseMeter.reset(40.0)
	NoiseMeter.activate()
	label.queue_free()

func _trigger_game_over() -> void:
	var level_h := 1400.0
	var pct: float = clampf(((level_h - _player.global_position.y) / level_h) * 100.0, 5.0, 99.0)
	GameManager.fail_run(pct)

# ─── DAD EVENTS ──────────────────────────────────────────────────────────────

func _on_dad_woke_up() -> void:
	_play_jump_scare()
	_flash_lights()
	add_screen_shake(0.75)
	for spot in _hide_spots:
		if spot.has_method("glow_for_dad"):
			spot.glow_for_dad()

func _play_jump_scare() -> void:
	# 1. Kill all audio — DEAD SILENCE is the scariest thing
	if _ambience_player: _ambience_player.volume_db = -80
	if _heartbeat_player: _heartbeat_player.stop()

	# 2. Silence pause — 0.3s. Player relaxes. THEN it hits.
	await get_tree().create_timer(0.3).timeout

	# 3. HORROR STING + DOOR SLAM at same moment — massive audio impact
	_play_oneshot("res://audio/sfx/door_slam.wav", 8.0)
	_play_oneshot("res://audio/sfx/horror_sting.wav", 6.0)

	# 4. WHITE FLASH — 0.05s of white fills screen before face appears
	if _jump_scare_bg:
		_jump_scare_bg.color = Color(1, 1, 1, 1)
	if _jump_scare:
		_jump_scare.visible = true
	if _jump_scare_face: _jump_scare_face.modulate = Color(1, 1, 1, 0)
	if _jump_scare_text: _jump_scare_text.modulate = Color(1, 1, 1, 0)

	await get_tree().create_timer(0.05).timeout

	# 5. Slam to dark red + face pops in instantly — no easing
	if _jump_scare_bg:
		_jump_scare_bg.color = Color(0.15, 0.0, 0.0, 1)
	if _jump_scare_face: _jump_scare_face.modulate = Color(1, 0.3, 0.3, 1)
	if _jump_scare_text: _jump_scare_text.modulate = Color(1, 0.1, 0.1, 1)
	add_screen_shake(1.0)

	# 6. Dad yells while face is up
	await get_tree().create_timer(0.15).timeout
	_play_oneshot("res://audio/dad/dad_got_you.wav", 2.0)

	# 7. Hold — player has time to panic
	await get_tree().create_timer(1.2).timeout

	# 8. Fade out all children
	if _jump_scare:
		var tween := create_tween().set_parallel(true)
		if _jump_scare_bg:   tween.tween_property(_jump_scare_bg,   "modulate:a", 0.0, 0.4)
		if _jump_scare_face: tween.tween_property(_jump_scare_face, "modulate:a", 0.0, 0.4)
		if _jump_scare_text: tween.tween_property(_jump_scare_text, "modulate:a", 0.0, 0.4)
		tween.chain().tween_callback(func():
			if _jump_scare: _jump_scare.visible = false
			# Reset for next time
			if _jump_scare_bg:
				_jump_scare_bg.color    = Color(0, 0, 0, 1)
				_jump_scare_bg.modulate = Color(1, 1, 1, 1)
			if _jump_scare_face: _jump_scare_face.modulate = Color(1, 1, 1, 1)
			if _jump_scare_text: _jump_scare_text.modulate = Color(1, 1, 1, 1)
		)

	# 9. Chase music slams in hard
	if _music_player and _music_player.stream:
		_music_player.volume_db = -14
		_music_player.play()

func _on_dad_returned() -> void:
	for spot in _hide_spots:
		if spot.has_method("stop_glow"):
			spot.stop_glow()
	# Fade chase music out
	if _music_player and _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -80.0, 2.0)
		tween.tween_callback(func(): _music_player.stop())
	# Restore ambience
	if _ambience_player and _ambience_player.stream:
		_ambience_player.volume_db = -18

func _flash_lights() -> void:
	if not _light_flicker:
		return
	var tween := create_tween()
	for i in range(6):
		tween.tween_property(_light_flicker, "modulate:a", 0.7, 0.05)
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
		"dog_bark":
			add_screen_shake(0.22)
			_play_oneshot("res://audio/sfx/dog_bump.wav", -4.0)
		"microwave_beep":
			add_screen_shake(0.15)
			_play_oneshot("res://audio/sfx/creak.wav", -8.0)

func _play_oneshot(path: String, vol: float) -> void:
	var s: Resource = load(path)
	if not s:
		return
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.volume_db = vol
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

func _spawn_random_lego() -> void:
	if not _current_level:
		return
	var lego_scene: Resource = load("res://entities/noise_object.tscn")
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
