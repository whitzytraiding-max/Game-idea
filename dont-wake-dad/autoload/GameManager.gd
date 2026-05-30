extends Node

signal run_started(objective: String)
signal phase_one_complete(objective: String)   # item collected — now return to bed
signal run_completed(stars: int, peak_noise: float)
signal run_failed(completion_pct: float)

const SCENE_MAIN_MENU := "res://scenes/main_menu.tscn"
const SCENE_GAME      := "res://scenes/game.tscn"
const SCENE_WIN       := "res://scenes/win_screen.tscn"
const SCENE_LOSE      := "res://scenes/lose_screen.tscn"

# Each objective maps to the room type where the item lives
const OBJECTIVES: Array = [
	{"text": "Get a glass of water",        "room": "kitchen"},
	{"text": "Get a snack from the fridge", "room": "kitchen"},
	{"text": "Grab some ice cream",         "room": "kitchen"},
	{"text": "Grab some leftovers",         "room": "kitchen"},
	{"text": "Check the fridge at midnight","room": "kitchen"},
	{"text": "Steal the TV remote",         "room": "living_room"},
	{"text": "Rescue your Nintendo Switch", "room": "living_room"},
	{"text": "Get your phone charger",      "room": "living_room"},
	{"text": "Grab your headphones",        "room": "living_room"},
	{"text": "Go to the bathroom",          "room": "bathroom"},
	{"text": "Grab some toilet paper",      "room": "bathroom"},
]

var current_run: int = 0
var total_stars: int = 0
var current_objective: String = ""
var current_required_room: String = ""
var revives_used_this_run: int = 0
var last_completion_pct: float = 0.0
var last_stars: int = 0
var phase: int = 0   # 0 = collect item, 1 = return to bed

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_run() -> void:
	phase = 0
	current_run += 1
	revives_used_this_run = 0
	var chosen: Dictionary = OBJECTIVES[randi() % OBJECTIVES.size()]
	current_objective = chosen["text"]
	current_required_room = chosen["room"]
	DifficultyManager.update_for_run(current_run)
	NoiseMeter.decay_rate = DifficultyManager.config.noise_decay_rate
	NoiseMeter.activate()
	NoiseMeter.reset(0.0)
	EventManager.start_events()
	run_started.emit(current_objective)

func complete_phase_one() -> void:
	phase = 1
	# Small noise reward for getting the item
	NoiseMeter.reset(minf(NoiseMeter.current_noise * 0.6, 25.0))
	phase_one_complete.emit(current_objective)

func complete_run() -> void:
	phase = 0
	NoiseMeter.deactivate()
	EventManager.stop_events()
	var peak := NoiseMeter.get_peak()
	var stars := _calculate_stars(peak)
	last_stars = stars
	last_completion_pct = 100.0
	total_stars += stars
	run_completed.emit(stars, peak)
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file(SCENE_WIN)

func fail_run(completion_pct: float) -> void:
	phase = 0
	NoiseMeter.deactivate()
	EventManager.stop_events()
	last_completion_pct = completion_pct
	run_failed.emit(completion_pct)
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file(SCENE_LOSE)

func use_revive() -> bool:
	if revives_used_this_run >= 2:
		return false
	revives_used_this_run += 1
	NoiseMeter.reset(70.0)
	NoiseMeter.activate()
	EventManager.start_events()
	return true

func go_to_main_menu() -> void:
	phase = 0
	NoiseMeter.deactivate()
	EventManager.stop_events()
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)

func go_to_game() -> void:
	get_tree().change_scene_to_file(SCENE_GAME)

func _calculate_stars(peak_noise: float) -> int:
	if peak_noise < 30.0:
		return 3
	elif peak_noise < 65.0:
		return 2
	else:
		return 1
