extends Control

@onready var _pct_label: Label         = $VBox/PctLabel
@onready var _retry_button: Button     = $VBox/RetryButton
@onready var _menu_button: Button      = $VBox/MenuButton
@onready var _ad_button: Button        = $VBox/AdButton
@onready var _share_button: Button     = $VBox/ShareButton
@onready var _dad_face: Label          = $DadFace

func _ready() -> void:
	_retry_button.pressed.connect(_on_retry)
	_menu_button.pressed.connect(_on_menu)
	_ad_button.pressed.connect(_on_ad_revive)
	_share_button.pressed.connect(_on_share)

	var pct := GameManager.last_completion_pct
	if _pct_label:
		_pct_label.text = "You made it %.0f%% of the way...\nSo close 😭" % pct

	if _dad_face:
		var tween := create_tween()
		tween.tween_property(_dad_face, "scale", Vector2(1.2, 1.2), 0.3)
		tween.tween_property(_dad_face, "scale", Vector2(1.0, 1.0), 0.2)

	# Ad button only available if revives remain
	if _ad_button:
		_ad_button.visible = GameManager.revives_used_this_run < 2

func _on_retry() -> void:
	GameManager.go_to_game()

func _on_menu() -> void:
	GameManager.go_to_main_menu()

func _on_ad_revive() -> void:
	# TODO: show real rewarded ad here via AdMob plugin
	# On reward_earned callback, call:
	#   GameManager.go_to_game()
	# For now, grant instantly (remove this in production)
	GameManager.go_to_game()

func _on_share() -> void:
	var pct := GameManager.last_completion_pct
	var text := "I made it %.0f%% without waking Dad in 'Don't Wake Dad' 😂\n#DontWakeDad" % pct
	if OS.has_feature("android") or OS.has_feature("ios"):
		# Native share sheet
		_capture_screenshot()
		OS.shell_open("share://?text=" + text.uri_encode())
	else:
		DisplayServer.clipboard_set(text)

func _capture_screenshot() -> String:
	var img := get_viewport().get_texture().get_image()
	var path := OS.get_user_data_dir() + "/screenshot.png"
	img.save_png(path)
	return path
