extends Control

@onready var _play_button: Button        = $VBox/PlayButton
@onready var _mission_label: Label       = $MissionLabel
@onready var _stars_label: Label         = $VBox/StarsLabel
@onready var _title_label: Label         = $TitleLabel
@onready var _door_light: ColorRect      = $DoorLight
@onready var _remove_ads_btn: Button     = $VBox/RemoveAdsButton
@onready var _restore_btn: Button        = $VBox/RestoreButton
@onready var _ambience: AudioStreamPlayer = $AmbiencePlayer

var _flicker_tween: Tween = null

func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_remove_ads_btn.pressed.connect(_on_remove_ads_pressed)
	_restore_btn.pressed.connect(_on_restore_pressed)
	PurchaseManager.purchase_completed.connect(_on_purchase_done)
	PurchaseManager.purchase_failed.connect(_on_purchase_error)
	PurchaseManager.restore_completed.connect(_on_restore_done)
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
	var preview: String = GameManager.OBJECTIVES[randi() % GameManager.OBJECTIVES.size()]["text"]
	if _mission_label:
		_mission_label.text = "Tonight:\n\"" + preview + "\""
	if _stars_label:
		_stars_label.text = "⭐ Total Stars: " + str(SaveManager.total_stars)
	if _title_label:
		var tween := create_tween().set_loops()
		tween.tween_property(_title_label, "modulate", Color(1.0, 0.85, 0.85, 1.0), 1.2)
		tween.tween_property(_title_label, "modulate", Color(0.7, 0.1, 0.1, 1.0), 1.2)
	_update_ads_button()

func _update_ads_button() -> void:
	if not _remove_ads_btn:
		return
	if SaveManager.ads_removed:
		_remove_ads_btn.text = "Ads Removed  ✓"
		_remove_ads_btn.disabled = true
		_remove_ads_btn.modulate = Color(0.4, 0.8, 0.4, 0.7)
		if _restore_btn: _restore_btn.visible = false
	else:
		_remove_ads_btn.text = "Remove Ads  💜"
		_remove_ads_btn.disabled = false
		_remove_ads_btn.modulate = Color(1, 1, 1, 1)

func _on_play_pressed() -> void:
	GameManager.go_to_game()

func _on_remove_ads_pressed() -> void:
	_remove_ads_btn.text = "Loading..."
	_remove_ads_btn.disabled = true
	PurchaseManager.buy_remove_ads()

func _on_restore_pressed() -> void:
	_restore_btn.text = "Restoring..."
	_restore_btn.disabled = true
	PurchaseManager.restore_purchases()

func _on_purchase_done(product_id: String) -> void:
	if product_id == PurchaseManager.PRODUCT_REMOVE_ADS:
		_update_ads_button()

func _on_purchase_error(_product_id: String, _error: String) -> void:
	_remove_ads_btn.text = "Remove Ads  💜"
	_remove_ads_btn.disabled = false

func _on_restore_done() -> void:
	_restore_btn.text = "Restore Purchases"
	_restore_btn.disabled = false
	_update_ads_button()

func _start_ambient_flicker() -> void:
	if not _door_light:
		return
	_flicker_tween = create_tween().set_loops()
	_flicker_tween.tween_property(_door_light, "modulate:a", 0.05, randf_range(2.0, 5.0))
	_flicker_tween.tween_property(_door_light, "modulate:a", 0.12, randf_range(1.0, 3.0))
