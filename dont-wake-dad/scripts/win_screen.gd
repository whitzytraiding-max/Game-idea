extends Control

@onready var _stars_label: Label    = $VBox/StarsLabel
@onready var _noise_label: Label    = $VBox/NoiseLabel
@onready var _next_button: Button   = $VBox/NextButton
@onready var _retry_button: Button  = $VBox/RetryButton
@onready var _menu_button: Button   = $VBox/MenuButton
@onready var _share_button: Button  = $VBox/ShareButton
@onready var _kid_visual: Label     = $KidVisual

func _ready() -> void:
	_next_button.pressed.connect(_on_next)
	_retry_button.pressed.connect(_on_retry)
	_menu_button.pressed.connect(_on_menu)
	_share_button.pressed.connect(_on_share)

	var stars := GameManager.last_stars
	var peak  := NoiseMeter.get_peak()

	if _stars_label:
		var star_str := ""
		for i in range(3):
			star_str += "⭐" if i < stars else "☆"
		_stars_label.text = star_str + "\n" + _stars_flavor(stars)

	if _noise_label:
		_noise_label.text = "Peak Noise: %.0f%%\nTotal Stars: %d" % [peak, GameManager.total_stars]

	if _kid_visual:
		var tween := create_tween()
		tween.tween_property(_kid_visual, "position:y", _kid_visual.position.y - 20, 0.3).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_property(_kid_visual, "position:y", _kid_visual.position.y, 0.3)

func _stars_flavor(stars: int) -> String:
	match stars:
		3: return "GHOST MODE 👻"
		2: return "PRETTY SNEAKY 🤫"
		_: return "YOU SURVIVED 😅"

func _on_next() -> void:
	GameManager.go_to_game()  # generator picks a new random room + mission each run

func _on_retry() -> void:
	GameManager.go_to_game()

func _on_menu() -> void:
	GameManager.go_to_main_menu()

func _on_share() -> void:
	var stars := GameManager.last_stars
	var star_str := ""
	for i in range(3):
		star_str += "⭐" if i < stars else "☆"
	var text := "Just snuck past Dad %s in 'Don't Wake Dad' 🤫\n#DontWakeDad" % star_str
	if OS.has_feature("android") or OS.has_feature("ios"):
		OS.shell_open("share://?text=" + text.uri_encode())
	else:
		DisplayServer.clipboard_set(text)
