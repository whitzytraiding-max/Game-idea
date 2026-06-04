extends Node

# ── Real IDs (Don't Wake Dad) ─────────────────────────────────────────────────
const REAL_APP_ID:      String = "ca-app-pub-5758394034635286~4481672652"
const REAL_REWARDED_ID: String = "ca-app-pub-5758394034635286/9079393217"

# ── Google test IDs (used automatically in debug builds) ──────────────────────
const TEST_APP_ID:      String = "ca-app-pub-3940256099942544~1458002511"
const TEST_REWARDED_ID: String = "ca-app-pub-3940256099942544/1712485313"

signal extra_life_granted
signal ad_not_available   # emitted when no ad loaded yet — UI can show message

var _admob = null
var _rewarded_ready: bool = false
var _is_real: bool = false

func _ready() -> void:
	_is_real = not OS.is_debug_build()

	if not Engine.has_singleton("AdMob"):
		push_warning("AdMob: plugin not present — extra lives granted directly (dev mode)")
		return

	_admob = Engine.get_singleton("AdMob")

	_admob.initialization_complete.connect(_on_init_complete)
	_admob.rewarded_video_loaded.connect(_on_rewarded_loaded)
	_admob.rewarded_video_failed_to_load.connect(_on_rewarded_failed)
	_admob.rewarded.connect(_on_rewarded_earned)

	_admob.initialize({
		"app_id": REAL_APP_ID if _is_real else TEST_APP_ID,
		"is_real": _is_real
	})

func _on_init_complete(_data) -> void:
	_load_rewarded()

func _load_rewarded() -> void:
	if not _admob:
		return
	_rewarded_ready = false
	_admob.load_rewarded_video({
		"ad_unit_id": REAL_REWARDED_ID if _is_real else TEST_REWARDED_ID
	})

func _on_rewarded_loaded() -> void:
	_rewarded_ready = true

func _on_rewarded_failed(_error_code) -> void:
	_rewarded_ready = false

func _on_rewarded_earned(_currency: String, _amount: int) -> void:
	extra_life_granted.emit()
	_rewarded_ready = false
	_load_rewarded()  # preload next ad immediately

# ── Called by game.gd when player taps Extra Life ─────────────────────────────
func request_extra_life() -> void:
	if not _admob:
		# No plugin (dev/simulator) — grant directly so gameplay isn't blocked
		extra_life_granted.emit()
		return

	if _rewarded_ready:
		_admob.show_rewarded_video()
	else:
		# Ad not loaded yet — let the UI know
		ad_not_available.emit()
